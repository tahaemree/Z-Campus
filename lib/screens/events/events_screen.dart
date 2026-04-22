import 'package:campus_online/commons/app_error.dart';
import 'package:campus_online/providers/access_provider.dart';
import 'package:campus_online/providers/events_provider.dart';
import 'package:campus_online/screens/events/event_management_screen.dart';
import 'package:campus_online/widgets/event_card.dart';
import 'package:campus_online/widgets/venue_list_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  void _openEventDetail(BuildContext context, String eventId) {
    Navigator.pushNamed(context, '/event_details', arguments: eventId);
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    bool currentlyFavorite,
  ) async {
    try {
      await ref.read(eventFavoriteIdsProvider.notifier).toggle(eventId);
      if (!context.mounted) return;
      AppError.showSuccess(
        context,
        currentlyFavorite
            ? 'Etkinlik favorilerden çıkarıldı.'
            : 'Etkinlik favorilere eklendi.',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppError.showError(context, AppError.getUserFriendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final accessAsync = ref.watch(currentUserAccessProvider);
    final favoriteEventIds = ref.watch(eventFavoriteIdsProvider);

    final canManageEvents = accessAsync.maybeWhen(
      data: (access) => access.canManageEvents,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlikler'),
        actions: [
          if (canManageEvents)
            TextButton.icon(
              onPressed: () async {
                try {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EventManagementScreen(),
                    ),
                  );

                  invalidateEvents(ref);
                  await Future.wait([
                    ref.read(eventFavoriteIdsProvider.notifier).load(),
                    ref.refresh(upcomingEventsProvider.future),
                    ref.refresh(favoriteEventsProvider.future),
                  ]);

                  if (!context.mounted) return;
                  AppError.showSuccess(
                      context, 'Etkinlik listesi güncellendi.');
                } catch (e) {
                  if (!context.mounted) return;
                  AppError.showError(
                    context,
                    AppError.getUserFriendlyMessage(e),
                  );
                }
              },
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Yönet'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            invalidateEvents(ref);
            await Future.wait([
              ref.read(eventFavoriteIdsProvider.notifier).load(),
              ref.refresh(upcomingEventsProvider.future),
              ref.refresh(favoriteEventsProvider.future),
            ]);

            if (!context.mounted) return;
            AppError.showSuccess(context, 'Etkinlikler yenilendi.');
          } catch (e) {
            if (!context.mounted) return;
            AppError.showError(context, AppError.getUserFriendlyMessage(e));
          }
        },
        child: eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  VenueEmptyState(
                    icon: Icons.event_busy,
                    title: 'Henüz yayınlanmış etkinlik yok',
                    subtitle:
                        'Yeni etkinlikler yayınlandığında burada listelenecek.',
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isFavorite = favoriteEventIds.contains(event.id);
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: EventCard(
                    event: event,
                    isFavorite: isFavorite,
                    onTap: () => _openEventDetail(context, event.id),
                    onFavoriteToggle: () => _toggleFavorite(
                      context,
                      ref,
                      event.id,
                      isFavorite,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => ListView(
            children: const [
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              Text('Etkinlikler yüklenemedi: $error'),
            ],
          ),
        ),
      ),
    );
  }
}
