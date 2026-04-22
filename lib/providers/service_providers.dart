import 'package:campus_online/services/auth_service.dart';
import 'package:campus_online/services/contact_service.dart';
import 'package:campus_online/services/notification_service.dart';
import 'package:campus_online/services/profile_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
