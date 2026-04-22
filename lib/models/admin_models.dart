enum StaffRole { admin, sks }

String staffRoleToValue(StaffRole role) {
  switch (role) {
    case StaffRole.admin:
      return 'admin';
    case StaffRole.sks:
      return 'sks';
  }
}

String staffRoleLabel(StaffRole role) {
  switch (role) {
    case StaffRole.admin:
      return 'Admin';
    case StaffRole.sks:
      return 'SKS Etkinlik Yetkisi';
  }
}

StaffRole? staffRoleFromValue(String value) {
  switch (value) {
    case 'admin':
      return StaffRole.admin;
    case 'sks':
      return StaffRole.sks;
    default:
      return null;
  }
}

class UserAccessProfile {
  final bool isAdmin;
  final bool canManageEvents;
  final Set<StaffRole> roles;
  final Set<String> editableVenueIds;

  const UserAccessProfile({
    required this.isAdmin,
    required this.canManageEvents,
    required this.roles,
    required this.editableVenueIds,
  });

  const UserAccessProfile.empty()
      : isAdmin = false,
        canManageEvents = false,
        roles = const {},
        editableVenueIds = const {};
}

class AdminUserProfile {
  final String id;
  final String email;
  final String displayName;

  const AdminUserProfile({
    required this.id,
    required this.email,
    required this.displayName,
  });

  factory AdminUserProfile.fromJson(Map<String, dynamic> json) {
    return AdminUserProfile(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true
          ? (json['display_name'] as String).trim()
          : ((json['email'] as String?) ?? 'Kullanıcı'),
    );
  }
}

class UserPermissionBundle {
  final Set<StaffRole> roles;
  final Set<String> editableVenueIds;

  const UserPermissionBundle({
    required this.roles,
    required this.editableVenueIds,
  });
}
