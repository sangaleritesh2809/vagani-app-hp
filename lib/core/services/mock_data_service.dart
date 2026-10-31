import '../models/user_model.dart';
import '../models/organization_model.dart';
import '../models/campaign_model.dart';
import '../models/household_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';
import '../models/cash_handover_model.dart';
import '../models/expense_model.dart';
import '../models/complaint_model.dart';
import '../models/audit_log_model.dart';
import '../models/group_model.dart';
import '../models/role_model.dart';
import '../models/user_role_assignment_model.dart';
import '../constants/rbac_modules.dart';

class MockDataService {
  static final OrganizationModel organization = OrganizationModel(
    id: 'org_001',
    name: 'Shree Shiv Chhatrapati Mitra Mandal',
    registrationNumber: 'MH/2018/PUN/00918',
    contactPerson: 'Sachin Kadam (President)',
    phone: '+91 98220 54321',
    address: 'Near Old Maruti Mandir, Main Chowk',
    village: 'Sangvi',
    taluka: 'Haveli',
    district: 'Pune',
    state: 'Maharashtra',
    registrationDate: DateTime(2018, 5, 12),
    status: 'Active',
  );

  static final List<OrganizationModel> organizations = [
    organization,
  ];

  static void addOrganization(OrganizationModel org) {
    final idx = organizations.indexWhere(
        (o) => o.id == org.id || (o.slug.isNotEmpty && o.slug == org.slug));
    if (idx != -1) {
      organizations[idx] = org;
    } else {
      organizations.insert(0, org);
    }
  }

  static final List<GroupModel> groups = [
    const GroupModel(
      id: 'grp_001',
      organizationId: 'org_001',
      name: 'Shivaji Chowk Mandal Group',
      code: 'GRP-SC-01',
      description: 'Main Pandal & Shivaji Chowk collection jurisdiction',
      location: 'Pune Central',
      status: 'active',
      contributionSettings: {
        'suggested_amount': 500,
        'allow_partial': true,
        'per_person_rate': 200,
      },
    ),
    const GroupModel(
      id: 'grp_002',
      organizationId: 'org_001',
      name: 'Maruti Mandir Parisar Group',
      code: 'GRP-MM-02',
      description: 'Maruti Mandir and Gaothan inner lanes',
      location: 'Pune South',
      status: 'active',
      contributionSettings: {
        'suggested_amount': 500,
        'allow_partial': true,
        'per_person_rate': 200,
      },
    ),
    const GroupModel(
      id: 'grp_003',
      organizationId: 'org_001',
      name: 'Station Road Committee',
      code: 'GRP-SR-03',
      description: 'Station Road and Market line shopkeepers',
      location: 'Pune East',
      status: 'active',
      contributionSettings: {
        'suggested_amount': 1000,
        'allow_partial': true,
        'per_person_rate': 300,
      },
    ),
  ];

  static void addGroup(GroupModel group) {
    final idx = groups.indexWhere(
        (g) => g.id == group.id || (g.code.isNotEmpty && g.code == group.code));
    if (idx != -1) {
      groups[idx] = group;
    } else {
      groups.insert(0, group);
    }
  }

  static void deleteGroup(String id) {
    groups.removeWhere((g) => g.id == id);
  }

  static void updateGroup(String id, Map<String, dynamic> data) {
    final idx = groups.indexWhere((g) => g.id == id);
    if (idx != -1) {
      final current = groups[idx];
      Map<String, dynamic> settings =
          Map<String, dynamic>.from(current.contributionSettings);
      if (data['suggested_amount'] != null) {
        settings['suggested_amount'] =
            double.tryParse(data['suggested_amount'].toString()) ?? 100;
      }
      groups[idx] = current.copyWith(
        name: data['name'] as String?,
        code: data['code'] as String?,
        description: data['description'] as String?,
        location: data['location'] as String?,
        contributionSettings: settings,
      );
    }
  }

  static final List<RoleModel> roles = [
    const RoleModel(
      id: 'rol_super_admin',
      code: 'SUPER_ADMIN',
      name: 'Super Admin',
      description: 'System-wide owner with complete authority (*)',
      scopeType: 'system',
      isSystem: true,
      isSystemRole: true,
      isActive: true,
      permissions: ['*'],
    ),
    const RoleModel(
      id: 'rol_org_admin',
      code: 'ORG_ADMIN',
      name: 'Organization Admin',
      description:
          'Administrator managing the organization, campaigns, groups, and members',
      scopeType: 'organization',
      isSystem: true,
      isSystemRole: true,
      isActive: true,
      permissions: [
        'dashboard.view',
        'dashboard.export',
        'organizations.view',
        'organizations.edit',
        'groups.view',
        'groups.create',
        'groups.edit',
        'groups.settings',
        'users.view',
        'users.create',
        'users.edit',
        'users.export',
        'roles.view',
        'roles.create',
        'roles.edit',
        'group_members.view',
        'group_members.create',
        'group_members.edit',
        'group_members.delete',
        'group_members.export',
        'join_requests.view',
        'join_requests.approve',
        'campaigns.view',
        'campaigns.create',
        'campaigns.edit',
        'campaigns.settings',
        'contribution_settings.view',
        'contribution_settings.edit',
        'contribution_settings.settings',
        'collections.view',
        'collections.create',
        'collections.edit',
        'collections.export',
        'payment_verification.view',
        'payment_verification.verify',
        'payment_verification.export',
        'receipts.view',
        'receipts.create',
        'receipts.delete',
        'receipts.export',
        'expenses.view',
        'expenses.create',
        'expenses.edit',
        'expenses.approve',
        'expenses.export',
        'expense_approval.view',
        'expense_approval.approve',
        'expense_approval.export',
        'collection_reports.view',
        'collection_reports.export',
        'expense_reports.view',
        'expense_reports.export',
        'pending_dues.view',
        'pending_dues.export',
        'complaints.view',
        'complaints.create',
        'complaints.edit',
        'complaints.approve',
        'notifications.view',
        'notifications.create',
        'notifications.settings',
        'audit_logs.view',
        'audit_logs.export',
        'organization_settings.view',
        'organization_settings.edit',
        'organization_settings.settings',
        'group_settings.view',
        'group_settings.edit',
        'group_settings.settings',
      ],
    ),
    const RoleModel(
      id: 'rol_group_admin',
      code: 'GROUP_ADMIN',
      name: 'Group Admin / Treasurer',
      description:
          'Ward/Group level coordinator managing group collections and dues',
      scopeType: 'group',
      isSystem: true,
      isSystemRole: true,
      isActive: true,
      permissions: [
        'dashboard.view',
        'groups.view',
        'group_members.view',
        'group_members.create',
        'group_members.edit',
        'join_requests.view',
        'join_requests.approve',
        'campaigns.view',
        'collections.view',
        'collections.create',
        'collections.edit',
        'collections.export',
        'payment_verification.view',
        'payment_verification.verify',
        'receipts.view',
        'receipts.create',
        'receipts.export',
        'expenses.view',
        'expenses.create',
        'expenses.approve',
        'expense_approval.view',
        'expense_approval.approve',
        'collection_reports.view',
        'collection_reports.export',
        'pending_dues.view',
        'pending_dues.export',
        'complaints.view',
        'complaints.create',
        'complaints.approve',
        'group_settings.view',
        'group_settings.edit',
      ],
    ),
    const RoleModel(
      id: 'rol_treasurer',
      code: 'TREASURER',
      name: 'Treasurer',
      description:
          'Manages treasury, cash verification, expense approvals and balance sheet audits',
      scopeType: 'organization',
      isSystem: true,
      isSystemRole: true,
      isActive: true,
      permissions: [
        'dashboard.view',
        'dashboard.export',
        'collections.view',
        'collections.export',
        'payment_verification.view',
        'payment_verification.verify',
        'payment_verification.export',
        'receipts.view',
        'receipts.export',
        'expenses.view',
        'expenses.create',
        'expenses.edit',
        'expenses.approve',
        'expenses.export',
        'expense_approval.view',
        'expense_approval.approve',
        'expense_approval.export',
        'collection_reports.view',
        'collection_reports.export',
        'expense_reports.view',
        'expense_reports.export',
        'pending_dues.view',
        'pending_dues.export',
        'complaints.view',
        'audit_logs.view',
      ],
    ),
    const RoleModel(
      id: 'rol_collector',
      code: 'COLLECTOR',
      name: 'Collector',
      description:
          'Field agent authorized to record household collections and issue receipts',
      scopeType: 'group',
      isSystem: true,
      isSystemRole: true,
      isActive: true,
      permissions: [
        'dashboard.view',
        'collections.view',
        'collections.create',
        'receipts.view',
        'receipts.create',
        'pending_dues.view',
        'complaints.view',
        'complaints.create',
      ],
    ),
    const RoleModel(
      id: 'rol_public',
      code: 'PUBLIC_USER',
      name: 'Member / Public User',
      description:
          'Citizen access: view public festival details, own receipts, and file complaints',
      scopeType: 'system',
      isSystem: true,
      isSystemRole: true,
      isActive: true,
      permissions: [
        'dashboard.view',
        'receipts.view',
        'complaints.view',
        'complaints.create',
      ],
    ),
    // Example Custom Role: Cash Verifier (Section 5 Requirement)
    const RoleModel(
      id: 'rol_cash_verifier',
      code: 'CASH_VERIFIER',
      name: 'Cash Verifier',
      description:
          'Audits payment entries, verifies online/cash receipts without expense access',
      scopeType: 'organization',
      isSystem: false,
      isSystemRole: false,
      isActive: true,
      permissions: [
        'dashboard.view',
        'collections.view',
        'payment_verification.view',
        'payment_verification.verify',
        'receipts.view',
        'collection_reports.view',
        'collection_reports.export',
      ],
    ),
  ];

  static final List<UserRoleAssignmentModel> userRoleAssignments = [
    UserRoleAssignmentModel(
      id: 'asgn_001',
      userId: 'usr_ritesh',
      userName: 'Ritesh Sangale (Super Admin)',
      userPhone: '9699342811',
      userEmail: 'ritesh.sangale@varganipro.in',
      roleId: 'rol_super_admin',
      roleKey: 'SUPER_ADMIN',
      roleName: 'Super Admin',
      createdAt: DateTime(2026, 1, 1),
    ),
    UserRoleAssignmentModel(
      id: 'asgn_002',
      userId: 'usr_admin',
      userName: 'Sachin Kadam',
      userPhone: '9822054321',
      userEmail: 'sachin.kadam@mandal.org',
      roleId: 'rol_org_admin',
      roleKey: 'ORG_ADMIN',
      roleName: 'Organization Admin',
      organizationId: 'org_001',
      organizationName: 'Shree Shiv Chhatrapati Mitra Mandal',
      createdAt: DateTime(2026, 1, 15),
    ),
    UserRoleAssignmentModel(
      id: 'asgn_003',
      userId: 'usr_treasurer',
      userName: 'Anil Shinde',
      userPhone: '9850077889',
      userEmail: 'anil.shinde@mandal.org',
      roleId: 'rol_treasurer',
      roleKey: 'TREASURER',
      roleName: 'Treasurer',
      organizationId: 'org_001',
      organizationName: 'Shree Shiv Chhatrapati Mitra Mandal',
      groupId: 'grp_001',
      groupName: 'Shivaji Chowk Mandal Group',
      createdAt: DateTime(2026, 2, 1),
    ),
    UserRoleAssignmentModel(
      id: 'asgn_004',
      userId: 'usr_collector1',
      userName: 'Rohan Gaikwad',
      userPhone: '9765432100',
      userEmail: 'rohan.g@mandal.org',
      roleId: 'rol_collector',
      roleKey: 'COLLECTOR',
      roleName: 'Collector',
      organizationId: 'org_001',
      organizationName: 'Shree Shiv Chhatrapati Mitra Mandal',
      groupId: 'grp_001',
      groupName: 'Shivaji Chowk Mandal Group',
      createdAt: DateTime(2026, 2, 10),
    ),
    UserRoleAssignmentModel(
      id: 'asgn_005',
      userId: 'usr_collector2',
      userName: 'Pooja Sawant',
      userPhone: '9922144556',
      userEmail: 'pooja.s@mandal.org',
      roleId: 'rol_cash_verifier',
      roleKey: 'CASH_VERIFIER',
      roleName: 'Cash Verifier',
      organizationId: 'org_001',
      organizationName: 'Shree Shiv Chhatrapati Mitra Mandal',
      groupId: 'grp_001',
      groupName: 'Shivaji Chowk Mandal Group',
      createdAt: DateTime(2026, 3, 1),
    ),
  ];

  static void addRole(RoleModel role) {
    final idx = roles.indexWhere((r) =>
        r.id == role.id || r.roleKey == role.roleKey || r.code == role.code);
    if (idx != -1) {
      roles[idx] = role;
    } else {
      roles.insert(0, role);
    }
  }

  static bool toggleRoleActive(String roleId, bool isActive) {
    final idx = roles.indexWhere((r) => r.id == roleId);
    if (idx != -1) {
      if (roles[idx].isSuperAdmin && !isActive) return false;
      roles[idx] = roles[idx].copyWith(isActive: isActive);
      return true;
    }
    return false;
  }

  static bool deleteRole(String roleId) {
    final idx = roles.indexWhere((r) => r.id == roleId);
    if (idx == -1) return false;
    final role = roles[idx];
    if (role.isSystemRole || role.isSuperAdmin) {
      return false; // Cannot delete protected system roles
    }
    // Prevent deletion of roles that are in use unless assignments are migrated
    final isInUse = userRoleAssignments
        .any((a) => a.roleId == roleId || a.roleKey == role.roleKey);
    if (isInUse) {
      return false;
    }
    roles.removeAt(idx);
    return true;
  }

  static bool assignUserRole({
    required String userId,
    required String roleId,
    String? organizationId,
    String? groupId,
    String? assignedBy,
  }) {
    final role = roles.firstWhere((r) => r.id == roleId,
        orElse: () => const RoleModel(id: '', code: '', name: ''));
    if (role.id.isEmpty) return false;

    final user = users.firstWhere((u) => u.id == userId,
        orElse: () => const UserModel(
            id: '',
            name: '',
            phone: '',
            email: '',
            organizationId: '',
            role: UserRole.citizen));
    if (user.id.isEmpty) return false;

    // Check if duplicate assignment exists for same user, role, and group
    final existingIdx = userRoleAssignments.indexWhere(
      (a) =>
          a.userId == userId &&
          (a.roleId == roleId || a.roleKey == role.roleKey) &&
          a.groupId == groupId,
    );
    if (existingIdx != -1) return true;

    final newAssignment = UserRoleAssignmentModel(
      id: 'asgn_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: user.name,
      userPhone: user.phone,
      userEmail: user.email,
      roleId: role.id,
      roleKey: role.roleKey,
      roleName: role.name,
      organizationId: organizationId ?? user.organizationId,
      organizationName: 'Shree Shiv Chhatrapati Mitra Mandal',
      groupId: groupId,
      groupName: groupId != null
          ? (groups
              .firstWhere((g) => g.id == groupId, orElse: () => groups.first)
              .name)
          : null,
      assignedBy: assignedBy,
      createdAt: DateTime.now(),
    );

    userRoleAssignments.insert(0, newAssignment);
    return true;
  }

  static bool revokeUserRole(String assignmentId) {
    userRoleAssignments.removeWhere((a) => a.id == assignmentId);
    return true;
  }

  static List<PermissionModel> get permissions {
    final list = <PermissionModel>[];
    for (final m in RbacModuleRegistry.allModules) {
      for (final a in m.applicableActions) {
        list.add(PermissionModel(
          id: 'perm_${m.key}_${a.key}',
          code: m.permissionKey(a),
          module: m.key,
          action: a.key,
          description: '${m.name} - ${a.displayName}',
        ));
      }
    }
    return list;
  }

  static final List<UserModel> users = [
    const UserModel(
      id: 'usr_ritesh',
      name: 'Ritesh Sangale (Super Admin)',
      phone: '9699342811',
      email: 'ritesh.sangale@varganipro.in',
      organizationId: 'platform',
      role: UserRole.superAdmin,
      permissions: ['*'],
      accountStatus: 'active',
      isActive: true,
    ),
    const UserModel(
      id: 'usr_admin',
      name: 'Sachin Kadam',
      phone: '+91 98220 54321',
      email: 'sachin.kadam@mandal.org',
      organizationId: 'org_001',
      role: UserRole.orgAdmin,
    ),
    const UserModel(
      id: 'usr_treasurer',
      name: 'Anil Shinde',
      phone: '+91 98500 77889',
      email: 'anil.shinde@mandal.org',
      organizationId: 'org_001',
      role: UserRole.treasurer,
    ),
    const UserModel(
      id: 'usr_collector1',
      name: 'Rohan Gaikwad',
      phone: '+91 97654 32100',
      email: 'rohan.g@mandal.org',
      organizationId: 'org_001',
      role: UserRole.collector,
    ),
    const UserModel(
      id: 'usr_collector2',
      name: 'Pooja Sawant',
      phone: '+91 99221 44556',
      email: 'pooja.s@mandal.org',
      organizationId: 'org_001',
      role: UserRole.collector,
    ),
    const UserModel(
      id: 'usr_citizen',
      name: 'Rahul Patil',
      phone: '+91 98234 01122',
      email: 'rahul.patil@gmail.com',
      organizationId: 'org_001',
      role: UserRole.citizen,
    ),
    const UserModel(
      id: 'usr_inactive_test',
      name: 'Inactive User',
      phone: '9111122222',
      email: 'inactive@varganipro.in',
      organizationId: 'org_001',
      role: UserRole.collector,
      isActive: false,
      accountStatus: 'inactive',
    ),
  ];

  static void addUser(UserModel user) {
    final idx = users.indexWhere((u) =>
        u.id == user.id || (u.phone.isNotEmpty && u.phone == user.phone));
    if (idx != -1) {
      users[idx] = user;
    } else {
      users.insert(0, user);
    }
  }

  static void deleteUser(String userId) {
    users.removeWhere((u) => u.id == userId);
  }

  static bool hasFinancialTransactions(String userId) {
    final inReceipts = getInitialReceipts().any((r) =>
        r.collectedByName.contains(userId) ||
        r.receivedByName.contains(userId));
    final inHandovers = getInitialHandovers().any((h) =>
        h.handoverFromName.contains(userId) ||
        h.handoverToName.contains(userId));
    return inReceipts || inHandovers;
  }

  static final List<CampaignModel> campaigns = [
    CampaignModel(
      id: 'cmp_ganesh_2026',
      organizationId: 'org_001',
      name: 'Ganeshotsav 2026',
      varganiType: VarganiType.ganeshotsav,
      description:
          'Annual 10-day grand Ganesh festival, cultural events, and Mahaprasad.',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 25),
      targetAmount: 500000.0,
      perPersonRate: 100.0,
      suggestedAmount: 500.0,
      allowPartialPayment: true,
      status: 'Active',
      rateEffectiveDate: DateTime(2026, 8, 1),
    ),
    CampaignModel(
      id: 'cmp_shivjayanti_2026',
      organizationId: 'org_001',
      name: 'Shivjayanti Utsav 2026',
      varganiType: VarganiType.shivjayanti,
      description:
          'Chhatrapati Shivaji Maharaj Jayanti grand procession and historical lecture series.',
      startDate: DateTime(2026, 2, 10),
      endDate: DateTime(2026, 2, 22),
      targetAmount: 350000.0,
      perPersonRate: 150.0,
      suggestedAmount: 600.0,
      allowPartialPayment: true,
      status: 'Upcoming',
      rateEffectiveDate: DateTime(2026, 1, 15),
    ),
    CampaignModel(
      id: 'cmp_gram_vikas',
      organizationId: 'org_001',
      name: 'Gram Vikas & Solar Lighting Nidhi',
      varganiType: VarganiType.villageDevelopment,
      description:
          'Community solar street-lighting and village library development initiative.',
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 12, 31),
      targetAmount: 1000000.0,
      perPersonRate: 250.0,
      suggestedAmount: 1000.0,
      allowPartialPayment: true,
      status: 'Active',
      rateEffectiveDate: DateTime(2026, 3, 20),
    ),
  ];

  static List<HouseholdModel> getInitialHouseholds() => [];

  static List<PaymentModel> getInitialPayments() => [];

  static List<ReceiptModel> getInitialReceipts() => [];

  static List<CashHandoverModel> getInitialHandovers() => [];

  static List<ExpenseModel> getInitialExpenses() => [];

  static List<ComplaintModel> getInitialComplaints() => [];

  static List<AuditLogModel> getInitialAuditLogs() => [];
}
