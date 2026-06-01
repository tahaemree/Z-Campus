import 'dart:async';

import 'package:campus_online/models/notification_model.dart';
import 'package:campus_online/providers/notifications_provider.dart';
import 'package:campus_online/providers/service_providers.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('NotificationsFeedController', () {
    test('marks a notification as read immediately and updates unread badge',
        () async {
      final markAsReadCompleter = Completer<void>();
      final notification = _notification(id: 'n1', isRead: false);
      final fakeService = FakeNotificationService(
        initialNotifications: [
          notification,
          _notification(id: 'n2', isRead: true),
        ],
        markAsReadCompleter: markAsReadCompleter,
      );
      final container = _createContainer(fakeService);
      final subscription = container.listen(
        notificationsFeedProvider,
        (_, __) {},
        fireImmediately: true,
      );

      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(fakeService.dispose);

      await container.read(notificationsFeedProvider.future);

      final future =
          container.read(notificationsFeedProvider.notifier).markAsRead('n1');

      expect(
        container.read(unreadNotificationCountProvider),
        0,
      );
      expect(
        container
            .read(notificationsFeedProvider)
            .valueOrNull
            ?.firstWhere((item) => item.id == 'n1')
            .isRead,
        isTrue,
      );

      markAsReadCompleter.complete();
      await future;
    });

    test('deletes a notification immediately and refreshes unread badge',
        () async {
      final deleteCompleter = Completer<void>();
      final fakeService = FakeNotificationService(
        initialNotifications: [
          _notification(id: 'n1', isRead: false),
          _notification(id: 'n2', isRead: true),
        ],
        deleteNotificationCompleter: deleteCompleter,
      );
      final container = _createContainer(fakeService);
      final subscription = container.listen(
        notificationsFeedProvider,
        (_, __) {},
        fireImmediately: true,
      );

      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(fakeService.dispose);

      await container.read(notificationsFeedProvider.future);

      final future = container
          .read(notificationsFeedProvider.notifier)
          .deleteNotification('n1');

      expect(
        container.read(unreadNotificationCountProvider),
        0,
      );
      expect(
        container.read(notificationsFeedProvider).valueOrNull?.length,
        1,
      );

      deleteCompleter.complete();
      await future;
    });

    test('marks all notifications as read immediately and updates unread badge',
        () async {
      final markAllCompleter = Completer<void>();
      final fakeService = FakeNotificationService(
        initialNotifications: [
          _notification(id: 'n1', isRead: false),
          _notification(id: 'n2', isRead: false),
          _notification(id: 'n3', isRead: true),
        ],
        markAllAsReadCompleter: markAllCompleter,
      );
      final container = _createContainer(fakeService);
      final subscription = container.listen(
        notificationsFeedProvider,
        (_, __) {},
        fireImmediately: true,
      );

      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(fakeService.dispose);

      await container.read(notificationsFeedProvider.future);

      final future =
          container.read(notificationsFeedProvider.notifier).markAllAsRead();

      expect(container.read(unreadNotificationCountProvider), 0);
      expect(
        container
            .read(notificationsFeedProvider)
            .valueOrNull
            ?.every((item) => item.isRead),
        isTrue,
      );

      markAllCompleter.complete();
      await future;
    });

    test('restores unread notifications when mark all read fails', () async {
      final fakeService = FakeNotificationService(
        initialNotifications: [
          _notification(id: 'n1', isRead: false),
          _notification(id: 'n2', isRead: false),
        ],
        markAllAsReadError: Exception('database error'),
      );
      final container = _createContainer(fakeService);
      final subscription = container.listen(
        notificationsFeedProvider,
        (_, __) {},
        fireImmediately: true,
      );

      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(fakeService.dispose);

      await container.read(notificationsFeedProvider.future);

      await expectLater(
        container.read(notificationsFeedProvider.notifier).markAllAsRead(),
        throwsException,
      );

      expect(container.read(unreadNotificationCountProvider), 2);
      expect(
        container
            .read(notificationsFeedProvider)
            .valueOrNull
            ?.every((item) => !item.isRead),
        isTrue,
      );
    });

    test('restores a notification when delete fails', () async {
      final fakeService = FakeNotificationService(
        initialNotifications: [
          _notification(id: 'n1', isRead: false),
          _notification(id: 'n2', isRead: true),
        ],
        deleteNotificationError: Exception('database error'),
      );
      final container = _createContainer(fakeService);
      final subscription = container.listen(
        notificationsFeedProvider,
        (_, __) {},
        fireImmediately: true,
      );

      addTearDown(subscription.close);
      addTearDown(container.dispose);
      addTearDown(fakeService.dispose);

      await container.read(notificationsFeedProvider.future);

      await expectLater(
        container
            .read(notificationsFeedProvider.notifier)
            .deleteNotification('n1'),
        throwsException,
      );

      final items = container.read(notificationsFeedProvider).valueOrNull;
      expect(items?.map((item) => item.id), containsAll(['n1', 'n2']));
      expect(container.read(unreadNotificationCountProvider), 1);
    });
  });
}

ProviderContainer _createContainer(FakeNotificationService fakeService) {
  return ProviderContainer(
    overrides: [
      notificationServiceProvider.overrideWith((ref) => fakeService),
      authStateProvider.overrideWith(
        (ref) => Stream<AuthState>.value(
          const AuthState(AuthChangeEvent.initialSession, null),
        ),
      ),
    ],
  );
}

NotificationModel _notification({
  required String id,
  required bool isRead,
}) {
  final now = DateTime.utc(2026, 4, 22, 12);
  return NotificationModel(
    id: id,
    userId: 'user-1',
    title: 'Notification $id',
    body: 'Body for $id',
    type: 'general',
    targetId: null,
    isRead: isRead,
    createdBy: 'admin-1',
    createdAt: now,
    updatedAt: now,
  );
}

class FakeNotificationService extends NotificationService {
  FakeNotificationService({
    required List<NotificationModel> initialNotifications,
    this.markAsReadCompleter,
    this.deleteNotificationCompleter,
    this.markAllAsReadCompleter,
    this.deleteNotificationError,
    this.markAllAsReadError,
  })  : _notifications = List<NotificationModel>.from(initialNotifications),
        super(
          supabase: SupabaseClient(
            'http://localhost:54321',
            'public-anon-key',
          ),
        );

  final Completer<void>? markAsReadCompleter;
  final Completer<void>? deleteNotificationCompleter;
  final Completer<void>? markAllAsReadCompleter;
  final Object? deleteNotificationError;
  final Object? markAllAsReadError;
  final StreamController<List<NotificationModel>> _controller =
      StreamController<List<NotificationModel>>.broadcast();

  List<NotificationModel> _notifications;

  @override
  Future<List<NotificationModel>> fetchNotifications({int limit = 50}) async {
    return List<NotificationModel>.unmodifiable(_notifications);
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() => _controller.stream;

  @override
  Future<void> markAsRead(String notificationId) async {
    if (markAsReadCompleter != null) {
      await markAsReadCompleter!.future;
    }

    _notifications = List<NotificationModel>.unmodifiable([
      for (final item in _notifications)
        item.id == notificationId ? item.copyWith(isRead: true) : item,
    ]);
    _controller.add(_notifications);
  }

  @override
  Future<void> markAllAsRead() async {
    if (markAllAsReadCompleter != null) {
      await markAllAsReadCompleter!.future;
    }

    if (markAllAsReadError != null) {
      throw markAllAsReadError!;
    }

    _notifications = List<NotificationModel>.unmodifiable([
      for (final item in _notifications) item.copyWith(isRead: true),
    ]);
    _controller.add(_notifications);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    if (deleteNotificationCompleter != null) {
      await deleteNotificationCompleter!.future;
    }

    if (deleteNotificationError != null) {
      throw deleteNotificationError!;
    }

    _notifications = List<NotificationModel>.unmodifiable([
      for (final item in _notifications)
        if (item.id != notificationId) item,
    ]);
    _controller.add(_notifications);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
