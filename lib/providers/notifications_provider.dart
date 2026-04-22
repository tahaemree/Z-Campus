import 'package:campus_online/models/notification_model.dart';
import 'package:campus_online/providers/service_providers.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcının tüm bildirimleri (kendi + broadcast).
final notificationsFeedProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);
  return service.fetchNotifications();
});

/// Okunmamış bildirim sayısı — badge için.
final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  ref.watch(authStateProvider);
  final service = ref.watch(notificationServiceProvider);
  return service.fetchUnreadCount();
});

/// Admin: geri bildirim listesi.
final adminFeedbackListProvider = FutureProvider.autoDispose
    .family<List<FeedbackItem>, String?>((ref, statusFilter) async {
  final service = ref.watch(notificationServiceProvider);
  return service.fetchFeedbacks(statusFilter: statusFilter);
});
