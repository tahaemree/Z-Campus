import 'dart:async';
import 'dart:math' as math;

import 'package:campus_online/commons/postgrest_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:campus_online/providers/cache_manager.dart';

String _normalizeSearchQuery(String query) {
  return query.trim().replaceAll(RegExp(r'\s+'), ' ');
}

Future<void> _debounceSearch(Ref ref) async {
  final completer = Completer<void>();
  final timer = Timer(const Duration(milliseconds: 300), () {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  ref.onDispose(() {
    timer.cancel();
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  await completer.future;
}

/// Direct Supabase client provider — single source for DI.
final supabaseProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Auth state stream — triggers provider refreshes on login/logout.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// All venues with favorite status.
final venuesProvider = FutureProvider<List<VenueModel>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  ref.watch(authStateProvider);

  final userId = supabase.auth.currentUser?.id;

  try {
    debugPrint('Fetching venues from Supabase database...');

    List<dynamic> response;

    if (userId != null) {
      response = await supabase.from('venues').select('''
            *,
            user_favorites!left(user_id)
          ''');
    } else {
      response = await supabase.from('venues').select('*');
    }

    if (response.isEmpty) {
      debugPrint('No venues found, returning empty list');
      return [];
    }

    final venues = response
        .map((json) => VenueModel.fromSupabaseJson(json, userId: userId))
        .toList();

    debugPrint('Successfully fetched ${venues.length} venues');
    return venues;
  } catch (e) {
    debugPrint('Error fetching venues: $e');
    rethrow;
  }
});

/// Venues filtered by category.
final venuesByCategoryProvider =
    FutureProvider.family<List<VenueModel>, String>((ref, category) async {
  final supabase = ref.watch(supabaseProvider);
  final userId = supabase.auth.currentUser?.id;

  try {
    List<dynamic> response;

    if (userId != null) {
      response = await supabase.from('venues').select('''
            *,
            user_favorites!left(user_id)
          ''').eq('category', category).order('name', ascending: true);
    } else {
      response = await supabase
          .from('venues')
          .select('*')
          .eq('category', category)
          .order('name');
    }

    return response
        .map((json) => VenueModel.fromSupabaseJson(json, userId: userId))
        .toList();
  } catch (e) {
    debugPrint('Error getting venues by category: $e');
    rethrow;
  }
});

/// Search venues with query.
final searchVenuesProvider = FutureProvider.autoDispose
    .family<List<VenueModel>, String>((ref, query) async {
  final normalizedQuery = _normalizeSearchQuery(query);
  if (normalizedQuery.length < 2) return [];

  await _debounceSearch(ref);

  try {
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    final safeQuery = escapePostgrestLikeValue(normalizedQuery);
    final searchFilter =
        'name.ilike.%$safeQuery%,description.ilike.%$safeQuery%,location.ilike.%$safeQuery%';

    List<dynamic> response;

    if (userId != null) {
      response = await supabase.from('venues').select('''
            *,
            user_favorites!left(user_id)
          ''').or(searchFilter).order('name').limit(50);
    } else {
      response = await supabase
          .from('venues')
          .select('*')
          .or(searchFilter)
          .order('name')
          .limit(50);
    }

    return response
        .map((json) => VenueModel.fromSupabaseJson(json, userId: userId))
        .toList();
  } catch (e) {
    debugPrint('Search error: $e');
    rethrow;
  }
});

/// Single venue by ID with cache.
final venueByIdProvider =
    FutureProvider.family<VenueModel, String>((ref, venueId) async {
  final cacheManager = ref.watch(venuesCacheProvider.notifier);
  final supabase = ref.watch(supabaseProvider);
  ref.watch(authStateProvider);

  final userId = supabase.auth.currentUser?.id;
  final cacheKey = scopedVenueCacheKey(venueId: venueId, userId: userId);

  if (cacheManager.hasValidCache(cacheKey)) {
    final cachedVenues = cacheManager.get(cacheKey);
    if (cachedVenues != null && cachedVenues.isNotEmpty) {
      return cachedVenues.first;
    }
  }

  try {
    Map<String, dynamic> response;

    if (userId != null) {
      response = await supabase.from('venues').select('''
            *,
            user_favorites!left(user_id)
          ''').eq('id', venueId).single();
    } else {
      response =
          await supabase.from('venues').select('*').eq('id', venueId).single();
    }

    final venue = VenueModel.fromSupabaseJson(response, userId: userId);
    cacheManager.put(cacheKey, [venue]);

    return venue;
  } catch (e) {
    debugPrint('Error fetching venue by ID: $e');
    throw Exception('Mekan bulunamadı. Lütfen tekrar deneyin.');
  }
});

class VenueFavoriteCountNotifier extends StateNotifier<AsyncValue<int>> {
  VenueFavoriteCountNotifier(this._ref, this._venueId)
      : super(const AsyncValue.loading()) {
    refresh();
  }

  final Ref _ref;
  final String _venueId;
  int? _serverCount;
  int _optimisticDelta = 0;
  int _localRevision = 0;

  Future<void> refresh() async {
    final requestRevision = _localRevision;
    final count = await _fetchCount();
    if (!mounted || requestRevision != _localRevision) return;

    _serverCount = count;
    _emitCount();
  }

  void applyOptimisticDelta(int delta) {
    _optimisticDelta += delta;
    final current = state.valueOrNull ?? _serverCount ?? 0;
    state = AsyncValue.data(math.max(0, current + delta));
  }

  Future<void> commitOptimisticDelta(int delta) async {
    final current = state.valueOrNull ?? _serverCount ?? 0;
    _optimisticDelta -= delta;
    _serverCount = math.max(0, current - _optimisticDelta);
    _localRevision++;
    _emitCount();
  }

  void rollbackOptimisticDelta(int delta) {
    _optimisticDelta -= delta;
    final current = state.valueOrNull ?? _serverCount ?? 0;
    state = AsyncValue.data(math.max(0, current - delta));
  }

  void _emitCount() {
    final count = (_serverCount ?? 0) + _optimisticDelta;
    state = AsyncValue.data(math.max(0, count));
  }

  Future<int> _fetchCount() async {
    final supabase = _ref.read(supabaseProvider);

    try {
      final response = await supabase.rpc(
        'get_venue_favorite_count',
        params: {'p_venue_id': _venueId},
      );

      if (response is int) return response;
      if (response is num) return response.toInt();

      return int.tryParse(response?.toString() ?? '') ?? 0;
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202') return 0;
      debugPrint('Error getting venue favorite count: $error');
      return _serverCount ?? state.valueOrNull ?? 0;
    } catch (error) {
      debugPrint('Error getting venue favorite count: $error');
      return _serverCount ?? state.valueOrNull ?? 0;
    }
  }
}

final venueFavoriteCountProvider = StateNotifierProvider.family<
    VenueFavoriteCountNotifier, AsyncValue<int>, String>((ref, venueId) {
  return VenueFavoriteCountNotifier(ref, venueId);
});

/// Featured venues with TTL cache.
final featuredVenuesProvider = FutureProvider<List<VenueModel>>((ref) async {
  final cacheManager = ref.watch(venuesCacheProvider.notifier);
  final supabase = ref.watch(supabaseProvider);
  ref.watch(authStateProvider);

  final userId = supabase.auth.currentUser?.id;
  final cacheKey = scopedFeaturedVenuesCacheKey(userId);

  if (cacheManager.hasValidCache(cacheKey)) {
    final cached = cacheManager.get(cacheKey);
    if (cached != null) return cached;
  }

  try {
    List<dynamic> response;

    if (userId != null) {
      response = await supabase
          .from('venues')
          .select('''
            *,
            user_favorites!left(user_id)
          ''')
          .gt('visit_count', 0)
          .order('visit_count', ascending: false)
          .order('name')
          .limit(5);
    } else {
      response = await supabase
          .from('venues')
          .select('*')
          .gt('visit_count', 0)
          .order('visit_count', ascending: false)
          .order('name')
          .limit(5);
    }

    final venues = response
        .map((json) => VenueModel.fromSupabaseJson(json, userId: userId))
        .toList();

    cacheManager.put(cacheKey, venues);
    return venues;
  } catch (e) {
    debugPrint('Error getting featured venues: $e');
    return [];
  }
});

/// Recently viewed venues.
final recentlyViewedVenuesProvider =
    FutureProvider<List<VenueModel>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return [];

  try {
    final response = await supabase
        .from('user_recent_views')
        .select('''
          venue_id,
          viewed_at,
          venues(*)
        ''')
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(10);

    final venues = <VenueModel>[];
    for (final row in response) {
      if (row['venues'] != null) {
        final venueData = row['venues'] as Map<String, dynamic>;
        venueData['is_favorite'] = false;
        venues.add(VenueModel.fromJson(venueData, venueData['id']));
      }
    }

    return venues;
  } catch (e) {
    debugPrint('Error getting recently viewed venues: $e');
    return [];
  }
});
