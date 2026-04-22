import 'package:campus_online/commons/postgrest_helpers.dart';
import 'package:campus_online/models/admin_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessControlService {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isAdminFromMetadata(User user) {
    final appRole = user.appMetadata['role'];
    return appRole == 'admin';
  }

  bool _isRelationMissing(PostgrestException error, String relationHint) {
    if (error.code == '42P01') return true;

    final message = error.message.toLowerCase();
    return message.contains('relation') &&
        message.contains('does not exist') &&
        message.contains(relationHint.toLowerCase());
  }

  Future<Set<StaffRole>> _fetchRolesForUser(String userId) async {
    try {
      final rows = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);

      return rows
          .map((row) => staffRoleFromValue(row['role'] as String? ?? ''))
          .whereType<StaffRole>()
          .toSet();
    } on PostgrestException catch (error) {
      // Table might not exist before migration is applied.
      if (_isRelationMissing(error, 'user_roles')) {
        return <StaffRole>{};
      }
      rethrow;
    } catch (_) {
      return <StaffRole>{};
    }
  }

  Future<Set<String>> _fetchVenuePermissionsForUser(String userId) async {
    try {
      final rows = await _supabase
          .from('user_venue_permissions')
          .select('venue_id')
          .eq('user_id', userId);

      return rows
          .map((row) => row['venue_id'] as String?)
          .whereType<String>()
          .toSet();
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'user_venue_permissions')) {
        return <String>{};
      }
      rethrow;
    } catch (_) {
      return <String>{};
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    final access = await getCurrentUserAccess();
    return access.isAdmin;
  }

  Future<UserAccessProfile> getCurrentUserAccess() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const UserAccessProfile.empty();

    final roles = await _fetchRolesForUser(user.id);
    final editableVenueIds = await _fetchVenuePermissionsForUser(user.id);
    final isAdmin =
        _isAdminFromMetadata(user) || roles.contains(StaffRole.admin);

    return UserAccessProfile(
      isAdmin: isAdmin,
      canManageEvents: isAdmin || roles.contains(StaffRole.sks),
      roles: roles,
      editableVenueIds: editableVenueIds,
    );
  }

  Future<List<AdminUserProfile>> searchUsers({String query = ''}) async {
    final trimmed = query.trim();

    try {
      final base = _supabase
          .from('users')
          .select('id, email, display_name')
          .order('display_name')
          .limit(50);

      final dynamic rows = trimmed.isEmpty
          ? await base
          : await _supabase
              .from('users')
              .select('id, email, display_name')
              .or(
                'display_name.ilike.%${escapePostgrestLikeValue(trimmed)}%,email.ilike.%${escapePostgrestLikeValue(trimmed)}%',
              )
              .order('display_name')
              .limit(50);

      return (rows as List<dynamic>)
          .map((row) => AdminUserProfile.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (_isRelationMissing(error, 'users')) {
        return <AdminUserProfile>[];
      }
      rethrow;
    } catch (_) {
      return <AdminUserProfile>[];
    }
  }

  String? _extractFunctionErrorMessage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final errorValue = payload['error'];
      if (errorValue is String && errorValue.trim().isNotEmpty) {
        return errorValue.trim();
      }

      final messageValue = payload['message'];
      if (messageValue is String && messageValue.trim().isNotEmpty) {
        return messageValue.trim();
      }
    }

    if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }

    return null;
  }

  Future<UserPermissionBundle> getUserPermissionBundle(String userId) async {
    final roles = await _fetchRolesForUser(userId);
    final editableVenueIds = await _fetchVenuePermissionsForUser(userId);
    return UserPermissionBundle(
      roles: roles,
      editableVenueIds: editableVenueIds,
    );
  }

  Future<void> replaceUserRoles(String userId, Set<StaffRole> roles) async {
    final actorId = _supabase.auth.currentUser?.id;

    await _supabase.from('user_roles').delete().eq('user_id', userId);

    if (roles.isEmpty) return;

    final payload = roles
        .map(
          (role) => {
            'user_id': userId,
            'role': staffRoleToValue(role),
            'created_by': actorId,
          },
        )
        .toList();

    await _supabase.from('user_roles').insert(payload);
  }

  Future<void> replaceUserVenuePermissions(
    String userId,
    Set<String> venueIds,
  ) async {
    final actorId = _supabase.auth.currentUser?.id;

    await _supabase
        .from('user_venue_permissions')
        .delete()
        .eq('user_id', userId);

    if (venueIds.isEmpty) return;

    final payload = venueIds
        .map(
          (venueId) => {
            'user_id': userId,
            'venue_id': venueId,
            'created_by': actorId,
          },
        )
        .toList();

    await _supabase.from('user_venue_permissions').insert(payload);
  }

  Future<void> updateUserPermissions({
    required String userId,
    required Set<StaffRole> roles,
    required Set<String> editableVenueIds,
  }) async {
    await replaceUserRoles(userId, roles);
    await replaceUserVenuePermissions(userId, editableVenueIds);
  }

  Future<String> createStaffAccount({
    required String email,
    required String password,
    required String displayName,
    required Set<StaffRole> roles,
    required Set<String> editableVenueIds,
  }) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      throw Exception('Bu işlem için admin yetkisi gerekiyor.');
    }

    final cleanEmail = email.trim().toLowerCase();
    final cleanDisplayName = displayName.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Geçerli bir e-posta girin.');
    }

    if (password.length < 6) {
      throw Exception('Şifre en az 6 karakter olmalı.');
    }

    try {
      final response = await _supabase.functions.invoke(
        'create-staff-account',
        body: {
          'email': cleanEmail,
          'password': password,
          'display_name': cleanDisplayName,
          'roles': roles.map(staffRoleToValue).toList(),
          'editable_venue_ids': editableVenueIds.toList(),
        },
      );

      if (response.status >= 400) {
        throw Exception(
          _extractFunctionErrorMessage(response.data) ??
              'Personel hesabı oluşturulamadı.',
        );
      }

      final payload = response.data;
      final userId = payload is Map<String, dynamic>
          ? payload['user_id'] as String?
          : null;

      if (userId == null || userId.isEmpty) {
        throw Exception(
          'Personel hesabı oluşturuldu ancak kullanıcı kimliği alınamadı.',
        );
      }

      return userId;
    } on FunctionException catch (error) {
      throw Exception(
        _extractFunctionErrorMessage(error.details) ??
            'Personel hesabı oluşturulamadı.',
      );
    }
  }
}
