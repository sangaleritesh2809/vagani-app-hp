enum UserRole {
  superAdmin,
  orgAdmin,
  treasurer,
  collector,
  citizen,
}

extension UserRoleExtension on UserRole {
  String get nameString {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.orgAdmin:
        return 'Organization Admin';
      case UserRole.treasurer:
        return 'Treasurer';
      case UserRole.collector:
        return 'Collection Agent';
      case UserRole.citizen:
        return 'Citizen / Public';
    }
  }

  String get localizedKey {
    switch (this) {
      case UserRole.superAdmin:
        return 'superAdmin';
      case UserRole.orgAdmin:
        return 'orgAdmin';
      case UserRole.treasurer:
        return 'treasurer';
      case UserRole.collector:
        return 'collector';
      case UserRole.citizen:
        return 'citizen';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String organizationId;
  final UserRole role;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.organizationId,
    required this.role,
    this.avatarUrl,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? organizationId,
    UserRole? role,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      organizationId: organizationId ?? this.organizationId,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
