import 'package:flutter/foundation.dart';
import 'package:campus_online/models/event_model.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

final upcomingEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  ref.watch(authStateProvider);
  final service = ref.watch(eventServiceProvider);
  return service.fetchUpcomingPublishedEvents();
});

final manageableEventsProvider =
    FutureProvider.family<List<EventModel>, String>((ref, query) async {
  ref.watch(authStateProvider);
  final service = ref.watch(eventServiceProvider);
  return service.fetchManageableEvents(query: query);
});

final eventByIdProvider =
    FutureProvider.family<EventModel, String>((ref, eventId) async {
  ref.watch(authStateProvider);
  final service = ref.watch(eventServiceProvider);
  return service.fetchEventById(eventId);
});

class EventFavoriteIdsNotifier extends StateNotifier<Set<String>> {
  EventFavoriteIdsNotifier(this._ref) : super(<String>{});

  final Ref _ref;

  Future<void> load() async {
    final service = _ref.read(eventServiceProvider);
    try {
      state = await service.fetchFavoriteEventIds();
    } catch (e) {
      debugPrint('Error loading event favorites: $e');
      state = <String>{};
    }
  }

  Future<void> toggle(String eventId) async {
    final service = _ref.read(eventServiceProvider);
    final isFavorite = state.contains(eventId);

    if (isFavorite) {
      state = Set<String>.from(state)..remove(eventId);
    } else {
      state = Set<String>.from(state)..add(eventId);
    }

    try {
      if (isFavorite) {
        await service.removeEventFavorite(eventId);
      } else {
        await service.addEventFavorite(eventId);
      }

      _ref.invalidate(favoriteEventsProvider);
    } catch (e) {
      if (isFavorite) {
        state = Set<String>.from(state)..add(eventId);
      } else {
        state = Set<String>.from(state)..remove(eventId);
      }
      rethrow;
    }
  }
}

final eventFavoriteIdsProvider =
    StateNotifierProvider<EventFavoriteIdsNotifier, Set<String>>((ref) {
  final notifier = EventFavoriteIdsNotifier(ref);

  ref.listen(authStateProvider, (_, __) {
    notifier.load();
  });

  notifier.load();
  return notifier;
});

final favoriteEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  ref.watch(authStateProvider);
  final service = ref.watch(eventServiceProvider);
  return service.fetchFavoriteEvents();
});

/// Derived provider: favorite events list.
/// Mirrors venue favorite behavior and keeps optimistic UI in sync.
final favoriteEventsListProvider = Provider<AsyncValue<List<EventModel>>>((ref) {
  final eventsAsync = ref.watch(favoriteEventsProvider);
  final upcomingEvents = ref.watch(upcomingEventsProvider).valueOrNull ??
      const <EventModel>[];
  final favoriteIds = ref.watch(eventFavoriteIdsProvider);

  return eventsAsync.whenData(
    (events) {
      final base = events
          .where((event) => favoriteIds.contains(event.id))
          .toList();

      final baseIds = base.map((event) => event.id).toSet();
      final optimistic = upcomingEvents
          .where(
            (event) =>
                favoriteIds.contains(event.id) && !baseIds.contains(event.id),
          )
          .toList();

      return [...base, ...optimistic];
    },
  );
});

void invalidateEvents(WidgetRef ref) {
  ref.invalidate(upcomingEventsProvider);
  ref.invalidate(favoriteEventsProvider);
}
