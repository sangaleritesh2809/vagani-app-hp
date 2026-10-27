class PermissionModel {
  final String id;
  final String code;
  final String module;
  final String action;
  final String description;

  const PermissionModel({
    this.id = '',
    required this.code,
    required this.module,
    required this.action,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'permission_key': code,
      'module': module,
      'action': action,
      'description': description,
    };
  }

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id'] as String? ?? '',
      code: (json['permission_key'] ?? json['code']) as String? ?? '',
      module: json['module'] as String? ?? '',
      action: json['action'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class RoleModel {
  final String id;
  final String code;
  final String roleKey;
  final String name;
  final String? organizationId;
  final String? groupId;
  final String scopeType; // 'system', 'organization', 'group'
  final bool isSystem;
  final bool isSystemRole;
  final bool isActive;
  final String description;
  final List<String> permissions;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int userCount;

  const RoleModel({
    required this.id,
    required this.code,
    String? roleKey,
    required this.name,
    this.organizationId,
    this.groupId,
    this.scopeType = 'system',
    this.isSystem = false,
    bool? isSystemRole,
    this.isActive = true,
    this.description = '',
    this.permissions = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.userCount = 0,
  })  : roleKey = roleKey ?? code,
        isSystemRole = isSystemRole ?? isSystem;

  bool get isSuperAdmin =>
      code == 'superAdmin' || roleKey == 'SUPER_ADMIN' || code == 'SUPER_ADMIN';

  bool get isOrgAdmin =>
      code == 'orgAdmin' || roleKey == 'ORG_ADMIN' || code == 'ORG_ADMIN';

  bool get isTreasurer =>
      code == 'treasurer' || roleKey == 'TREASURER' || code == 'TREASURER';

  bool get isCollector =>
      code == 'collector' || roleKey == 'COLLECTOR' || code == 'COLLECTOR';

  bool get isCustomRole => !isSystemRole && !isSuperAdmin;

  /// Check if role has permission
  bool hasPermission(String permCode) {
    if (isSuperAdmin) return true;
    if (!isActive) return false;
    if (permissions.contains('*')) return true;
    return permissions.contains(permCode);
  }

  bool can(String moduleKey, String action) {
    return hasPermission('$moduleKey.$action');
  }

  String get scopeDescription {
    switch (scopeType.toLowerCase()) {
      case 'group':
        return groupId != null ? 'Group Specific' : 'Group Level';
      case 'organization':
        return organizationId != null
            ? 'Organization Specific'
            : 'Organization Level';
      case 'system':
      default:
        return 'System Wide (Global)';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'role_key': roleKey,
      'name': name,
      'organization_id': organizationId,
      'group_id': groupId,
      'scope_type': scopeType,
      'scope': scopeType,
      'is_system': isSystem,
      'is_system_role': isSystemRole,
      'is_active': isActive,
      'description': description,
      'permissions': permissions,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_count': userCount,
    };
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    List<String> perms = [];
    if (rawPerms is List) {
      perms = rawPerms.map((e) => e.toString()).toList();
    }

    final key = (json['role_key'] ?? json['code']) as String? ?? '';
    final isSys = json['is_system_role'] is bool
        ? json['is_system_role'] as bool
        : (json['is_system'] is bool ? json['is_system'] as bool : false);

    final act = json['is_active'] is bool ? json['is_active'] as bool : true;

    final scope = (json['scope_type'] ?? json['scope']) as String? ?? 'system';

    return RoleModel(
      id: json['id'] as String? ?? '',
      code: key,
      roleKey: key,
      name: json['name'] as String? ?? '',
      organizationId: json['organization_id'] as String?,
      groupId: json['group_id'] as String?,
      scopeType: scope,
      isSystem: isSys,
      isSystemRole: isSys,
      isActive: act,
      description: json['description'] as String? ?? '',
      permissions: perms,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      userCount:
          (json['user_count'] is num) ? (json['user_count'] as num).toInt() : 0,
    );
  }

  RoleModel copyWith({
    String? id,
    String? code,
    String? roleKey,
    String? name,
    String? organizationId,
    String? groupId,
    String? scopeType,
    bool? isSystem,
    bool? isSystemRole,
    bool? isActive,
    String? description,
    List<String>? permissions,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? userCount,
  }) {
    return RoleModel(
      id: id ?? this.id,
      code: code ?? this.code,
      roleKey: roleKey ?? this.roleKey,
      name: name ?? this.name,
      organizationId: organizationId ?? this.organizationId,
      groupId: groupId ?? this.groupId,
      scopeType: scopeType ?? this.scopeType,
      isSystem: isSystem ?? this.isSystem,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userCount: userCount ?? this.userCount,
    );
  }
}
