import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/providers/cache_manager.dart';
import 'package:campus_online/models/venue_model.dart';

// ──────────────────────────────────────────────────────────
// FAVORITE STATE — Single source of truth
// ──────────────────────────────────────────────────────────

/// Manages the set of favorited venue IDs locally.
/// This is the ONLY place favorite state lives.
/// Toggle is optimistic — UI updates instantly, API syncs in background.
class FavoriteIdsNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;

  FavoriteIdsNotifier(this._ref) : super({});

  /// Load favorite IDs from Supabase.
  Future<void> load() async {
    final supabase = _ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = {};
      return;
    }

    try {
      final response = await supabase
          .from('user_favorites')
          .select('venue_id')
          .eq('user_id', userId);

      state = {for (final row in response) row['venue_id'] as String};
    } catch (e) {
      debugPrint('Error loading favorite IDs: $e');
    }
  }

  /// Toggle favorite — optimistic update, revert on failure.
  Future<void> toggle(String venueId) async {
    final supabase = _ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Favorilere eklemek için giriş yapmalısınız.');

    final wasFavorite = state.contains(venueId);

    // ─── OPTIMISTIC: Update Set immediately ───
    if (wasFavorite) {
      state = Set<String>.from(state)..remove(venueId);
    } else {
      state = Set<String>.from(state)..add(venueId);
    }

    // ─── API CALL: Sync with server ───
    try {
      if (!wasFavorite) {
        await supabase.from('user_favorites').insert({
          'user_id': userId,
          'venue_id': venueId,
        });
      } else {
        await supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('venue_id', venueId);
      }
    } catch (e) {
      // ─── REVERT: Undo optimistic update on failure ───
      if (wasFavorite) {
        state = Set<String>.from(state)..add(venueId);
      } else {
        state = Set<String>.from(state)..remove(venueId);
      }
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }
}

/// Provider for the favorite IDs set.
/// Reloads when auth state changes (login/logout/user switch).
final favoriteIdsProvider =
    StateNotifierProvider<FavoriteIdsNotifier, Set<String>>((ref) {
  final notifier = FavoriteIdsNotifier(ref);

  // Reload favorites whenever auth state changes
  ref.listen(authStateProvider, (_, __) {
    notifier.load();
  });

  // Initial load
  notifier.load();
  return notifier;
});

/// Derived provider: favorite venues list.
/// Instantly updates when favoriteIdsProvider changes — no API refetch needed.
final favoriteVenuesList = Provider<AsyncValue<List<VenueModel>>>((ref) {
  final allVenuesAsync = ref.watch(venuesProvider);
  final favIds = ref.watch(favoriteIdsProvider);
  return allVenuesAsync.whenData(
    (venues) => venues.where((v) => favIds.contains(v.id)).toList(),
  );
});

// ──────────────────────────────────────────────────────────
// VENUE ACTIONS
// ──────────────────────────────────────────────────────────

/// Increment venue visit count and record view.
Future<void> incrementVisitCount(WidgetRef ref, String venueId) async {
  try {
    final supabase = ref.read(supabaseProvider);
    await supabase
        .rpc('increment_visit_count', params: {'p_venue_id': venueId});

    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      await supabase.from('user_recent_views').upsert(
        {
          'user_id': userId,
          'venue_id': venueId,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,venue_id',
      );
    }
  } catch (e) {
    debugPrint('Error incrementing visit count: $e');
  }
}

/// Clear venues cache — type-safe.
void clearVenuesCache(WidgetRef ref, {String? specificKey}) {
  final cacheManager = ref.read(venuesCacheProvider.notifier);
  if (specificKey != null) {
    cacheManager.invalidate(specificKey);
  } else {
    cacheManager.clear();
  }
}
