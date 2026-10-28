import 'package:uuid/uuid.dart';
import 'user_role_assignment_model.dart';

enum UserRole {
  superAdmin,
  orgAdmin,
  groupAdmin,
  treasurer,
  collector,
  viewer,
  publicUser,
  citizen, // Alias for publicUser
  custom,
}

extension UserRoleExtension on UserRole {
  String get nameString {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.orgAdmin:
        return 'Organization Admin';
      case UserRole.groupAdmin:
        return 'Group Admin';
      case UserRole.treasurer:
        return 'Treasurer';
      case UserRole.collector:
        return 'Collection Agent';
      case UserRole.viewer:
        return 'Viewer (Read Only)';
      case UserRole.publicUser:
      case UserRole.citizen:
        return 'Citizen / Public';
      case UserRole.custom:
        return 'Custom Role';
    }
  }

  String get roleKey {
    switch (this) {
      case UserRole.superAdmin:
        return 'SUPER_ADMIN';
      case UserRole.orgAdmin:
        return 'ORG_ADMIN';
      case UserRole.groupAdmin:
        return 'GROUP_ADMIN';
      case UserRole.treasurer:
        return 'TREASURER';
      case UserRole.collector:
        return 'COLLECTOR';
      case UserRole.viewer:
        return 'VIEWER';
      case UserRole.publicUser:
      case UserRole.citizen:
        return 'PUBLIC_USER';
      case UserRole.custom:
        return 'CUSTOM';
    }
  }

  String get localizedKey {
    switch (this) {
      case UserRole.superAdmin:
        return 'superAdmin';
      case UserRole.orgAdmin:
        return 'orgAdmin';
      case UserRole.groupAdmin:
        return 'groupAdmin';
      case UserRole.treasurer:
        return 'treasurer';
      case UserRole.collector:
        return 'collector';
      case UserRole.viewer:
        return 'viewer';
      case UserRole.publicUser:
      case UserRole.citizen:
        return 'citizen';
      case UserRole.custom:
        return 'custom';
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
  final String? customRoleName;
  final String? avatarUrl;
  final bool isActive;
  final String accountStatus; // 'active', 'inactive', 'suspended'
  final List<String> groupIds;
  final List<String> permissions;
  final String? selectedGroupId;
  final String? selectedGroupName;

  final String? address;
  final String? notes;
  final String? passwordHash;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<UserRoleAssignmentModel> roleAssignments;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.organizationId,
    required this.role,
    this.customRoleName,
    this.avatarUrl,
    this.isActive = true,
    this.accountStatus = 'active',
    this.groupIds = const ['grp_001'],
    this.permissions = const [],
    this.selectedGroupId,
    this.selectedGroupName,
    this.address,
    this.notes,
    this.passwordHash,
    this.createdAt,
    this.updatedAt,
    this.roleAssignments = const [],
  });

  bool get isSuspended => accountStatus == 'suspended';
  bool get isInactive => accountStatus == 'inactive' || !isActive;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isOrgAdmin => role == UserRole.orgAdmin;
  bool get isGroupAdmin => role == UserRole.groupAdmin;
  bool get isCollector => role == UserRole.collector;
  bool get isViewer => role == UserRole.viewer;
  bool get isPublicUser =>
      role == UserRole.publicUser || role == UserRole.citizen;
  bool get isCitizen => isPublicUser;

  bool hasPermission(String permCode) {
    if (isSuperAdmin) return true;
    if (isInactive || isSuspended) return false;
    if (permissions.contains('*')) return true;
    return permissions.contains(permCode);
  }

  bool can(String module, String action) {
    return hasPermission('$module.$action');
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? organizationId,
    UserRole? role,
    String? customRoleName,
    String? avatarUrl,
    bool? isActive,
    String? accountStatus,
    List<String>? groupIds,
    List<String>? permissions,
    String? selectedGroupId,
    String? selectedGroupName,
    String? address,
    String? notes,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<UserRoleAssignmentModel>? roleAssignments,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      organizationId: organizationId ?? this.organizationId,
      role: role ?? this.role,
      customRoleName: customRoleName ?? this.customRoleName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      accountStatus: accountStatus ?? this.accountStatus,
      groupIds: groupIds ?? this.groupIds,
      permissions: permissions ?? this.permissions,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedGroupName: selectedGroupName ?? this.selectedGroupName,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roleAssignments: roleAssignments ?? this.roleAssignments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': name,
      'phone': phone,
      'email': email,
      'organizationId': organizationId,
      'organization_id': organizationId,
      'role': role.name,
      'role_key': role.roleKey,
      'custom_role_name': customRoleName,
      'avatarUrl': avatarUrl,
      'avatar_url': avatarUrl,
      'is_active': isActive,
      'account_status': accountStatus,
      'group_ids': groupIds,
      'permissions': permissions,
      'selected_group_id': selectedGroupId,
      'selected_group_name': selectedGroupName,
      'address': address,
      'notes': notes,
      if (passwordHash != null) 'password_hash': passwordHash,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static UserRole parseRole(String raw) {
    switch (raw.toUpperCase()) {
      case 'SUPER_ADMIN':
      case 'SUPERADMIN':
        return UserRole.superAdmin;
      case 'ORG_ADMIN':
      case 'ORGADMIN':
        return UserRole.orgAdmin;
      case 'GROUP_ADMIN':
      case 'GROUPADMIN':
        return UserRole.groupAdmin;
      case 'TREASURER':
        return UserRole.treasurer;
      case 'COLLECTOR':
        return UserRole.collector;
      case 'VIEWER':
        return UserRole.viewer;
      case 'PUBLIC_USER':
      case 'PUBLICUSER':
      case 'CITIZEN':
        return UserRole.publicUser;
      case 'CUSTOM':
        return UserRole.custom;
      default:
        for (final r in UserRole.values) {
          if (r.name.toLowerCase() == raw.toLowerCase()) {
            return r;
          }
        }
        return UserRole.citizen;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleRaw =
        (json['role_key'] ?? json['role'] ?? 'citizen').toString().trim();
    final parsedRole = parseRole(roleRaw);

    final rawGroupIds = json['group_ids'] ?? json['groupIds'];
    List<String> parsedGroupIds = ['grp_001'];
    if (rawGroupIds is List) {
      parsedGroupIds = rawGroupIds.map((e) => e.toString()).toList();
    }

    final rawPerms = json['permissions'];
    List<String> parsedPerms = [];
    if (rawPerms is List) {
      parsedPerms = rawPerms.map((e) => e.toString()).toList();
    }

    final statusStr = json['account_status'] as String? ??
        (json['is_active'] == false || json['isActive'] == false
            ? 'inactive'
            : 'active');

    return UserModel(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['full_name'] as String? ?? json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      organizationId:
          (json['organizationId'] ?? json['organization_id']) as String? ??
              'org_001',
      role: parsedRole,
      customRoleName: json['custom_role_name'] as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      isActive: statusStr == 'active',
      accountStatus: statusStr,
      groupIds: parsedGroupIds,
      permissions: parsedPerms,
      selectedGroupId: json['selected_group_id'] as String?,
      selectedGroupName: json['selected_group_name'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      passwordHash: (json['password_hash'] ?? json['passwordHash']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
