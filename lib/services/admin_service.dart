import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Admin service with database-backed role checking.
///
/// Important: Server-side RLS policies must also enforce admin-only access
/// on the `venues` table for INSERT, UPDATE, DELETE operations.
/// Client-side checks alone are NOT sufficient for security.
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Checks if the current user has admin role.
  ///
  /// Uses user_metadata['role'] set during user creation/promotion.
  /// The hardcoded email fallback is for backward compatibility only.
  ///
  /// TODO: Replace with a dedicated `user_roles` table + RLS for production.
  bool isAdmin() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final role = user.userMetadata?['role'];
    if (role == 'admin') return true;

    // Legacy fallback — remove once role-based system is fully in place
    return user.email == 'admin@admin.com';
  }

  /// Add a new venue (admin only).
  Future<void> addVenue(Map<String, dynamic> venueData) async {
    if (!isAdmin()) {
      throw Exception('Bu işlem için yetkiniz bulunmamaktadır.');
    }
    await _supabase.from('venues').insert(venueData);
  }

  /// Update an existing venue (admin only).
  Future<void> updateVenue(
      String venueId, Map<String, dynamic> venueData) async {
    if (!isAdmin()) {
      throw Exception('Bu işlem için yetkiniz bulunmamaktadır.');
    }
    await _supabase.from('venues').update(venueData).eq('id', venueId);
  }

  /// Delete a venue (admin only).
  Future<void> deleteVenue(String venueId) async {
    if (!isAdmin()) {
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
