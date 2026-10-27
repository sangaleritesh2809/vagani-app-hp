class UserRoleAssignmentModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String roleId;
  final String roleKey;
  final String roleName;
  final String? organizationId;
  final String? organizationName;
  final String? groupId;
  final String? groupName;
  final String? assignedBy;
  final DateTime createdAt;

  const UserRoleAssignmentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone = '',
    this.userEmail = '',
    required this.roleId,
    required this.roleKey,
    required this.roleName,
    this.organizationId,
    this.organizationName,
    this.groupId,
    this.groupName,
    this.assignedBy,
    required this.createdAt,
  });

  String get scopeDescription {
    if (groupId != null && groupName != null && groupName!.isNotEmpty) {
      return 'Group: $groupName';
    }
    if (organizationId != null &&
        organizationName != null &&
        organizationName!.isNotEmpty) {
      return 'Organization: $organizationName';
    }
    return 'System Wide';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'user_email': userEmail,
      'role_id': roleId,
      'role_key': roleKey,
      'role_name': roleName,
      'organization_id': organizationId,
      'organization_name': organizationName,
      'group_id': groupId,
      'group_name': groupName,
      'assigned_by': assignedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserRoleAssignmentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? roleId,
    String? roleKey,
    String? roleName,
    String? organizationId,
    String? organizationName,
    String? groupId,
    String? groupName,
    String? assignedBy,
    DateTime? createdAt,
  }) {
    return UserRoleAssignmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      roleId: roleId ?? this.roleId,
      roleKey: roleKey ?? this.roleKey,
      roleName: roleName ?? this.roleName,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      assignedBy: assignedBy ?? this.assignedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserRoleAssignmentModel.fromJson(Map<String, dynamic> json) {
    String uName = 'User';
    String uPhone = '';
    String uEmail = '';
    if (json['profiles'] is Map) {
      final p = json['profiles'] as Map;
      uName = p['full_name'] as String? ?? 'User';
      uPhone = p['phone'] as String? ?? '';
      uEmail = p['email'] as String? ?? '';
    } else if (json['users'] is Map) {
      final p = json['users'] as Map;
      uName = p['name'] as String? ?? 'User';
      uPhone = p['phone'] as String? ?? '';
      uEmail = p['email'] as String? ?? '';
    }

    String rKey = 'PUBLIC_USER';
    String rName = 'Public User';
    if (json['roles'] is Map) {
      final r = json['roles'] as Map;
      rKey =
          r['role_key'] as String? ?? (r['code'] as String? ?? 'PUBLIC_USER');
      rName = r['name'] as String? ?? 'Public User';
    }

    String? orgName;
    if (json['organizations'] is Map) {
      orgName = (json['organizations'] as Map)['name'] as String?;
    }

    String? grpName;
    if (json['groups'] is Map) {
      grpName = (json['groups'] as Map)['name'] as String?;
    }

    return UserRoleAssignmentModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? uName,
      userPhone: json['user_phone'] as String? ?? uPhone,
      userEmail: json['user_email'] as String? ?? uEmail,
      roleId: json['role_id'] as String? ?? '',
      roleKey: json['role_key'] as String? ?? rKey,
      roleName: json['role_name'] as String? ?? rName,
      organizationId: json['organization_id'] as String?,
      organizationName: json['organization_name'] as String? ?? orgName,
      groupId: json['group_id'] as String?,
      groupName: json['group_name'] as String? ?? grpName,
      assignedBy: json['assigned_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
