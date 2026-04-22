import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:campus_online/services/access_control_service.dart';

/// Admin service with database-backed role checking.
///
/// Important: Server-side RLS policies must also enforce admin-only access
/// on the `venues` table for INSERT, UPDATE, DELETE operations.
/// Client-side checks alone are NOT sufficient for security.
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AccessControlService _accessControlService = AccessControlService();

  /// Checks if the current user has admin role.
  ///
  /// Primary source is `app_metadata['role']` to match RLS policy checks.
  bool isAdmin() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final appRole = user.appMetadata['role'];
    return appRole == 'admin';
  }

  Future<bool> isAdminAsync() {
    return _accessControlService.isCurrentUserAdmin();
  }

  Future<bool> canManageVenue(String venueId) async {
    final access = await _accessControlService.getCurrentUserAccess();
    return access.isAdmin || access.editableVenueIds.contains(venueId);
  }

  /// Add a new venue (admin only).
  Future<void> addVenue(Map<String, dynamic> venueData) async {
    if (!await isAdminAsync()) {
      throw Exception('Bu işlem için yetkiniz bulunmamaktadır.');
    }
    await _supabase.from('venues').insert(venueData);
  }

  /// Update an existing venue (admin only).
  Future<void> updateVenue(
    String venueId,
    Map<String, dynamic> venueData,
  ) async {
    if (!await canManageVenue(venueId)) {
      throw Exception('Bu işlem için yetkiniz bulunmamaktadır.');
    }
    await _supabase.from('venues').update(venueData).eq('id', venueId);
  }

  /// Delete a venue (admin only).
  Future<void> deleteVenue(String venueId) async {
    if (!await isAdminAsync()) {
      throw Exception('Bu işlem için yetkiniz bulunmamaktadır.');
    }

    try {
      await _supabase.from('venues').delete().eq('id', venueId);
    } catch (e) {
      debugPrint('Error deleting venue: $e');
      rethrow;
    }
  }
}
