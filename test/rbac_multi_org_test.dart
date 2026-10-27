import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vargani_app/core/models/organization_model.dart';
import 'package:vargani_app/core/models/group_model.dart';
import 'package:vargani_app/core/models/user_model.dart';
import 'package:vargani_app/core/models/role_model.dart';
import 'package:vargani_app/core/models/join_request_model.dart';
import 'package:vargani_app/core/models/user_role_assignment_model.dart';
import 'package:vargani_app/core/services/supabase_service.dart';
import 'package:vargani_app/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Multi-Organization Hierarchy & Models Tests', () {
    test('OrganizationModel JSON roundtrip with slug and status', () {
      final org = OrganizationModel(
        id: 'org_test_01',
        name: 'Ganesh Festival Federation',
        slug: 'ganesh-festival-federation',
        description: 'Apex federation of Pune festival mandals',
        registrationNumber: 'MAH/PUN/2026',
        contactPerson: 'Ramesh Patil',
        phone: '9822011223',
        district: 'Pune',
        registrationDate: DateTime(2020, 1, 1),
        status: 'active',
      );

      final json = org.toJson();
      expect(json['slug'], 'ganesh-festival-federation');
      expect(json['status'], 'active');
      expect(org.isActive, isTrue);
      expect(org.isArchived, isFalse);

      final parsed = OrganizationModel.fromJson(json);
      expect(parsed.name, org.name);
      expect(parsed.slug, org.slug);
      expect(parsed.district, 'Pune');
    });

    test('GroupModel belongs to Organization and manages contribution settings',
        () {
      const group = GroupModel(
        id: 'grp_test_01',
        organizationId: 'org_test_01',
        name: 'Shivaji Chowk Mandal Group',
        code: 'GRP-SCM-01',
        description: 'Ward 14 youth committee',
        location: 'Shivaji Nagar, Pune',
        status: 'active',
        contributionSettings: {
          'per_person_rate': 150.0,
          'suggested_amount': 500.0,
          'allow_partial': true,
        },
      );

      expect(group.organizationId, 'org_test_01');
      expect(group.perPersonRate, 150.0);
      expect(group.suggestedAmount, 500.0);
      expect(group.allowPartial, isTrue);
      expect(group.isActive, isTrue);

      final json = group.toJson();
      final parsed = GroupModel.fromJson(json);
      expect(parsed.code, 'GRP-SCM-01');
      expect(parsed.location, 'Shivaji Nagar, Pune');
    });

    test('JoinRequestModel lifecycle: pending, approved, rejected', () {
      final req = JoinRequestModel(
        id: 'req_001',
        groupId: 'grp_001',
        groupName: 'Shivaji Chowk Mandal',
        groupCode: 'GRP-01',
        organizationId: 'org_001',
        organizationName: 'Pune Mandal Federation',
        userId: 'usr_citizen_01',
        userName: 'Suresh More',
        userPhone: '9822000001',
        userEmail: 'suresh@example.com',
        requestStatus: 'pending',
        message:
            'I am a local resident wanting to participate in Vargani collection',
        createdAt: DateTime.now(),
      );

      expect(req.isPending, isTrue);
      expect(req.isApproved, isFalse);
      expect(req.isRejected, isFalse);

      final approved = req.copyWith(
        requestStatus: 'approved',
        reviewedBy: 'usr_admin',
        reviewedAt: DateTime.now(),
      );
      expect(approved.isApproved, isTrue);
      expect(approved.isPending, isFalse);
    });

    test('UserRoleAssignmentModel captures scope correctly', () {
      final sysAssign = UserRoleAssignmentModel(
        id: 'ura_01',
        userId: 'u_1',
        userName: 'Admin One',
        roleId: 'r_super',
        roleKey: 'SUPER_ADMIN',
        roleName: 'Super Admin',
        createdAt: DateTime.now(),
      );
      expect(sysAssign.scopeDescription, 'System Wide');

      final orgAssign = UserRoleAssignmentModel(
        id: 'ura_02',
        userId: 'u_2',
        userName: 'Org Admin One',
        roleId: 'r_org',
        roleKey: 'ORG_ADMIN',
        roleName: 'Organization Admin',
        organizationId: 'org_01',
        organizationName: 'Pune Central Federation',
        createdAt: DateTime.now(),
      );
      expect(
          orgAssign.scopeDescription, 'Organization: Pune Central Federation');

      final grpAssign = UserRoleAssignmentModel(
        id: 'ura_03',
        userId: 'u_3',
        userName: 'Collector One',
        roleId: 'r_col',
        roleKey: 'COLLECTOR',
        roleName: 'Collection Agent',
        organizationId: 'org_01',
        groupId: 'grp_01',
        groupName: 'Main Bazaar Ward',
        createdAt: DateTime.now(),
      );
      expect(grpAssign.scopeDescription, 'Group: Main Bazaar Ward');
    });
  });

  group('Dynamic Role & Permission Enforcement', () {
    test('RoleModel distinguishes system roles vs custom roles and scope types',
        () {
      const superRole = RoleModel(
        id: 'r_super',
        code: 'SUPER_ADMIN',
        roleKey: 'SUPER_ADMIN',
        name: 'Super Administrator',
        scopeType: 'system',
        isSystemRole: true,
      );
      expect(superRole.isSuperAdmin, isTrue);
      expect(superRole.isSystemRole, isTrue);
      expect(superRole.scopeType, 'system');

      const customRole = RoleModel(
        id: 'r_treasurer',
        code: 'TREASURER',
        roleKey: 'TREASURER',
        name: 'Assistant Treasurer',
        scopeType: 'group',
        isSystemRole: false,
        permissions: ['collection.view', 'expense.view'],
      );
      expect(customRole.isSuperAdmin, isFalse);
      expect(customRole.isSystemRole, isFalse);
      expect(customRole.scopeType, 'group');
      expect(customRole.permissions.length, 2);
    });

    test('Suspended or Inactive accounts have zero permissions and are blocked',
        () {
      const activeUser = UserModel(
        id: 'u_active',
        name: 'Active Collector',
        phone: '9822000002',
        email: 'collector@example.com',
        organizationId: 'org_001',
        role: UserRole.collector,
        accountStatus: 'active',
        permissions: ['collection.create'],
      );
      expect(activeUser.isInactive, isFalse);
      expect(activeUser.isSuspended, isFalse);
      expect(activeUser.hasPermission('collection.create'), isTrue);

      const suspendedUser = UserModel(
        id: 'u_suspended',
        name: 'Suspended Agent',
        phone: '9822000003',
        email: 'suspended@example.com',
        organizationId: 'org_001',
        role: UserRole.collector,
        accountStatus: 'suspended',
        permissions: ['collection.create'],
      );
      expect(suspendedUser.isSuspended, isTrue);
      expect(suspendedUser.hasPermission('collection.create'), isFalse);

      const inactiveUser = UserModel(
        id: 'u_inactive',
        name: 'Inactive Agent',
        phone: '9822000004',
        email: 'inactive@example.com',
        organizationId: 'org_001',
        role: UserRole.collector,
        accountStatus: 'inactive',
        permissions: ['collection.create'],
      );
      expect(inactiveUser.isInactive, isTrue);
      expect(inactiveUser.hasPermission('collection.create'), isFalse);
    });

    test('AuthProvider role getters work accurately across roles', () {
      final auth = AuthProvider();

      // Switch / continue as citizen / public user
      auth.continueAsGuest();
      expect(auth.isSuperAdmin, isFalse);
      expect(auth.isCitizen, isTrue);
      expect(auth.isPublicUser, isTrue);

      // Switch to super admin
      const superUser = UserModel(
        id: 'usr_super',
        name: 'Super Admin',
        phone: '9888811111',
        email: 'super@varganipro.in',
        organizationId: 'platform',
        role: UserRole.superAdmin,
      );
      auth.switchUser(superUser);
      expect(auth.isSuperAdmin, isTrue);
      expect(auth.isCitizen, isFalse);
    });

    test(
        'Primary Super Admin (9699342811) login with Ritesh@123 is permanent and immutable',
        () async {
      final auth = AuthProvider();

      // 1. Wrong password fails
      final wrongRes =
          await auth.loginWithPassword('9699342811', 'wrongPassword123');
      expect(wrongRes.success, isFalse);

      // 2. Correct password Ritesh@123 logs in directly as Super Admin
      final loginRes = await auth.loginWithPassword('9699342811', 'Ritesh@123');
      expect(loginRes.success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isSuperAdmin, isTrue);
      expect(auth.currentUser.phone, '9699342811');
      expect(auth.canManageOrganizations, isTrue);
      expect(auth.canManageRoles, isTrue);
      expect(auth.canManageUsers, isTrue);

      // 3. Immutability: Attempting to reset 9699342811 password must be blocked
      final resetRes = auth.resetPassword(
        phone: '9699342811',
        otp: '992224',
        newPassword: 'HackedPassword@123',
      );
      expect(resetRes, isFalse); // Cannot be changed by anyone
    });

    test('Creating and saving an organization updates master data immediately',
        () async {
      final newOrg = OrganizationModel(
        id: 'org_test_123',
        name: 'New Test Mandal Pune',
        slug: 'new-test-mandal-pune',
        description: 'Community mandal for annual festival',
        district: 'Pune',
        registrationDate: DateTime.now(),
        status: 'active',
      );

      final ok = await SupabaseService.insertOrganization(newOrg);
      expect(ok, isTrue);

      final allOrgs = await SupabaseService.getOrganizations();
      expect(allOrgs, isNotNull);
      expect(allOrgs!.any((o) => o.slug == 'new-test-mandal-pune'), isTrue);

      const newGrp = GroupModel(
        id: 'grp_test_456',
        organizationId: 'org_test_123',
        name: 'Shivaji Chowk Unit',
        code: 'SC-UNIT',
        description: 'Main chowk collection unit',
        location: 'Pune',
        status: 'active',
        contributionSettings: {'suggested_amount': 250},
      );

      final grpOk = await SupabaseService.insertGroup(newGrp);
      expect(grpOk, isTrue);

      final allGrps = await SupabaseService.getGroups();
      expect(allGrps, isNotNull);
      expect(allGrps!.any((g) => g.code == 'SC-UNIT'), isTrue);
    });
  });
}
