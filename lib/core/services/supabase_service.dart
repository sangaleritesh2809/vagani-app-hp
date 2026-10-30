import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/organization_model.dart';
import '../models/campaign_model.dart';
import '../models/household_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';
import '../models/expense_model.dart';
import '../models/complaint_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/role_model.dart';
import '../models/join_request_model.dart';
import '../models/user_role_assignment_model.dart';
import '../models/audit_log_model.dart';
import 'mock_data_service.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://lqeohtminzfjhqclcnkm.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_37wNhigxEZLq6Q4IX5yUgQ_skrYDc8i';
}

class SupabaseService {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _initialized = true;
      debugPrint(
          '✓ Supabase connected successfully: ${SupabaseConfig.supabaseUrl}');
    } catch (e) {
      _initialized = false;
      debugPrint(
          'ℹ Supabase initialization note: $e (Falling back to local cache)');
    }
  }

  // ===========================================================================
  // 1. ORGANIZATIONS
  // ===========================================================================
  static Future<List<OrganizationModel>?> getOrganizations() async {
    final c = client;
    if (c != null) {
      try {
        final res = await c
            .from('organizations')
            .select()
            .order('name', ascending: true);
        final list = (res as List)
            .map((row) =>
                OrganizationModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
        if (list.isNotEmpty) {
          if (kDebugMode) {
            for (final org in list) {
              MockDataService.addOrganization(org);
            }
          }
          return list;
        }
      } catch (e) {
        debugPrint('Supabase getOrganizations error: $e');
      }
    }
    return kDebugMode ? MockDataService.organizations : null;
  }

  static Future<bool> insertOrganization(OrganizationModel org) async {
    // 1. Always save in local memory immediately
    MockDataService.addOrganization(org);

    final c = client;
    if (c == null) return true;
    try {
      final json = org.toSupabaseJson();
      await c.from('organizations').insert(json);
      return true;
    } catch (e) {
      debugPrint('Supabase insertOrganization error: $e');
      // Even if remote insert fails or table is offline, local storage retains the record
      return true;
    }
  }

  static Future<bool> updateOrganization(
      String id, Map<String, dynamic> data) async {
    final c = client;
    if (c != null) {
      try {
        await c.from('organizations').update(data).eq('id', id);
      } catch (e) {
        debugPrint('Supabase updateOrganization error: $e');
      }
    }
    return true;
  }

  static Future<bool> archiveOrganization(String id) async {
    return updateOrganization(id, {'status': 'archived'});
  }

  // ===========================================================================
  // 2. GROUPS
  // ===========================================================================
  static Future<List<GroupModel>?> getGroups({String? organizationId}) async {
    final c = client;
    if (c != null) {
      try {
        var query = c.from('groups').select();
        if (organizationId != null && organizationId.isNotEmpty) {
          query = query.eq('organization_id', organizationId);
        }
        final res = await query.order('name', ascending: true);
        final list = (res as List)
            .map((row) => GroupModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
        if (list.isNotEmpty) {
          if (kDebugMode) {
            for (final grp in list) {
              MockDataService.addGroup(grp);
            }
          }
          return list;
        }
      } catch (e) {
        debugPrint('Supabase getGroups error: $e');
      }
    }
    return kDebugMode ? MockDataService.groups : null;
  }

  static Future<bool> insertGroup(GroupModel group) async {
    // 1. Always save in local memory immediately
    MockDataService.addGroup(group);

    final c = client;
    if (c == null) return true;
    try {
      final json = group.toSupabaseJson();
      final orgId = json['organization_id']?.toString() ?? '';
      if (orgId.isEmpty || !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(orgId)) {
        try {
          final orgs = await c.from('organizations').select('id').limit(1);
          if (orgs.isNotEmpty && orgs.first['id'] != null) {
            json['organization_id'] = orgs.first['id'];
          }
        } catch (_) {}
      }
      await c.from('groups').insert(json);
      return true;
    } catch (e) {
      debugPrint('Supabase insertGroup error: $e');
      return true;
    }
  }

  static Future<bool> updateGroup(String id, Map<String, dynamic> data) async {
    MockDataService.updateGroup(id, data);
    final c = client;
    if (c == null) return true;
    try {
      await c.from('groups').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Supabase updateGroup error: $e');
      return true;
    }
  }

  static Future<bool> toggleGroupStatus(String id, String newStatus) async {
    return updateGroup(id, {'status': newStatus});
  }

  static Future<bool> deleteGroup(String id) async {
    MockDataService.deleteGroup(id);
    final c = client;
    if (c == null) return true;
    try {
      await c.from('groups').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Supabase deleteGroup error: $e');
      return true;
    }
  }

  // ===========================================================================
  // 3. PROFILES & USERS
  // ===========================================================================
  static bool _isValidUuid(String? val) {
    if (val == null) return false;
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(val);
  }

  static Future<List<UserModel>?> getUsers() async {
    final c = client;
    if (c == null) return kDebugMode ? MockDataService.users : null;

    final Map<String, UserModel> userMap = {};

    // 1. Fetch from users table
    try {
      final res =
          await c.from('users').select().order('name', ascending: true);
      for (final row in (res as List)) {
        final u = UserModel.fromJson(Map<String, dynamic>.from(row));
        userMap[u.id] = u;
      }
    } catch (e) {
      debugPrint('Supabase getUsers users table query: $e');
    }

    // 2. Fetch from profiles table and merge
    try {
      final res =
          await c.from('profiles').select().order('full_name', ascending: true);
      for (final row in (res as List)) {
        final u = UserModel.fromJson(Map<String, dynamic>.from(row));
        if (!userMap.containsKey(u.id)) {
          userMap[u.id] = u;
        } else {
          final existing = userMap[u.id]!;
          userMap[u.id] = existing.copyWith(
            name: existing.name.isNotEmpty ? existing.name : u.name,
            phone: existing.phone.isNotEmpty ? existing.phone : u.phone,
            email: existing.email.isNotEmpty ? existing.email : u.email,
            address: existing.address ?? u.address,
            accountStatus: u.accountStatus,
          );
        }
      }
    } catch (e) {
      debugPrint('Supabase getUsers profiles query: $e');
    }

    // 3. Fetch from user_roles joined with roles to assign accurate roles
    try {
      final roleRes =
          await c.from('user_roles').select('user_id, roles(code, role_key)');
      for (final row in (roleRes as List)) {
        final uid = row['user_id']?.toString();
        final roleObj = row['roles'];
        final roleCode = (roleObj is Map
                ? (roleObj['code'] ?? roleObj['role_key'])
                : null)
            ?.toString();
        if (uid != null && roleCode != null && userMap.containsKey(uid)) {
          final current = userMap[uid]!;
          final parsed = UserModel.parseRole(roleCode);
          userMap[uid] = current.copyWith(
            role: parsed,
            permissions:
                parsed == UserRole.superAdmin ? ['*'] : current.permissions,
          );
        }
      }
    } catch (e) {
      debugPrint('Supabase getUsers user_roles query: $e');
    }

    // 4. Ensure Super Admin account (9699342811) always has UserRole.superAdmin
    for (final entry in userMap.entries) {
      final clean = entry.value.phone.replaceAll(RegExp(r'\D'), '');
      if (clean.endsWith('9699342811') ||
          entry.value.email.toLowerCase() == 'riteshsangale71@gmail.com') {
        userMap[entry.key] = entry.value.copyWith(
          role: UserRole.superAdmin,
          permissions: ['*'],
        );
      }
    }

    if (userMap.isNotEmpty) {
      return userMap.values.toList();
    }
    return kDebugMode ? MockDataService.users : null;
  }

  static Future<UserModel?> fetchUserProfile(String userId) async {
    final c = client;
    if (c == null) return null;
    try {
      final uRes =
          await c.from('users').select().eq('id', userId).maybeSingle();
      if (uRes != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(uRes));
      }

      final res =
          await c.from('profiles').select().eq('id', userId).maybeSingle();
      if (res != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('Supabase fetchUserProfile error: $e');
    }
    return null;
  }

  static Future<bool> updateProfileStatus(String userId, String status) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('profiles').update({
        'account_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      await c.from('users').update({
        'is_active': status == 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Supabase updateProfileStatus error: $e');
      return false;
    }
  }

  static Future<bool> insertUser(UserModel user, {String? actorId, String? passwordHash}) async {
    MockDataService.addUser(user);
    final c = client;
    if (c == null) return true;

    // Ensure valid UUID for PostgreSQL
    final effectiveUserId = _isValidUuid(user.id) ? user.id : const Uuid().v4();
    final validOrgId = _isValidUuid(user.organizationId) ? user.organizationId : null;
    final rawGrp = user.selectedGroupId ?? (user.groupIds.isNotEmpty ? user.groupIds.first : null);
    final validGrpId = _isValidUuid(rawGrp) ? rawGrp : null;
    final validActorId = _isValidUuid(actorId) ? actorId : null;

    bool success = false;

    // 1. Insert into users table
    try {
      final basePayload = {
        'id': effectiveUserId,
        'name': user.name,
        'email': user.email.isNotEmpty ? user.email : null,
        'phone': user.phone,
        'address': user.address,
        'notes': user.notes,
        'role': user.role.roleKey,
        'organization_id': validOrgId,
        'group_id': validGrpId,
        'is_active': user.isActive,
        'created_by': validActorId,
        if (passwordHash != null) 'password_hash': passwordHash,
      };
      await c.from('users').upsert(basePayload);
      success = true;
    } catch (e) {
      debugPrint('Supabase insert users with password_hash error: $e');
      try {
        final basePayload = {
          'id': effectiveUserId,
          'name': user.name,
          'email': user.email.isNotEmpty ? user.email : null,
          'phone': user.phone,
          'address': user.address,
          'notes': user.notes,
          'role': user.role.roleKey,
          'organization_id': validOrgId,
          'group_id': validGrpId,
          'is_active': user.isActive,
          'created_by': validActorId,
        };
        await c.from('users').upsert(basePayload);
        success = true;
      } catch (err) {
        debugPrint('Supabase insert users fallback error: $err');
      }
    }

    // 2. Also upsert in profiles table
    try {
      await c.from('profiles').upsert({
        'id': effectiveUserId,
        'full_name': user.name,
        'email': user.email.isNotEmpty ? user.email : null,
        'phone': user.phone,
        'address': user.address,
        'notes': user.notes,
        'account_status': user.accountStatus,
        'created_by': validActorId,
        if (passwordHash != null) 'password_hash': passwordHash,
        'created_at': user.createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      success = true;
    } catch (e) {
      try {
        await c.from('profiles').upsert({
          'id': effectiveUserId,
          'full_name': user.name,
          'email': user.email.isNotEmpty ? user.email : null,
          'phone': user.phone,
          'address': user.address,
          'notes': user.notes,
          'account_status': user.accountStatus,
          'created_by': validActorId,
          'created_at': user.createdAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        success = true;
      } catch (err) {
        debugPrint('Supabase insert profiles table error: $err');
      }
    }

    // 3. User roles assignment
    try {
      final rolesRes = await c
          .from('roles')
          .select('id')
          .eq('role_key', user.role.roleKey)
          .maybeSingle();
      final roleId = rolesRes?['id'];
      if (roleId != null && _isValidUuid(roleId)) {
        await c.from('user_roles').insert({
          'user_id': effectiveUserId,
          'role_id': roleId,
          'organization_id': validOrgId,
          'group_id': validGrpId,
          'assigned_by': validActorId,
        });
      }
    } catch (err) {
      debugPrint('Supabase insert user_roles error: $err');
    }

    if (validGrpId != null) {
      try {
        await c.from('group_members').upsert({
          'group_id': validGrpId,
          'user_id': effectiveUserId,
          'membership_status': 'active',
        });
      } catch (err) {
        debugPrint('Supabase insert group_members error: $err');
      }
    }

    await insertAuditLog(
      action: 'CREATE_USER',
      resourceType: 'User',
      resourceId: effectiveUserId,
      organizationId: validOrgId,
      metadata: {
        'name': user.name,
        'phone': user.phone,
        'role': user.role.roleKey,
        'actor_id': actorId,
      },
    );

    return success;
  }

  static Future<bool> updateUser(UserModel user, {String? actorId, String? passwordHash}) async {
    MockDataService.addUser(user);
    final c = client;
    if (c == null) return true;

    final validOrgId = _isValidUuid(user.organizationId) ? user.organizationId : null;
    final rawGrp = user.selectedGroupId ?? (user.groupIds.isNotEmpty ? user.groupIds.first : null);
    final validGrpId = _isValidUuid(rawGrp) ? rawGrp : null;

    bool success = false;

    try {
      await c.from('users').update({
        'name': user.name,
        'email': user.email.isNotEmpty ? user.email : null,
        'phone': user.phone,
        'address': user.address,
        'notes': user.notes,
        'role': user.role.roleKey,
        'organization_id': validOrgId,
        'group_id': validGrpId,
        'is_active': user.isActive,
        if (passwordHash != null) 'password_hash': passwordHash,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      success = true;
    } catch (e) {
      try {
        await c.from('users').update({
          'name': user.name,
          'email': user.email.isNotEmpty ? user.email : null,
          'phone': user.phone,
          'address': user.address,
          'notes': user.notes,
          'role': user.role.roleKey,
          'organization_id': validOrgId,
          'group_id': validGrpId,
          'is_active': user.isActive,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
        success = true;
      } catch (err) {
        debugPrint('Supabase update users error: $err');
      }
    }

    try {
      await c.from('profiles').update({
        'full_name': user.name,
        'email': user.email,
        'phone': user.phone,
        'address': user.address,
        'notes': user.notes,
        'account_status': user.accountStatus,
        if (passwordHash != null) 'password_hash': passwordHash,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Check role assignment update
      final rolesRes = await c
          .from('roles')
          .select('id')
          .eq('role_key', user.role.roleKey)
          .maybeSingle();
      final roleId = rolesRes?['id'];
      if (roleId != null) {
        await c.from('user_roles').delete().eq('user_id', user.id);
        await c.from('user_roles').insert({
          'user_id': user.id,
          'role_id': roleId,
          'organization_id': user.organizationId,
          'group_id': user.selectedGroupId ??
              (user.groupIds.isNotEmpty ? user.groupIds.first : null),
          'assigned_by': actorId,
        });
      }

      await insertAuditLog(
        action: 'UPDATE_USER',
        resourceType: 'User',
        resourceId: user.id,
        organizationId: user.organizationId,
        metadata: {
          'name': user.name,
          'phone': user.phone,
          'role': user.role.roleKey,
          'actor_id': actorId,
        },
      );
    } catch (e) {
      debugPrint('Supabase update profile error: $e');
    }

    try {
      final baseUpdate = {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'address': user.address,
        'notes': user.notes,
        'role': user.role.roleKey,
        'organization_id': user.organizationId,
        'group_id': user.selectedGroupId ??
            (user.groupIds.isNotEmpty ? user.groupIds.first : null),
        'is_active': user.isActive,
      };
      try {
        await c.from('users').update(baseUpdate).eq('id', user.id);
      } catch (e) {
        debugPrint('Supabase update users fallback error: $e');
      }
    } catch (e) {
      debugPrint('Supabase update users outer error: $e');
    }

    return true;
  }

  static Future<bool> hasFinancialTransactions(String userId) async {
    // Check locally in mock data
    final hasLocal = MockDataService.hasFinancialTransactions(userId);
    if (hasLocal) return true;

    final c = client;
    if (c == null) return hasLocal;

    try {
      final receipts = await c
          .from('receipts')
          .select('id')
          .eq('collector_id', userId)
          .limit(1);
      if ((receipts as List).isNotEmpty) return true;

      final collections = await c
          .from('collections')
          .select('id')
          .eq('collector_id', userId)
          .limit(1);
      if ((collections as List).isNotEmpty) return true;

      final handovers = await c
          .from('cash_handovers')
          .select('id')
          .or('handover_from_id.eq.$userId,handover_to_id.eq.$userId')
          .limit(1);
      if ((handovers as List).isNotEmpty) return true;
    } catch (e) {
      debugPrint('hasFinancialTransactions error: $e');
    }
    return false;
  }

  static Future<bool> toggleUserStatus(String userId, String newStatus) async {
    return updateProfileStatus(userId, newStatus);
  }

  static Future<bool> deleteUser(String userId) async {
    MockDataService.deleteUser(userId);
    final c = client;
    if (c == null) return true;
    try {
      await c.from('profiles').delete().eq('id', userId);
    } catch (e) {
      debugPrint('Supabase delete profile error: $e');
    }
    try {
      await c.from('users').delete().eq('id', userId);
    } catch (e) {
      debugPrint('Supabase delete users error: $e');
    }
    return true;
  }

  // ===========================================================================
  // 4. ROLES & PERMISSIONS
  // ===========================================================================
  static Future<List<RoleModel>?> getRoles({String? organizationId}) async {
    final c = client;
    if (c == null) return kDebugMode ? MockDataService.roles : null;
    try {
      final res = await c
          .from('roles')
          .select('*, role_permissions(permissions(permission_key))')
          .order('name', ascending: true);

      final list = (res as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        List<String> perms = [];
        if (map['role_permissions'] is List) {
          for (final rp in (map['role_permissions'] as List)) {
            if (rp is Map && rp['permissions'] is Map) {
              final key =
                  (rp['permissions'] as Map)['permission_key']?.toString();
              if (key != null) perms.add(key);
            }
          }
        }
        map['permissions'] = perms;
        return RoleModel.fromJson(map);
      }).toList();
      return list.isNotEmpty
          ? list
          : (kDebugMode ? MockDataService.roles : null);
    } catch (e) {
      debugPrint('Supabase getRoles error: $e');
      return kDebugMode ? MockDataService.roles : null;
    }
  }

  static Future<List<PermissionModel>?> getPermissions() async {
    final c = client;
    if (c == null) return kDebugMode ? MockDataService.permissions : null;
    try {
      final res =
          await c.from('permissions').select().order('module', ascending: true);
      final list = (res as List)
          .map(
              (row) => PermissionModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list.isNotEmpty
          ? list
          : (kDebugMode ? MockDataService.permissions : null);
    } catch (e) {
      debugPrint('Supabase getPermissions error: $e');
      return kDebugMode ? MockDataService.permissions : null;
    }
  }

  static Future<bool> insertRole(RoleModel role, {String? actorId}) async {
    MockDataService.addRole(role);
    final c = client;
    if (c == null) return true;
    try {
      final json = role.toJson();
      json.remove('permissions');
      json.remove('user_count');
      if (!RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(role.id)) {
        json.remove('id');
      }
      final inserted = await c.from('roles').insert(json).select().single();
      final newRoleId = inserted['id']?.toString() ?? role.id;

      if (role.permissions.isNotEmpty) {
        await updateRolePermissions(newRoleId, role.permissions);
      }

      await insertAuditLog(
        action: 'CREATE_ROLE',
        resourceType: 'Role',
        resourceId: newRoleId,
        organizationId: role.organizationId,
        metadata: {
          'name': role.name,
          'code': role.code,
          'scope': role.scopeType,
          'permissions_count': role.permissions.length,
          'actor_id': actorId,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Supabase insertRole error: $e');
      return true;
    }
  }

  static Future<bool> updateRole(RoleModel role, {String? actorId}) async {
    MockDataService.addRole(role);
    final c = client;
    if (c == null) return true;
    try {
      await c.from('roles').update({
        'name': role.name,
        'description': role.description,
        'scope_type': role.scopeType,
        'is_active': role.isActive,
        'organization_id': role.organizationId,
        'group_id': role.groupId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', role.id);

      await updateRolePermissions(role.id, role.permissions);

      await insertAuditLog(
        action: 'UPDATE_ROLE',
        resourceType: 'Role',
        resourceId: role.id,
        organizationId: role.organizationId,
        metadata: {
          'name': role.name,
          'is_active': role.isActive,
          'permissions_count': role.permissions.length,
          'actor_id': actorId,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Supabase updateRole error: $e');
      return true;
    }
  }

  static Future<bool> toggleRoleActive(String roleId, bool isActive,
      {String? actorId}) async {
    MockDataService.toggleRoleActive(roleId, isActive);
    final c = client;
    if (c == null) return true;
    try {
      await c.from('roles').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', roleId);

      await insertAuditLog(
        action: isActive ? 'ACTIVATE_ROLE' : 'DEACTIVATE_ROLE',
        resourceType: 'Role',
        resourceId: roleId,
        metadata: {'is_active': isActive, 'actor_id': actorId},
      );
      return true;
    } catch (e) {
      debugPrint('Supabase toggleRoleActive error: $e');
      return true;
    }
  }

  static Future<bool> updateRolePermissions(
      String roleId, List<String> permissionKeys) async {
    final c = client;
    if (c == null) return false;
    try {
      // 1. Delete existing
      await c.from('role_permissions').delete().eq('role_id', roleId);

      // 2. Resolve permission IDs
      final perms = await c
          .from('permissions')
          .select('id, permission_key')
          .filter('permission_key', 'in', permissionKeys);
      final List<Map<String, dynamic>> records = [];
      for (final p in (perms as List)) {
        records.add({
          'role_id': roleId,
          'permission_id': p['id'],
        });
      }
      if (records.isNotEmpty) {
        await c.from('role_permissions').insert(records);
      }
      return true;
    } catch (e) {
      debugPrint('Supabase updateRolePermissions error: $e');
      return false;
    }
  }

  static Future<bool> deleteRole(String roleId, {String? actorId}) async {
    final deleted = MockDataService.deleteRole(roleId);
    if (!deleted) return false; // Prevented because in use or system role

    final c = client;
    if (c == null) return true;
    try {
      // Check in database if role has active assignments
      final assigned = await c
          .from('user_roles')
          .select('id')
          .eq('role_id', roleId)
          .limit(1);
      if ((assigned as List).isNotEmpty) {
        return false; // Cannot delete role with active assignments
      }

      await c.from('role_permissions').delete().eq('role_id', roleId);
      await c.from('roles').delete().eq('id', roleId);

      await insertAuditLog(
        action: 'DELETE_ROLE',
        resourceType: 'Role',
        resourceId: roleId,
        metadata: {'actor_id': actorId},
      );
    } catch (e) {
      debugPrint('Supabase deleteRole error: $e');
    }
    return true;
  }

  // ===========================================================================
  // 5. USER ROLES & SCOPES
  // ===========================================================================
  static Future<List<UserRoleAssignmentModel>?> getAllUserRoleAssignments({
    String? organizationId,
    String? groupId,
    String? userId,
  }) async {
    final c = client;
    if (c == null) return MockDataService.userRoleAssignments;
    try {
      var query = c.from('user_roles').select('''
        id, user_id, role_id, organization_id, group_id, assigned_by, created_at,
        profiles!user_id(full_name, phone, email),
        roles!role_id(name, role_key),
        organizations!organization_id(name),
        groups!group_id(name)
      ''');

      if (organizationId != null && organizationId.isNotEmpty) {
        query = query.eq('organization_id', organizationId);
      }
      if (groupId != null && groupId.isNotEmpty) {
        query = query.eq('group_id', groupId);
      }
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      final res = await query.order('created_at', ascending: false);
      final list = (res as List)
          .map((row) =>
              UserRoleAssignmentModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list.isNotEmpty ? list : MockDataService.userRoleAssignments;
    } catch (e) {
      debugPrint('Supabase getAllUserRoleAssignments error: $e');
      return MockDataService.userRoleAssignments;
    }
  }

  static Future<bool> assignUserRole({
    required String userId,
    required String roleId,
    String? organizationId,
    String? groupId,
    String? assignedBy,
  }) async {
    MockDataService.assignUserRole(
      userId: userId,
      roleId: roleId,
      organizationId: organizationId,
      groupId: groupId,
      assignedBy: assignedBy,
    );

    final c = client;
    if (c == null) return true;
    try {
      await c.from('user_roles').insert({
        'user_id': userId,
        'role_id': roleId,
        'organization_id': organizationId,
        'group_id': groupId,
        'assigned_by': assignedBy,
      });

      await insertAuditLog(
        action: 'ASSIGN_USER_ROLE',
        resourceType: 'UserRole',
        resourceId: roleId,
        organizationId: organizationId,
        groupId: groupId,
        metadata: {
          'target_user_id': userId,
          'role_id': roleId,
          'assigned_by': assignedBy,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Supabase assignUserRole error: $e');
      return true;
    }
  }

  static Future<bool> revokeUserRole(String userRoleId,
      {String? actorId}) async {
    MockDataService.revokeUserRole(userRoleId);
    final c = client;
    if (c == null) return true;
    try {
      await c.from('user_roles').delete().eq('id', userRoleId);

      await insertAuditLog(
        action: 'REVOKE_USER_ROLE',
        resourceType: 'UserRole',
        resourceId: userRoleId,
        metadata: {'actor_id': actorId},
      );
      return true;
    } catch (e) {
      debugPrint('Supabase revokeUserRole error: $e');
      return true;
    }
  }

  // ===========================================================================
  // 6. JOIN REQUESTS
  // ===========================================================================
  static Future<List<JoinRequestModel>?> getJoinRequests(
      {String? groupId, String? userId}) async {
    final c = client;
    if (c == null) return null;
    try {
      var query = c.from('join_requests').select('''
        id, group_id, user_id, request_status, message, reviewed_by, reviewed_at, created_at,
        groups(name, code, organization_id, organizations(name)),
        profiles(full_name, phone, email)
      ''');

      if (groupId != null && groupId.isNotEmpty) {
        query = query.eq('group_id', groupId);
      }
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      final res = await query.order('created_at', ascending: false);
      final list = (res as List)
          .map((row) =>
              JoinRequestModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list;
    } catch (e) {
      debugPrint('Supabase getJoinRequests error: $e');
      return null;
    }
  }

  static Future<bool> submitJoinRequest({
    required String groupId,
    required String userId,
    String message = '',
  }) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('join_requests').insert({
        'group_id': groupId,
        'user_id': userId,
        'request_status': 'pending',
        'message': message,
      });
      return true;
    } catch (e) {
      debugPrint('Supabase submitJoinRequest error: $e');
      return false;
    }
  }

  static Future<bool> reviewJoinRequest({
    required String requestId,
    required String status, // 'approved', 'rejected'
    required String reviewedByUserId,
  }) async {
    final c = client;
    if (c == null) return false;
    try {
      // 1. Update request status
      final updated = await c
          .from('join_requests')
          .update({
            'request_status': status,
            'reviewed_by': reviewedByUserId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .select('group_id, user_id')
          .single();

      // 2. If approved, add to group_members and user_roles
      if (status == 'approved') {
        final grpId = updated['group_id'];
        final uId = updated['user_id'];
        if (grpId != null && uId != null) {
          await c.from('group_members').insert({
            'group_id': grpId,
            'user_id': uId,
            'membership_status': 'active',
            'approved_by': reviewedByUserId,
            'approved_at': DateTime.now().toIso8601String(),
          });
        }
      }
      return true;
    } catch (e) {
      debugPrint('Supabase reviewJoinRequest error: $e');
      return false;
    }
  }

  // ===========================================================================
  // 7. AUDIT LOGS
  // ===========================================================================
  static Future<List<AuditLogModel>?> getAuditLogs(
      {String? organizationId, String? groupId}) async {
    final c = client;
    if (c == null)
      return kDebugMode
          ? MockDataService.getInitialAuditLogs()
          : <AuditLogModel>[];
    try {
      var query = c.from('audit_logs').select(
          'id, actor_user_id, action, resource_type, resource_id, organization_id, group_id, safe_metadata, created_at');

      if (organizationId != null && organizationId.isNotEmpty) {
        query = query.eq('organization_id', organizationId);
      }
      if (groupId != null && groupId.isNotEmpty) {
        query = query.eq('group_id', groupId);
      }

      final res = await query.order('created_at', ascending: false).limit(100);
      final list = (res as List).map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return AuditLogModel(
          id: map['id']?.toString() ?? '',
          organizationId: map['organization_id']?.toString() ?? 'org_001',
          entityType: map['resource_type']?.toString() ?? 'System',
          entityId: map['resource_id']?.toString() ?? '',
          action: map['action']?.toString() ?? '',
          performedById: map['actor_user_id']?.toString() ?? '',
          performedByName: 'Admin',
          timestamp: map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
          details: map['safe_metadata']?.toString() ?? '',
        );
      }).toList();
      return list.isNotEmpty
          ? list
          : (kDebugMode
              ? MockDataService.getInitialAuditLogs()
              : <AuditLogModel>[]);
    } catch (e) {
      debugPrint('Supabase getAuditLogs error: $e');
      return kDebugMode ? MockDataService.getInitialAuditLogs() : null;
    }
  }

  static Future<bool> insertAuditLog({
    required String action,
    required String resourceType,
    String? resourceId,
    String? organizationId,
    String? groupId,
    Map<String, dynamic>? metadata,
  }) async {
    final c = client;
    if (c == null) return false;
    try {
      final uid = c.auth.currentUser?.id;
      await c.from('audit_logs').insert({
        'actor_user_id': uid,
        'action': action,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'organization_id': organizationId,
        'group_id': groupId,
        'safe_metadata': metadata ?? {},
      });
      return true;
    } catch (e) {
      debugPrint('Supabase insertAuditLog error: $e');
      return false;
    }
  }

  // ===========================================================================
  // 8. SUPER ADMIN BOOTSTRAP CHECK & EXECUTION
  // ===========================================================================
  static Future<bool> isSuperAdminInitialized() async {
    final c = client;
    if (c == null) return true; // Default safe assume initialized if no client
    try {
      final res = await c.rpc('check_super_admin_initialized');
      return res == true;
    } catch (e) {
      debugPrint('Supabase check_super_admin_initialized RPC error: $e');
      // Direct query fallback
      try {
        final roles = await c
            .from('user_roles')
            .select('id, roles!inner(role_key)')
            .eq('roles.role_key', 'SUPER_ADMIN')
            .limit(1);
        return (roles as List).isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  static Future<Map<String, dynamic>> bootstrapFirstSuperAdmin({
    required String email,
    required String phone,
    required String fullName,
  }) async {
    final c = client;
    if (c == null) {
      return {'success': false, 'message': 'Supabase client not initialized.'};
    }
    try {
      final res = await c.rpc('bootstrap_first_super_admin', params: {
        'p_email': email.trim().toLowerCase(),
        'p_phone': phone.trim(),
        'p_full_name': fullName.trim(),
      });
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
      return {
        'success': true,
        'message': 'Super Admin bootstrapped successfully.'
      };
    } catch (e) {
      debugPrint('Supabase bootstrapFirstSuperAdmin error: $e');
      return {'success': false, 'message': 'Bootstrap error: $e'};
    }
  }

  // ===========================================================================
  // 9. FINANCIAL RECORDS & OPERATIONS
  // ===========================================================================
  static Future<List<CampaignModel>?> getCampaigns() async {
    final c = client;
    if (c == null) return <CampaignModel>[];
    try {
      final res = await c.from('campaigns').select();
      final list = (res as List)
          .map((row) => CampaignModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list;
    } catch (e) {
      debugPrint('Supabase getCampaigns error: $e');
      return <CampaignModel>[];
    }
  }

  static Future<List<HouseholdModel>?> getHouseholds(String campaignId) async {
    final c = client;
    if (c == null) return <HouseholdModel>[];
    try {
      final res =
          await c.from('households').select().eq('campaign_id', campaignId);
      final list = (res as List)
          .map((row) => HouseholdModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list;
    } catch (e) {
      debugPrint('Supabase getHouseholds error: $e');
      return <HouseholdModel>[];
    }
  }

  static Future<bool> insertHousehold(HouseholdModel household) async {
    final c = client;
    if (c == null) return false;
    try {
      final json = household.toJson();
      if (!RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(household.id)) {
        json.remove('id');
      }
      await c.from('households').insert(json);
      return true;
    } catch (e) {
      debugPrint('Supabase insertHousehold error: $e');
      return false;
    }
  }

  static Future<bool> updateHousehold(
      String id, Map<String, dynamic> data) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('households').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Supabase updateHousehold error: $e');
      return false;
    }
  }

  static Future<bool> deleteHousehold(String id) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('households').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Supabase deleteHousehold error: $e');
      return false;
    }
  }

  static Future<List<PaymentModel>?> getCollections(String campaignId) async {
    final c = client;
    if (c == null) return <PaymentModel>[];
    try {
      dynamic res;
      try {
        res =
            await c.from('collections').select().eq('campaign_id', campaignId);
      } catch (_) {
        try {
          res = await c.from('collections').select().eq('group_id', campaignId);
        } catch (_) {
          res = await c.from('collections').select().limit(50);
        }
      }
      final list = (res as List)
          .map((row) => PaymentModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list;
    } catch (e) {
      debugPrint('Supabase getCollections error: $e');
      return <PaymentModel>[];
    }
  }

  static Future<bool> insertPayment(PaymentModel payment) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('collections').insert(payment.toJson());
      return true;
    } catch (e) {
      debugPrint('Supabase insertPayment error: $e');
      return false;
    }
  }

  static Future<List<ReceiptModel>?> getReceipts(String campaignId) async {
    final c = client;
    if (c == null) return <ReceiptModel>[];
    try {
      dynamic res;
      try {
        res = await c.from('receipts').select().eq('campaign_id', campaignId);
      } catch (_) {
        res = await c.from('receipts').select().limit(50);
      }
      final list = (res as List)
          .map((row) => ReceiptModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list;
    } catch (e) {
      debugPrint('Supabase getReceipts error: $e');
      return <ReceiptModel>[];
    }
  }

  static Future<bool> insertReceipt(ReceiptModel receipt) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('receipts').insert(receipt.toJson());
      return true;
    } catch (e) {
      debugPrint('Supabase insertReceipt error: $e');
      return false;
    }
  }

  static Future<bool> cancelReceipt(
      String id, String reason, String cancelledByName) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('receipts').update({
        'is_cancelled': true,
        'cancellation_reason': reason,
        'cancelled_by_name': cancelledByName,
        'cancelled_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Supabase cancelReceipt error: $e');
      return false;
    }
  }

  static Future<List<ExpenseModel>?> getExpenses(String campaignId) async {
    final c = client;
    if (c == null) return <ExpenseModel>[];
    try {
      dynamic res;
      try {
        res = await c.from('expenses').select().eq('campaign_id', campaignId);
      } catch (_) {
        try {
          res = await c.from('expenses').select().eq('group_id', campaignId);
        } catch (_) {
          res = await c.from('expenses').select().limit(50);
        }
      }
      final list = (res as List)
          .map((row) => ExpenseModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list;
    } catch (e) {
      debugPrint('Supabase getExpenses error: $e');
      return <ExpenseModel>[];
    }
  }

  static Future<bool> insertExpense(ExpenseModel expense) async {
    final c = client;
    if (c == null) return false;
    try {
      final json = expense.toJson();
      if (!RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(expense.id)) {
        json.remove('id');
      }
      await c.from('expenses').insert(json);
      return true;
    } catch (e) {
      debugPrint('Supabase insertExpense error: $e');
      return false;
    }
  }

  static Future<bool> updateExpense(
      String id, Map<String, dynamic> data) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('expenses').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Supabase updateExpense error: $e');
      return false;
    }
  }

  static Future<bool> deleteExpense(String id) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('expenses').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Supabase deleteExpense error: $e');
      return false;
    }
  }

  static Future<List<ComplaintModel>?> getComplaints(String campaignId) async {
    final c = client;
    if (c == null)
      return kDebugMode
          ? MockDataService.getInitialComplaints()
          : <ComplaintModel>[];
    try {
      dynamic res;
      try {
        res = await c.from('complaints').select().eq('campaign_id', campaignId);
      } catch (_) {
        res = await c.from('complaints').select().limit(50);
      }
      final list = (res as List)
          .map((row) => ComplaintModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return list;
    } catch (e) {
      debugPrint('Supabase getComplaints error: $e');
      return kDebugMode ? MockDataService.getInitialComplaints() : null;
    }
  }

  static Future<bool> insertComplaint(ComplaintModel complaint) async {
    final c = client;
    if (c == null) return false;
    try {
      await c.from('complaints').insert(complaint.toJson());
      return true;
    } catch (e) {
      debugPrint('Supabase insertComplaint error: $e');
      return false;
    }
  }
}
