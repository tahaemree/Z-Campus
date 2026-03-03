import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:campus_online/providers/cache_manager.dart';

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
      response = await supabase
          .from('venues')
          .select('''
            *,
            user_favorites!left(user_id)
          ''')
          .eq('category', category)
          .order('name');
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
final searchVenuesProvider =
    FutureProvider.autoDispose.family<List<VenueModel>, String>((ref, query) async {
  if (query.isEmpty) return [];

  try {
    final supabase = ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;

    List<dynamic> response;

    if (userId != null) {
      response = await supabase
          .from('venues')
          .select('''
            *,
            user_favorites!left(user_id)
          ''')
          .or('name.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%')
          .order('name');
    } else {
      response = await supabase
          .from('venues')
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%')
          .order('name');
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
  final cacheKey = 'venue_$venueId';

  if (cacheManager.hasValidCache(cacheKey)) {
    final cachedVenues = cacheManager.get(cacheKey);
    if (cachedVenues != null && cachedVenues.isNotEmpty) {
      return cachedVenues.first;
    }
  }

  try {
    final supabase = ref.watch(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;

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

/// Featured venues with TTL cache.
final featuredVenuesProvider = FutureProvider<List<VenueModel>>((ref) async {
  final cacheManager = ref.watch(venuesCacheProvider.notifier);
  const cacheKey = 'featured';

  if (cacheManager.hasValidCache(cacheKey)) {
    final cached = cacheManager.get(cacheKey);
    if (cached != null) return cached;
  }

  try {
    final supabase = ref.watch(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;

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
