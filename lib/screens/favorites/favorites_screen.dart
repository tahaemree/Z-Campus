import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/models/event_model.dart';
import 'package:campus_online/models/venue_model.dart';
import 'package:campus_online/providers/events_provider.dart';
import 'package:campus_online/providers/venue_actions.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/widgets/event_card.dart';
import 'package:campus_online/widgets/venue_list_sliver.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  void _handleVenueTap(String venueId) {
    Navigator.pushNamed(context, '/venue_details', arguments: venueId);
  }

  void _handleEventTap(String eventId) {
    Navigator.pushNamed(context, '/event_details', arguments: eventId);
  }

  Future<void> _toggleEventFavorite(
    String eventId,
    bool currentlyFavorite,
  ) async {
    try {
      await ref.read(eventFavoriteIdsProvider.notifier).toggle(eventId);
      if (!mounted) return;

      AppError.showSuccess(
        context,
        currentlyFavorite
            ? 'Etkinlik favorilerden çıkarıldı.'
            : 'Etkinlik favorilere eklendi.',
      );
    } catch (e) {
      if (!mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  SliverToBoxAdapter _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionEmpty({
    required BuildContext context,
    required String message,
  }) {
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Derived providers - updates instantly when favorite IDs change
    final favVenuesAsync = ref.watch(favoriteVenuesList);
    final favEventsAsync = ref.watch(favoriteEventsListProvider);
    final favoriteEventIds = ref.watch(eventFavoriteIdsProvider);
    final theme = Theme.of(context);

    final venuesLoading =
        favVenuesAsync.isLoading && favVenuesAsync.valueOrNull == null;
    final eventsLoading =
        favEventsAsync.isLoading && favEventsAsync.valueOrNull == null;

    if (venuesLoading || eventsLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (favVenuesAsync.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Favorilerim',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: CustomScrollView(
          slivers: [
            VenueErrorState(
              error: favVenuesAsync.error!,
              title: 'Mekan favorileri yüklenemedi',
            ),
          ],
        ),
      );
    }

    if (favEventsAsync.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Favorilerim',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: CustomScrollView(
          slivers: [
            VenueErrorState(
              error: favEventsAsync.error!,
              title: 'Etkinlik favorileri yüklenemedi',
            ),
          ],
        ),
      );
    }

    final favoriteVenues = favVenuesAsync.valueOrNull ?? <VenueModel>[];
    final favoriteEvents = favEventsAsync.valueOrNull ?? <EventModel>[];
    final hasAnyFavorite =
        favoriteVenues.isNotEmpty || favoriteEvents.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorilerim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          try {
            clearVenuesCache(ref);
            ref.invalidate(venuesProvider);
            invalidateEvents(ref);

            await Future.wait([
              ref.read(favoriteIdsProvider.notifier).load(),
              ref.read(eventFavoriteIdsProvider.notifier).load(),
              ref.refresh(venuesProvider.future),
              ref.refresh(favoriteEventsProvider.future),
            ]);

            if (!context.mounted) return;
            AppError.showSuccess(context, 'Favoriler yenilendi.');
          } catch (e) {
            if (!context.mounted) return;
            AppError.showError(context, AppError.getUserFriendlyMessage(e));
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (!hasAnyFavorite)
              const VenueEmptyState(
                icon: Icons.favorite_border,
                title: 'Henüz favori içerik yok',
                subtitle:
                    'Favorilerinizi burada görmek için mekan veya etkinlik favorileyin',
              )
            else ...[
              _buildSectionHeader(
                context: context,
                icon: Icons.event,
                title: 'Etkinlik Favorileri',
              ),
              if (favoriteEvents.isEmpty)
                _buildSectionEmpty(
                  context: context,
                  message: 'Henüz favori etkinlik yok.',
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = favoriteEvents[index];
                        final isFavorite = favoriteEventIds.contains(event.id);
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: EventCard(
                            event: event,
                            isFavorite: isFavorite,
                            onTap: () => _handleEventTap(event.id),
                            onFavoriteToggle: () =>
                                _toggleEventFavorite(event.id, isFavorite),
                          ),
                        );
                      },
                      childCount: favoriteEvents.length,
                    ),
                  ),
                ),
              _buildSectionHeader(
                context: context,
                icon: Icons.place,
                title: 'Mekan Favorileri',
              ),
              if (favoriteVenues.isEmpty)
                _buildSectionEmpty(
                  context: context,
                  message: 'Henüz favori mekan yok.',
                )
              else
                VenueListSliver(
                  venues: favoriteVenues,
                  onVenueTap: _handleVenueTap,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
