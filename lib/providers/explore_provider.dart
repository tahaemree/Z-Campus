import 'package:campus_online/models/explore_models.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/services/explore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exploreServiceProvider = Provider<ExploreService>((ref) {
  return ExploreService(supabase: ref.watch(supabaseProvider));
});

final exploreSettingsProvider = FutureProvider<ExploreSettings>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(exploreServiceProvider).fetchSettings();
});

final exploreContributionsProvider =
    FutureProvider<List<ExploreContribution>>((ref) async {
  ref.watch(authStateProvider);
  final settings = ref.watch(exploreSettingsProvider).valueOrNull ??
      ExploreSettings.defaults;

  if (!settings.showContributions) {
    return <ExploreContribution>[];
  }

  return ref.watch(exploreServiceProvider).fetchActiveContributions(
        limit: settings.contributionsLimit,
      );
});

final adminExploreContributionsProvider =
    FutureProvider.autoDispose<List<ExploreContribution>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(exploreServiceProvider).fetchAdminContributions();
});

final exploreRecentlyViewedVenuesProvider =
    FutureProvider<List<VenueModel>>((ref) async {
  ref.watch(authStateProvider);
  final settings = ref.watch(exploreSettingsProvider).valueOrNull ??
      ExploreSettings.defaults;

  if (!settings.showRecentViews) {
    return <VenueModel>[];
  }

  return ref.watch(exploreServiceProvider).fetchRecentlyViewedVenues(
        limit: settings.recentViewsLimit,
      );
});

void invalidateExplore(WidgetRef ref) {
  ref.invalidate(exploreSettingsProvider);
  ref.invalidate(exploreContributionsProvider);
  ref.invalidate(adminExploreContributionsProvider);
  ref.invalidate(exploreRecentlyViewedVenuesProvider);
}
