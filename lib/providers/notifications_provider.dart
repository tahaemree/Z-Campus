import 'dart:async';

import 'package:campus_online/models/notification_model.dart';
import 'package:campus_online/providers/service_providers.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsFeedProvider = AsyncNotifierProvider.autoDispose<
    NotificationsFeedController, List<NotificationModel>>(
  NotificationsFeedController.new,
);

class NotificationsFeedController
    extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  StreamSubscription<List<NotificationModel>>? _subscription;
  late NotificationService _service;
  List<NotificationModel> _serverItems = const [];
  final Set<String> _optimisticReadIds = <String>{};
  final Set<String> _pendingDeleteIds = <String>{};
  bool _markAllAsReadPending = false;

  @override
  FutureOr<List<NotificationModel>> build() async {
    ref.watch(authStateProvider);
    _service = ref.read(notificationServiceProvider);
    ref.onDispose(_disposeSubscription);

    final items = await _service.fetchNotifications();
    _setServerItems(items, publish: false);
    _startSubscription();
    return _visibleItems;
  }

  Future<void> refresh() async {
    final items = await _service.fetchNotifications();
    _setServerItems(items);
  }

  Future<void> markAsRead(String notificationId) async {
    final item = _findVisibleItem(notificationId);
    if (item == null ||
        item.isRead ||
        _optimisticReadIds.contains(notificationId)) {
      return;
    }

    _optimisticReadIds.add(notificationId);
    _publishOptimisticState();

    try {
      await _service.markAsRead(notificationId);
      _serverItems = List<NotificationModel>.unmodifiable([
        for (final current in _serverItems)
          current.id == notificationId
              ? current.copyWith(isRead: true)
              : current,
      ]);
      _optimisticReadIds.remove(notificationId);
      _publishOptimisticState();
    } catch (error, stackTrace) {
      _optimisticReadIds.remove(notificationId);
      _publishOptimisticState();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> markAllAsRead() async {
    if (_visibleItems.isEmpty || _visibleItems.every((item) => item.isRead)) {
      return;
    }

    _markAllAsReadPending = true;
    _publishOptimisticState();

    try {
      await _service.markAllAsRead();
      _serverItems = List<NotificationModel>.unmodifiable([
        for (final item in _serverItems) item.copyWith(isRead: true),
      ]);
      _optimisticReadIds.clear();
      _markAllAsReadPending = false;
      _publishOptimisticState();
    } catch (error, stackTrace) {
      _markAllAsReadPending = false;
      _publishOptimisticState();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final exists = _visibleItems.any((item) => item.id == notificationId);
    if (!exists || _pendingDeleteIds.contains(notificationId)) {
      return;
    }

    _pendingDeleteIds.add(notificationId);
    _optimisticReadIds.remove(notificationId);
    _publishOptimisticState();

    try {
      await _service.deleteNotification(notificationId);
      _serverItems = List<NotificationModel>.unmodifiable([
        for (final item in _serverItems)
          if (item.id != notificationId) item,
      ]);
      _pendingDeleteIds.remove(notificationId);
      _publishOptimisticState();
    } catch (error, stackTrace) {
      _pendingDeleteIds.remove(notificationId);
      _publishOptimisticState();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  NotificationModel? _findVisibleItem(String notificationId) {
    for (final item in _visibleItems) {
      if (item.id == notificationId) {
        return item;
      }
    }
    return null;
  }

  List<NotificationModel> get _visibleItems {
    final items = <NotificationModel>[
      for (final item in _serverItems)
        if (!_pendingDeleteIds.contains(item.id))
          _markAllAsReadPending || _optimisticReadIds.contains(item.id)
              ? item.copyWith(isRead: true)
              : item,
    ];

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<NotificationModel>.unmodifiable(items);
  }

  void _setServerItems(
    List<NotificationModel> items, {
    bool publish = true,
  }) {
    _serverItems = List<NotificationModel>.unmodifiable(items);
    if (publish) {
      state = AsyncData(_visibleItems);
    }
  }

  void _publishOptimisticState() {
    state = AsyncData(_visibleItems);
  }

  void _startSubscription() {
    _disposeSubscription();
    _subscription = _service.watchNotifications().listen(
      _setServerItems,
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
  }

  void _disposeSubscription() {
    _subscription?.cancel();
    _subscription = null;
  }
}

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(
    notificationsFeedProvider.select(
      (notificationsAsync) =>
          notificationsAsync.valueOrNull
              ?.where((item) => !item.isRead)
              .length ??
          0,
    ),
  );
});

final adminFeedbackListProvider = FutureProvider.autoDispose
    .family<List<FeedbackItem>, String?>((ref, statusFilter) async {
  final service = ref.watch(notificationServiceProvider);
  return service.fetchFeedbacks(statusFilter: statusFilter);
});
