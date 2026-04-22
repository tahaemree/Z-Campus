import 'package:campus_online/models/admin_models.dart';
import 'package:campus_online/providers/venue_provider.dart';
import 'package:campus_online/services/access_control_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accessControlServiceProvider = Provider<AccessControlService>((ref) {
  return AccessControlService();
});

final currentUserAccessProvider =
    FutureProvider.autoDispose<UserAccessProfile>((ref) async {
  ref.watch(authStateProvider);
  final service = ref.watch(accessControlServiceProvider);
  return service.getCurrentUserAccess();
});

final adminUserSearchProvider =
    FutureProvider.family<List<AdminUserProfile>, String>((ref, query) async {
  final service = ref.watch(accessControlServiceProvider);
  return service.searchUsers(query: query);
});

final userPermissionBundleProvider =
    FutureProvider.family<UserPermissionBundle, String>((ref, userId) async {
  final service = ref.watch(accessControlServiceProvider);
  return service.getUserPermissionBundle(userId);
});
