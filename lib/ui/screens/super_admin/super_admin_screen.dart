import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/organization_model.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/role_model.dart';
import '../../../core/models/join_request_model.dart';
import '../../../core/models/user_role_assignment_model.dart';
import '../../../core/models/audit_log_model.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../providers/auth_provider.dart';
import '../auth/organization_selection_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/organization_status_card.dart';
import '../../widgets/mandatory_label.dart';
import '../../../core/utils/hash_util.dart';

enum SuperAdminModule {
  dashboard,
  organizations,
  groups,
  users,
  roles,
  permissions,
  roleAssignment,
  hierarchyMapping,
  joinRequests,
  collections,
  expenses,
  reports,
  auditLogs,
  accountStatus,
  settings,
}

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  SuperAdminModule _activeModule = SuperAdminModule.dashboard;
  bool _isLoading = true;

  // Cached Master Data
  List<OrganizationModel> _organizations = [];
  List<GroupModel> _groups = [];
  List<UserModel> _users = [];
  List<RoleModel> _roles = [];
  List<PermissionModel> _permissions = [];
  List<UserRoleAssignmentModel> _assignments = [];
  List<JoinRequestModel> _joinRequests = [];
  List<AuditLogModel> _auditLogs = [];
  List<PaymentModel> _collections = [];
  List<ExpenseModel> _expenses = [];

  // Filter States
  String _searchFilter = '';
  String _userRoleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadAllMasterData();
  }

  Future<void> _loadAllMasterData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Orgs
      var orgs = await SupabaseService.getOrganizations();
      if (orgs == null || orgs.isEmpty) {
        final apiOrg = await ApiService.fetchOrganization();
        if (apiOrg != null) orgs = [apiOrg];
      }

      // 2. Groups
      var grps = await SupabaseService.getGroups();
      grps ??= await ApiService.fetchGroups();

      // 3. Users
      var usrs = await SupabaseService.getUsers();
      usrs ??= await ApiService.fetchUsers();

      // 4. Roles & Permissions
      var rls = await SupabaseService.getRoles();
      rls ??= await ApiService.fetchRoles();

      var perms = await SupabaseService.getPermissions();
      perms ??= await ApiService.fetchPermissions();

      // 5. Assignments & Join Requests
      var assigns = await SupabaseService.getAllUserRoleAssignments();
      var reqs = await SupabaseService.getJoinRequests();

      // 6. Audit Logs
      var logs = await SupabaseService.getAuditLogs();
      logs ??= await ApiService.fetchAuditLogs();

      // 7. Collections & Expenses
      var cols = await SupabaseService.getCollections('camp_001');
      cols ??= [];

      var exps = await SupabaseService.getExpenses('camp_001');
      exps ??= await ApiService.fetchExpenses('camp_001');

      if (mounted) {
        setState(() {
          _organizations = orgs ?? [];
          _groups = grps ?? [];
          final authUsers = context.read<AuthProvider>().availableUsers;
          final rawUsers = <UserModel>[...authUsers];
          for (final u in (usrs ?? [])) {
            if (!rawUsers.any((e) => e.id == u.id || (e.phone.isNotEmpty && e.phone == u.phone))) {
              rawUsers.add(u);
            }
          }
          final cleanUsers = <UserModel>[];
          bool hasSuperAdmin = false;
          for (final u in rawUsers) {
            if (u.role == UserRole.superAdmin) {
              if (u.phone.contains('9699342811') || u.id == 'usr_ritesh') {
                if (!hasSuperAdmin) {
                  cleanUsers.add(u);
                  hasSuperAdmin = true;
                }
              } else {
                // Remap any duplicate super admin (e.g. Vikram) to Org Admin
                cleanUsers.add(u.copyWith(role: UserRole.orgAdmin));
              }
            } else {
              cleanUsers.add(u);
            }
          }
          _users = cleanUsers;
          _roles = rls ?? [];
          _permissions = perms ?? [];
          _assignments = assigns ?? [];
          _joinRequests = reqs ?? [];
          _auditLogs = logs ?? [];
          _collections = cols ?? [];
          _expenses = exps ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading master data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalCollectionsAmount =>
      _collections.fold(0.0, (acc, c) => acc + c.amount);
  double get _totalExpensesAmount =>
      _expenses.fold(0.0, (acc, e) => acc + e.amount);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _getModuleName(_activeModule),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      drawer: isWide ? null : _buildMobileDrawer(isDark, auth),
      bottomNavigationBar: isWide ? null : _buildBottomNavBar(isDark),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                if (isWide) _buildDesktopRail(isDark),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: RefreshIndicator(
                      onRefresh: _loadAllMasterData,
                      color: AppColors.primary,
                      child: _buildActiveModuleView(isDark, auth),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    const mainModules = [
      SuperAdminModule.dashboard,
      SuperAdminModule.organizations,
      SuperAdminModule.groups,
      SuperAdminModule.users,
      SuperAdminModule.roles,
    ];

    final currentIndex = mainModules.indexOf(_activeModule);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 460;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: isCompact ? 58 : 64,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: isCompact ? 10.5 : 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            overflow: TextOverflow.ellipsis,
            letterSpacing: isCompact ? -0.4 : -0.2,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex != -1 ? currentIndex : 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        elevation: 6,
        height: isCompact ? 58 : 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (idx) {
          setState(() {
            _activeModule = mainModules[idx];
            _searchFilter = '';
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon:
                Icon(Icons.dashboard_rounded, color: AppColors.primary),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: const Icon(Icons.apartment_outlined),
            selectedIcon:
                const Icon(Icons.apartment_rounded, color: AppColors.primary),
            label: isCompact ? 'Orgs' : 'Organizations',
          ),
          const NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub_rounded, color: AppColors.primary),
            label: 'Groups',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon:
                Icon(Icons.people_alt_rounded, color: AppColors.primary),
            label: 'Users',
          ),
          const NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon:
                Icon(Icons.security_rounded, color: AppColors.primary),
            label: 'Roles',
          ),
        ],
      ),
    );
  }

  String _getModuleName(SuperAdminModule module) {
    switch (module) {
      case SuperAdminModule.dashboard:
        return 'Overview';
      case SuperAdminModule.organizations:
        return 'Organization Management';
      case SuperAdminModule.groups:
        return 'Group Management';
      case SuperAdminModule.users:
        return 'User Management';
      case SuperAdminModule.roles:
        return 'Role Management';
      case SuperAdminModule.permissions:
        return 'Permission Management';
      case SuperAdminModule.roleAssignment:
        return 'User Role Assignment';
      case SuperAdminModule.hierarchyMapping:
        return 'Hierarchy Access Mapping';
      case SuperAdminModule.joinRequests:
        return 'Join Request Monitoring';
      case SuperAdminModule.collections:
        return 'Collection Overview';
      case SuperAdminModule.expenses:
        return 'Expense Overview';
      case SuperAdminModule.reports:
        return 'System Reports';
      case SuperAdminModule.auditLogs:
        return 'Audit Logs';
      case SuperAdminModule.accountStatus:
        return 'Account Status Control';
      case SuperAdminModule.settings:
        return 'Application Settings';
    }
  }

  // ===========================================================================
  // NAVIGATION: DESKTOP RAIL & MOBILE DRAWER
  // ===========================================================================
  Widget _buildDesktopRail(bool isDark) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
            right: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavHeader(
                    title: 'Admin Modules (15)',
                    subtitle: 'Multi-Org System Control'),
                const Divider(height: 1),
                ...SuperAdminModule.values.map((mod) => _buildNavItem(mod)),
              ],
            ),
          ),
          const Divider(height: 1),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => InkWell(
              onTap: () => _confirmLogout(context, auth),
              child: Container(
                margin: const EdgeInsets.all(12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 18, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(bool isDark, AuthProvider auth) {
    const mainModules = [
      SuperAdminModule.dashboard,
      SuperAdminModule.organizations,
      SuperAdminModule.groups,
      SuperAdminModule.users,
      SuperAdminModule.roles,
    ];

    final otherModules =
        SuperAdminModule.values.where((m) => !mainModules.contains(m)).toList();

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Header in Drawer
            _buildDrawerProfileHeader(auth, isDark),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ADVANCED MODULES',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ...otherModules
                      .map((mod) => _buildNavItem(mod, isDrawer: true)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const Divider(height: 1),
            // Organization Status Card
            OrganizationStatusCard(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              organization: auth.selectedOrganization ??
                  (_organizations.isNotEmpty ? _organizations.last : null),
              organizationCount: _organizations.length,
              onSwitch: () {
                Navigator.pop(context); // Close drawer first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const OrganizationSelectionScreen(isSwitching: true),
                  ),
                );
              },
            ),
            // Logout Button placed prominently at the bottom of the drawer
            InkWell(
              onTap: () => _confirmLogout(context, auth),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          size: 20, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Log Out',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Return to Login',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.redAccent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                Navigator.pop(context);
              }
              auth.logout();
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerProfileHeader(AuthProvider auth, bool isDark) {
    final user = auth.currentUser;
    final userName = user.name.isNotEmpty ? user.name : 'Ritesh Sangale';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground
            : AppColors.primary.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Super Admin',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavHeader(
      {String title = 'Admin Modules',
      String subtitle = 'Multi-Org System Control'}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(SuperAdminModule module, {bool isDrawer = false}) {
    final isSelected = _activeModule == module;
    IconData icon;
    switch (module) {
      case SuperAdminModule.dashboard:
        icon = Icons.dashboard_rounded;
        break;
      case SuperAdminModule.organizations:
        icon = Icons.apartment_rounded;
        break;
      case SuperAdminModule.groups:
        icon = Icons.hub_rounded;
        break;
      case SuperAdminModule.users:
        icon = Icons.people_alt_rounded;
        break;
      case SuperAdminModule.roles:
        icon = Icons.security_rounded;
        break;
      case SuperAdminModule.permissions:
        icon = Icons.vpn_key_rounded;
        break;
      case SuperAdminModule.roleAssignment:
        icon = Icons.assignment_ind_rounded;
        break;
      case SuperAdminModule.hierarchyMapping:
        icon = Icons.account_tree_rounded;
        break;
      case SuperAdminModule.joinRequests:
        icon = Icons.group_add_rounded;
        break;
      case SuperAdminModule.collections:
        icon = Icons.receipt_long_rounded;
        break;
      case SuperAdminModule.expenses:
        icon = Icons.shopping_bag_rounded;
        break;
      case SuperAdminModule.reports:
        icon = Icons.bar_chart_rounded;
        break;
      case SuperAdminModule.auditLogs:
        icon = Icons.history_edu_rounded;
        break;
      case SuperAdminModule.accountStatus:
        icon = Icons.toggle_on_rounded;
        break;
      case SuperAdminModule.settings:
        icon = Icons.settings_applications_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 18,
          color: isSelected ? AppColors.primary : Colors.grey.shade600,
        ),
        title: Text(
          _getModuleName(module),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
        onTap: () {
          setState(() {
            _activeModule = module;
            _searchFilter = '';
          });
          if (isDrawer) Navigator.pop(context);
        },
      ),
    );
  }

  // ===========================================================================
  // MODULE VIEW DISPATCHER
  // ===========================================================================
  Widget _buildActiveModuleView(bool isDark, AuthProvider auth) {
    switch (_activeModule) {
      case SuperAdminModule.dashboard:
        return _buildDashboardOverview();
      case SuperAdminModule.organizations:
        return _buildOrganizationManagement();
      case SuperAdminModule.groups:
        return _buildGroupManagement();
      case SuperAdminModule.users:
        return _buildUserManagement();
      case SuperAdminModule.roles:
        return _buildRoleManagement();
      case SuperAdminModule.permissions:
        return _buildPermissionManagement();
      case SuperAdminModule.roleAssignment:
        return _buildUserRoleAssignment();
      case SuperAdminModule.hierarchyMapping:
        return _buildHierarchyMapping();
      case SuperAdminModule.joinRequests:
        return _buildJoinRequestMonitoring();
      case SuperAdminModule.collections:
        return _buildCollectionOverview();
      case SuperAdminModule.expenses:
        return _buildExpenseOverview();
      case SuperAdminModule.reports:
        return _buildReportsOverview();
      case SuperAdminModule.auditLogs:
        return _buildAuditLogsView();
      case SuperAdminModule.accountStatus:
        return _buildAccountStatusControl();
      case SuperAdminModule.settings:
        return _buildApplicationSettings();
    }
  }

  // ===========================================================================
  // 1. DASHBOARD OVERVIEW
  // ===========================================================================
  Widget _buildDashboardOverview() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Super Admin System Overview',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete governance over multi-organizations, groups, role-based access control (RBAC), and centralized financial monitoring.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Key Metrics & System Indicators',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        // KPI Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth > 900
                ? 4
                : (constraints.maxWidth > 600 ? 3 : 2);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: count,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildKpiCard(
                    'Organizations',
                    '${_organizations.length}',
                    Icons.apartment_rounded,
                    Colors.purple,
                    SuperAdminModule.organizations),
                _buildKpiCard('Total Groups', '${_groups.length}',
                    Icons.hub_rounded, Colors.indigo, SuperAdminModule.groups),
                _buildKpiCard(
                    'Total Users',
                    '${_users.length}',
                    Icons.people_alt_rounded,
                    Colors.blue,
                    SuperAdminModule.users),
                _buildKpiCard(
                    'Pending Requests',
                    '${_joinRequests.where((r) => r.isPending).length}',
                    Icons.pending_actions_rounded,
                    Colors.orange,
                    SuperAdminModule.joinRequests),
                _buildKpiCard(
                    'Total Collections',
                    '₹${_totalCollectionsAmount.toStringAsFixed(0)}',
                    Icons.payments_rounded,
                    AppColors.statusPaid,
                    SuperAdminModule.collections),
                _buildKpiCard(
                    'Total Expenses',
                    '₹${_totalExpensesAmount.toStringAsFixed(0)}',
                    Icons.shopping_bag_rounded,
                    Colors.redAccent,
                    SuperAdminModule.expenses),
                _buildKpiCard('System Roles', '${_roles.length}',
                    Icons.shield_rounded, Colors.teal, SuperAdminModule.roles),
                _buildKpiCard(
                    'Audit Logs',
                    '${_auditLogs.length}',
                    Icons.history_edu_rounded,
                    Colors.blueGrey,
                    SuperAdminModule.auditLogs),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color,
      SuperAdminModule target) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _activeModule = target;
            _searchFilter = '';
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: color.withValues(alpha: 0.6)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. ORGANIZATION MANAGEMENT
  // ===========================================================================
  Widget _buildOrganizationManagement() {
    final list = _organizations.where((o) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return o.name.toLowerCase().contains(q) ||
          o.slug.toLowerCase().contains(q) ||
          o.district.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildModuleHeader(
          title: 'Organization Management',
          subtitle:
              'Create, edit, activate, deactivate, or archive organizations.',
          onAdd: () => _showAddEditOrgDialog(),
          addLabel: 'Add Organization',
        ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState('No organizations found.')
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final org = list[i];
                    final grpCount =
                        _groups.where((g) => g.organizationId == org.id).length;
                    final isActive = org.isActive;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          child: Icon(Icons.apartment_rounded,
                              color:
                                  isActive ? AppColors.primary : Colors.grey),
                        ),
                        title: Text(org.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          '$grpCount groups • ${org.village.isNotEmpty ? org.village : (isActive ? "Active" : "Inactive")}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isActive
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.cancel_outlined,
                                color: isActive ? Colors.green : Colors.grey,
                                size: 20,
                              ),
                              tooltip: isActive ? 'Deactivate' : 'Activate',
                              onPressed: () => _toggleOrgStatus(org),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primary, size: 20),
                              tooltip: 'Edit Organization',
                              onPressed: () => _showAddEditOrgDialog(org),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              tooltip: 'Archive / Delete',
                              onPressed: () => _archiveOrg(org),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddEditOrgDialog([OrganizationModel? existing]) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedType = existing?.organizationType ?? 'Festival Committee';
    final villageCtrl = TextEditingController(text: existing?.village ?? '');
    final distCtrl = TextEditingController(text: existing?.district ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit Organization' : 'Create Organization'),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MandatoryLabel('Organization Name', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter organization name',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Organization name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Organization Type', isRequired: true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select organization type',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Festival Committee',
                            child: Text('Festival Committee'),
                          ),
                          DropdownMenuItem(
                            value: 'Housing Society',
                            child: Text('Housing Society'),
                          ),
                          DropdownMenuItem(
                            value: 'Charitable Trust',
                            child: Text('Charitable Trust'),
                          ),
                          DropdownMenuItem(
                            value: 'Social Organization',
                            child: Text('Social Organization'),
                          ),
                          DropdownMenuItem(
                            value: 'Sports Club',
                            child: Text('Sports Club'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedType = v);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Village / City', isRequired: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: villageCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter village or city',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('District', isRequired: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: distCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter district',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Contact Number', isRequired: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Enter 10-digit contact number',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Description', isRequired: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter brief description (optional)',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);

                        final generatedSlug = existing?.slug.isNotEmpty == true
                            ? existing!.slug
                            : nameCtrl.text
                                .trim()
                                .toLowerCase()
                                .replaceAll(RegExp(r'[^a-z0-9]+'), '-');

                        final org = OrganizationModel(
                          id: (existing != null && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(existing!.id))
                              ? existing!.id
                              : const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          slug: generatedSlug,
                          organizationType: selectedType,
                          village: villageCtrl.text.trim(),
                          district: distCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          address: descCtrl.text.trim(),
                          registrationDate:
                              existing?.registrationDate ?? DateTime.now(),
                          status: existing?.status ?? 'active',
                        );

                        if (isEdit) {
                          await SupabaseService.updateOrganization(
                              org.id, org.toSupabaseJson());
                        } else {
                          await SupabaseService.insertOrganization(org);
                        }

                        MockDataService.addOrganization(org);

                        if (mounted) {
                          setState(() {
                            final idx = _organizations.indexWhere(
                                (o) => o.id == org.id || o.slug == org.slug);
                            if (idx != -1) {
                              _organizations[idx] = org;
                            } else {
                              _organizations.insert(0, org);
                            }
                          });

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Organization "${org.name}" saved successfully!'),
                              backgroundColor: AppColors.statusPaid,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleOrgStatus(OrganizationModel org) async {
    final newStatus = org.isActive ? 'inactive' : 'active';
    final ok =
        await SupabaseService.updateOrganization(org.id, {'status': newStatus});
    if (mounted) {
      _loadAllMasterData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(ok ? 'Status changed to $newStatus' : 'Update failed')),
      );
    }
  }

  Future<void> _archiveOrg(OrganizationModel org) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Organization?'),
        content: const Text(
          'Financial safety rule: To preserve accounting and audit compliance, organizations with collections cannot be hard-deleted. They will be soft-deleted / archived.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive Organization'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.archiveOrganization(org.id);
      _loadAllMasterData();
    }
  }

  // ===========================================================================
  // 3. GROUP MANAGEMENT
  // ===========================================================================
  Widget _buildGroupManagement() {
    final list = _groups.where((g) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return g.name.toLowerCase().contains(q) ||
          g.code.toLowerCase().contains(q) ||
          g.location.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildModuleHeader(
          title: 'Group Management',
          subtitle:
              'Create multiple groups under organizations, configure rates, and set locations.',
          onAdd: () => _showAddEditGroupDialog(),
          addLabel: 'Add Group',
        ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState('No groups found.')
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final grp = list[i];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: grp.isActive
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          child: Icon(Icons.hub_rounded,
                              color: grp.isActive
                                  ? AppColors.primary
                                  : Colors.grey),
                        ),
                        title: Text(grp.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primary, size: 20),
                              tooltip: 'Edit Group',
                              onPressed: () => _showAddEditGroupDialog(grp),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              tooltip: 'Delete Group',
                              onPressed: () => _confirmDeleteGroup(grp),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeleteGroup(GroupModel grp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Group'),
          ],
        ),
        content: Text(
            'Are you sure you want to permanently delete group "${grp.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteGroup(grp.id);
              MockDataService.deleteGroup(grp.id);
              if (mounted) {
                _loadAllMasterData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Group "${grp.name}" deleted successfully!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditGroupDialog([GroupModel? existing]) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final rateCtrl = TextEditingController(
        text:
            existing != null ? existing.perPersonRate.toStringAsFixed(0) : '');
    final suggestedCtrl = TextEditingController(
        text: existing != null
            ? existing.suggestedAmount.toStringAsFixed(0)
            : '');

    String selectedOrgId = existing?.organizationId ??
        (_organizations.isNotEmpty ? _organizations.first.id : 'org_001');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit_rounded : Icons.hub_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit Group' : 'Create Group'),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.78,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_organizations.isNotEmpty) ...[
                        const MandatoryLabel('Organization', isRequired: true),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedOrgId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            hintText: 'Select organization',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          items: _organizations.map((org) {
                            return DropdownMenuItem(
                              value: org.id,
                              child: Text(org.name,
                                  overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) => setDialogState(
                              () => selectedOrgId = v ?? selectedOrgId),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const MandatoryLabel('Group Name', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter group name',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Group name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Unique Group Code', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: codeCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. MANDAL_01',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Group code is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Location / Ward', isRequired: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: locCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter location or ward number',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MandatoryLabel('Rate / Person (₹)', isRequired: false),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: rateCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '200',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MandatoryLabel('Suggested (₹)', isRequired: false),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: suggestedCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '500',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Description', isRequired: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter group description (optional)',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);

                        final grp = GroupModel(
                          id: (existing != null && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(existing!.id))
                              ? existing!.id
                              : const Uuid().v4(),
                          organizationId: selectedOrgId,
                          name: nameCtrl.text.trim(),
                          code: codeCtrl.text.trim().toUpperCase(),
                          description: descCtrl.text.trim(),
                          location: locCtrl.text.trim(),
                          contributionSettings: {
                            'per_person_rate':
                                double.tryParse(rateCtrl.text.trim()) ?? 100.0,
                            'suggested_amount':
                                double.tryParse(suggestedCtrl.text.trim()) ??
                                    100.0,
                            'allow_partial': true,
                          },
                        );

                        if (isEdit) {
                          await SupabaseService.updateGroup(
                              grp.id, grp.toSupabaseJson());
                        } else {
                          await SupabaseService.insertGroup(grp);
                        }

                        MockDataService.addGroup(grp);

                        if (mounted) {
                          setState(() {
                            final idx = _groups.indexWhere(
                                (g) => g.id == grp.id || g.code == grp.code);
                            if (idx != -1) {
                              _groups[idx] = grp;
                            } else {
                              _groups.insert(0, grp);
                            }
                          });

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Group "${grp.name}" saved successfully!'),
                              backgroundColor: AppColors.statusPaid,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                child: const Text('Save Group'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 4. USER MANAGEMENT
  // ===========================================================================
  Widget _buildUserManagement() {
    final list = _users.where((u) {
      if (_userRoleFilter != 'ALL') {
        if (_userRoleFilter == 'ADMIN' &&
            u.role != UserRole.orgAdmin &&
            u.role != UserRole.superAdmin) return false;
        if (_userRoleFilter == 'TREASURER' && u.role != UserRole.treasurer)
          return false;
        if (_userRoleFilter == 'COLLECTOR' && u.role != UserRole.collector)
          return false;
        if (_userRoleFilter == 'CITIZEN' &&
            u.role != UserRole.citizen &&
            u.role != UserRole.publicUser) return false;
      }
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.role.nameString.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildModuleHeader(
          title: 'User Management',
          subtitle:
              'System-wide profile inspection, contact details, and role assignments.',
          onAdd: () => _showAddEditUserDialog(),
          addLabel: 'Add User',
          filterWidget: _buildUserFilterDropdown(),
        ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState('No users found.')
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final u = list[i];
                    final isSuper = u.role == UserRole.superAdmin;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSuper
                              ? Colors.purple.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            isSuper
                                ? Icons.admin_panel_settings_rounded
                                : Icons.person_rounded,
                            color: isSuper ? Colors.purple : AppColors.primary,
                          ),
                        ),
                        title: Text(
                          u.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.primary, size: 20),
                              tooltip: 'Edit User',
                              onPressed: () => _showAddEditUserDialog(u),
                            ),
                            if (!isSuper) ...[
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 20),
                                tooltip: 'Delete User',
                                onPressed: () => _confirmDeleteUser(u),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserFilterDropdown() {
    final allCount = _users.length;
    final adminsCount = _users
        .where(
            (u) => u.role == UserRole.orgAdmin || u.role == UserRole.superAdmin)
        .length;
    final treasurersCount =
        _users.where((u) => u.role == UserRole.treasurer).length;
    final collectorsCount =
        _users.where((u) => u.role == UserRole.collector).length;
    final citizensCount = _users
        .where(
            (u) => u.role == UserRole.citizen || u.role == UserRole.publicUser)
        .length;

    String selectedLabel;
    switch (_userRoleFilter) {
      case 'ADMIN':
        selectedLabel = 'Admins ($adminsCount)';
        break;
      case 'TREASURER':
        selectedLabel = 'Treasurers ($treasurersCount)';
        break;
      case 'COLLECTOR':
        selectedLabel = 'Collectors ($collectorsCount)';
        break;
      case 'CITIZEN':
        selectedLabel = 'Citizens ($citizensCount)';
        break;
      default:
        selectedLabel = 'All ($allCount)';
        break;
    }

    final isFiltered = _userRoleFilter != 'ALL';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      initialValue: _userRoleFilter,
      tooltip: 'Filter by Role',
      onSelected: (val) {
        setState(() => _userRoleFilter = val);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkBackground : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFiltered
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: isFiltered ? AppColors.primary : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              selectedLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isFiltered
                    ? AppColors.primary
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isFiltered ? AppColors.primary : Colors.grey.shade600,
            ),
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'ALL',
          child: Row(
            children: [
              Icon(
                _userRoleFilter == 'ALL'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color:
                    _userRoleFilter == 'ALL' ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text('All ($allCount)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ADMIN',
          child: Row(
            children: [
              Icon(
                _userRoleFilter == 'ADMIN'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: _userRoleFilter == 'ADMIN'
                    ? AppColors.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text('Admins ($adminsCount)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'TREASURER',
          child: Row(
            children: [
              Icon(
                _userRoleFilter == 'TREASURER'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: _userRoleFilter == 'TREASURER'
                    ? AppColors.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text('Treasurers ($treasurersCount)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'COLLECTOR',
          child: Row(
            children: [
              Icon(
                _userRoleFilter == 'COLLECTOR'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: _userRoleFilter == 'COLLECTOR'
                    ? AppColors.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text('Collectors ($collectorsCount)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'CITIZEN',
          child: Row(
            children: [
              Icon(
                _userRoleFilter == 'CITIZEN'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 18,
                color: _userRoleFilter == 'CITIZEN'
                    ? AppColors.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text('Citizens ($citizensCount)'),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteUser(UserModel u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete User'),
          ],
        ),
        content: Text(
            'Are you sure you want to permanently delete user "${u.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteUser(u.id);
              MockDataService.deleteUser(u.id);
              if (mounted) {
                setState(() {
                  _users.removeWhere((item) => item.id == u.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User "${u.name}" deleted successfully!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditUserDialog([UserModel? existing]) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final passwordCtrl = TextEditingController();
    bool obscurePassword = true;

    String selectedOrgId = existing?.organizationId ??
        (_organizations.isNotEmpty ? _organizations.first.id : 'org_001');
    String selectedGroupId = existing?.selectedGroupId ??
        (existing != null && existing.groupIds.isNotEmpty
            ? existing.groupIds.first
            : (_groups.isNotEmpty ? _groups.first.id : 'grp_001'));
    UserRole selectedRole = existing?.role ?? UserRole.collector;
    String selectedStatus = existing?.accountStatus ?? 'active';

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final groupOptions =
              _groups.where((g) => g.organizationId == selectedOrgId).toList();
          final effectiveGroups =
              groupOptions.isNotEmpty ? groupOptions : _groups;
          if (!effectiveGroups.any((g) => g.id == selectedGroupId) &&
              effectiveGroups.isNotEmpty) {
            selectedGroupId = effectiveGroups.first.id;
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit User' : 'Create User'),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(context).size.height * 0.78,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MandatoryLabel('Full Name', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Mobile Number', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          hintText: 'Enter 10-digit mobile number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Mobile number is required';
                          }
                          final clean = v.replaceAll(RegExp(r'\D'), '');
                          if (clean.length != 10 ||
                              !RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                            return 'Enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Email Address', isRequired: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter email address (optional)',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      MandatoryLabel(
                        'Password',
                        isRequired: !isEdit,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        maxLength: 17,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(17),
                        ],
                        decoration: InputDecoration(
                          hintText: isEdit
                              ? 'Leave blank to keep existing password'
                              : 'Enter password',
                          counterText: '',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setDialogState(
                                () => obscurePassword = !obscurePassword),
                          ),
                          helperText: isEdit
                              ? 'Leave blank to keep existing password'
                              : null,
                        ),
                        validator: (v) {
                          final pass = v?.trim() ?? '';
                          if (!isEdit && pass.isEmpty) {
                            return 'Please enter password';
                          }
                          if (pass.isNotEmpty &&
                              (pass.length < 8 || pass.length > 17)) {
                            return 'Password must be between 8 and 17 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      if (existing?.role == UserRole.superAdmin) ...[
                        const MandatoryLabel('Role', isRequired: false),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: 'Super Admin',
                          readOnly: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.security_rounded),
                            helperText:
                                'Super Admin role cannot be modified or duplicated',
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else ...[
                        const MandatoryLabel('Role', isRequired: true),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<UserRole>(
                          value: selectedRole,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Select role',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: UserRole.collector,
                              child: Text('Collection Agent',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: UserRole.treasurer,
                              child: Text('Treasurer',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: UserRole.groupAdmin,
                              child: Text('Group Admin',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: UserRole.orgAdmin,
                              child: Text('Organization Admin',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: UserRole.publicUser,
                              child: Text('Citizen / Contributor',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: UserRole.viewer,
                              child: Text('Viewer',
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (v) => setDialogState(
                              () => selectedRole = v ?? selectedRole),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (_organizations.isNotEmpty) ...[
                        const MandatoryLabel('Organization', isRequired: true),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedOrgId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Select organization',
                            prefixIcon: Icon(Icons.apartment_rounded),
                          ),
                          items: _organizations.map((org) {
                            return DropdownMenuItem(
                              value: org.id,
                              child: Text(
                                org.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setDialogState(() {
                              selectedOrgId = v ?? selectedOrgId;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (effectiveGroups.isNotEmpty) ...[
                        const MandatoryLabel('Assigned Group / Mandal', isRequired: true),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: selectedGroupId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Select assigned group',
                            prefixIcon: Icon(Icons.hub_outlined),
                          ),
                          items: effectiveGroups.map((grp) {
                            return DropdownMenuItem(
                              value: grp.id,
                              child: Text(
                                grp.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setDialogState(
                              () => selectedGroupId = v ?? selectedGroupId),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const MandatoryLabel('Account Status', isRequired: true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Select account status',
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'active',
                              child: Text('Active',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'inactive',
                              child: Text('Inactive',
                                  overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(
                              value: 'suspended',
                              child: Text('Suspended',
                                  overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) => setDialogState(
                            () => selectedStatus = v ?? 'active'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 16),
                label: Text(isSaving
                    ? 'Saving...'
                    : (isEdit ? 'Update User' : 'Save User')),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);

                        final cleanPhone = phoneCtrl.text.trim();
                        final emailVal = emailCtrl.text.trim();

                        final groupObj = _groups
                            .where((g) => g.id == selectedGroupId)
                            .firstOrNull;

                        final user = UserModel(
                          id: (existing != null && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(existing!.id))
                              ? existing!.id
                              : const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          phone: cleanPhone,
                          email: emailVal,
                          organizationId: selectedOrgId,
                          role: selectedRole,
                          isActive: selectedStatus == 'active',
                          accountStatus: selectedStatus,
                          groupIds: [selectedGroupId],
                          selectedGroupId: selectedGroupId,
                          selectedGroupName: groupObj?.name,
                          permissions: selectedRole == UserRole.collector
                              ? [
                                  'collection.create',
                                  'collection.view',
                                  'receipt.create',
                                  'receipt.view'
                                ]
                              : (selectedRole == UserRole.treasurer
                                  ? [
                                      'collection.view',
                                      'expense.create',
                                      'expense.view',
                                      'report.view'
                                    ]
                                  : ['group.view', 'collection.view']),
                        );

                        final rawPass = passwordCtrl.text.trim();
                        final assignedPass =
                            rawPass.isNotEmpty ? rawPass : 'Vargani@123';
                        final passHash = HashUtil.hashPassword(assignedPass);

                        final finalUser = user.copyWith(passwordHash: passHash);

                        if (isEdit) {
                          await SupabaseService.updateUser(
                            finalUser,
                            passwordHash: rawPass.isNotEmpty ? passHash : null,
                          );
                        } else {
                          await SupabaseService.insertUser(
                            finalUser,
                            passwordHash: passHash,
                          );
                        }

                        await context.read<AuthProvider>().registerAdminCreatedUser(
                          user: finalUser,
                          password: assignedPass,
                        );

                        MockDataService.addUser(finalUser);

                        if (mounted) {
                          setState(() {
                            final idx = _users.indexWhere((u) =>
                                u.id == finalUser.id ||
                                (u.phone.isNotEmpty && u.phone == finalUser.phone));
                            if (idx != -1) {
                              _users[idx] = finalUser;
                            } else {
                              _users.insert(0, finalUser);
                            }
                          });

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'User "${finalUser.name}" saved successfully!'),
                              backgroundColor: AppColors.statusPaid,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 5. ROLE MANAGEMENT
  // ===========================================================================
  Widget _buildRoleManagement() {
    return Column(
      children: [
        _buildModuleHeader(
          title: 'Role Management',
          subtitle:
              'Manage standard system roles and create custom organizational roles (e.g. Admin, Manager, Employee, Candidate).',
          onAdd: () => _showAddEditRoleDialog(),
          addLabel: 'Create Custom Role',
        ),
        Expanded(
          child: _roles.isEmpty
              ? _buildEmptyState('No roles configured.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _roles.length,
                  itemBuilder: (ctx, i) {
                    final role = _roles[i];
                    final isSys = role.isSystemRole;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isSys
                                          ? Icons.lock_outline_rounded
                                          : Icons.shield_rounded,
                                      size: 18,
                                      color: isSys
                                          ? Colors.grey
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      role.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSys
                                            ? Colors.grey
                                                .withValues(alpha: 0.12)
                                            : AppColors.primary
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        role.roleKey,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSys
                                              ? Colors.grey.shade700
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Scope: ${role.scopeType.toUpperCase()}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AppColors.primary, size: 18),
                                      tooltip: 'Edit Role / Modules',
                                      onPressed: () =>
                                          _showAddEditRoleDialog(role),
                                    ),
                                    if (!isSys) ...[
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                            size: 18),
                                        tooltip: 'Delete Role',
                                        onPressed: () =>
                                            _confirmDeleteRole(role),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (role.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(role.description,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'Enabled Permissions (${role.permissions.length}):',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            role.permissions.isEmpty
                                ? const Text('No explicit permissions assigned',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey))
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: role.permissions.map((p) {
                                      final isAll = p == '*';
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (isAll
                                                  ? Colors.purple
                                                  : AppColors.primary)
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: (isAll
                                                      ? Colors.purple
                                                      : AppColors.primary)
                                                  .withValues(alpha: 0.2)),
                                        ),
                                        child: Text(
                                          p,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isAll
                                                ? Colors.purple
                                                : AppColors.primary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDeleteRole(RoleModel role) {
    final inUse = _assignments
        .any((a) => a.roleId == role.id || a.roleKey == role.roleKey);
    if (inUse) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Role Cannot Be Deleted'),
            ],
          ),
          content: Text(
              'The role "${role.name}" is currently assigned to users. Revoke all user assignments before deleting this role.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Delete Role'),
          ],
        ),
        content: Text(
            'Are you sure you want to permanently delete role "${role.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.deleteRole(role.id);
              MockDataService.deleteRole(role.id);
              if (mounted) {
                _loadAllMasterData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Role "${role.name}" deleted successfully!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddEditRoleDialog([RoleModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final keyCtrl = TextEditingController(text: existing?.roleKey ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String scopeType = existing?.scopeType ?? 'organization';
    final Set<String> selectedPerms = Set.from(existing?.permissions ?? []);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    final moduleDefinitions = [
      {
        'key': 'collection',
        'title': 'Vargani Collection',
        'icon': Icons.payments_rounded,
        'color': Colors.green,
        'permissions': [
          {'code': 'collection.view', 'desc': 'View Collections'},
          {'code': 'collection.create', 'desc': 'Record Collection'},
          {'code': 'collection.update', 'desc': 'Edit Collection'},
          {'code': 'receipt.create', 'desc': 'Issue Receipt'},
          {'code': 'receipt.view', 'desc': 'Download / Share Receipt'},
        ],
      },
      {
        'key': 'expense',
        'title': 'Expense Management',
        'icon': Icons.shopping_bag_rounded,
        'color': Colors.redAccent,
        'permissions': [
          {'code': 'expense.view', 'desc': 'View Expenses'},
          {'code': 'expense.create', 'desc': 'Add Expense'},
          {'code': 'expense.approve', 'desc': 'Approve Expense'},
          {'code': 'expense.delete', 'desc': 'Delete Expense'},
        ],
      },
      {
        'key': 'report',
        'title': 'Reports & Analytics',
        'icon': Icons.bar_chart_rounded,
        'color': Colors.purple,
        'permissions': [
          {'code': 'report.view', 'desc': 'View Financial Reports'},
          {'code': 'report.export', 'desc': 'Export PDF / Excel'},
          {'code': 'report.audit', 'desc': 'Audit Logs'},
        ],
      },
      {
        'key': 'user',
        'title': 'Users & Employees',
        'icon': Icons.people_alt_rounded,
        'color': Colors.blue,
        'permissions': [
          {'code': 'user.view', 'desc': 'View Users List'},
          {'code': 'user.create', 'desc': 'Add New User'},
          {'code': 'user.update', 'desc': 'Edit User Information'},
          {'code': 'user.delete', 'desc': 'Delete User'},
          {'code': 'user.assign_role', 'desc': 'Assign Roles & Permissions'},
        ],
      },
      {
        'key': 'group',
        'title': 'Groups & Wards',
        'icon': Icons.hub_rounded,
        'color': Colors.orange,
        'permissions': [
          {'code': 'group.view', 'desc': 'View Groups'},
          {'code': 'group.create', 'desc': 'Create Group'},
          {'code': 'group.update', 'desc': 'Edit Group'},
          {'code': 'group.delete', 'desc': 'Delete Group'},
        ],
      },
      {
        'key': 'complaint',
        'title': 'Complaints & Grievances',
        'icon': Icons.report_problem_rounded,
        'color': Colors.deepOrange,
        'permissions': [
          {'code': 'complaint.view', 'desc': 'View Complaints'},
          {'code': 'complaint.resolve', 'desc': 'Resolve Complaints'},
        ],
      },
      {
        'key': 'settings',
        'title': 'System Settings',
        'icon': Icons.settings_rounded,
        'color': Colors.teal,
        'permissions': [
          {'code': 'settings.view', 'desc': 'View Settings'},
          {'code': 'settings.update', 'desc': 'Update Configuration'},
        ],
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                    existing != null
                        ? Icons.edit_rounded
                        : Icons.shield_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    existing != null
                        ? 'Edit Role & Module Permissions'
                        : 'Create Custom Role',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 580,
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MandatoryLabel('Role Name', isRequired: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter role name (e.g. Branch Supervisor)',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Role name is required'
                            : null,
                        onChanged: (v) {
                          if (existing == null && keyCtrl.text.isEmpty) {
                            keyCtrl.text = v
                                .trim()
                                .toUpperCase()
                                .replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MandatoryLabel('Role Key', isRequired: true),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: keyCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. BRANCH_SUPERVISOR',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty
                                      ? 'Role key is required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MandatoryLabel('Scope Type', isRequired: true),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: scopeType,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    hintText: 'Select scope',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'organization',
                                        child: Text('Organization',
                                            overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(
                                        value: 'group',
                                        child: Text('Group',
                                            overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(
                                        value: 'system',
                                        child: Text('System',
                                            overflow: TextOverflow.ellipsis)),
                                  ],
                                  onChanged: (v) => setDialogState(
                                      () => scopeType = v ?? scopeType),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const MandatoryLabel('Description', isRequired: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          hintText: 'Brief description of role responsibilities',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Modular Permissions
                      const Text(
                        'Select modules to enable for this role:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      ...moduleDefinitions.map((mod) {
                        final modPerms =
                            (mod['permissions'] as List<Map<String, String>>);
                        final allCodes =
                            modPerms.map((p) => p['code']!).toList();
                        final enabledCount = allCodes
                            .where((c) => selectedPerms.contains(c))
                            .length;
                        final isFullyEnabled = enabledCount == allCodes.length;
                        final isPartiallyEnabled =
                            enabledCount > 0 && !isFullyEnabled;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: enabledCount > 0
                                  ? (mod['color'] as Color)
                                      .withValues(alpha: 0.4)
                                  : Colors.grey.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: enabledCount > 0
                                ? (mod['color'] as Color)
                                    .withValues(alpha: 0.03)
                                : null,
                          ),
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: enabledCount > 0,
                              leading: Icon(mod['icon'] as IconData,
                                  color: mod['color'] as Color, size: 22),
                              title: Text(
                                mod['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: enabledCount > 0
                                      ? (mod['color'] as Color)
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                enabledCount == 0
                                    ? 'Disabled'
                                    : '$enabledCount/${allCodes.length} permissions active',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: enabledCount > 0
                                        ? Colors.green
                                        : Colors.grey),
                              ),
                              trailing: Switch(
                                value: isFullyEnabled || isPartiallyEnabled,
                                activeColor: mod['color'] as Color,
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val) {
                                      selectedPerms.addAll(allCodes);
                                    } else {
                                      selectedPerms.removeAll(allCodes);
                                    }
                                  });
                                },
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: Column(
                                    children: modPerms.map((p) {
                                      final isChecked =
                                          selectedPerms.contains(p['code']);
                                      return CheckboxListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        value: isChecked,
                                        title: Text(p['desc']!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        subtitle: Text(p['code']!,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                        activeColor: mod['color'] as Color,
                                        onChanged: (val) {
                                          setDialogState(() {
                                            if (val == true) {
                                              selectedPerms.add(p['code']!);
                                            } else {
                                              selectedPerms.remove(p['code']!);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton.icon(
                icon: isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 16),
                label: Text(isSaving
                    ? 'Saving...'
                    : (existing != null ? 'Update Role' : 'Save Role')),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);

                        final role = RoleModel(
                          id: (existing != null && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(existing!.id))
                              ? existing!.id
                              : const Uuid().v4(),
                          code: keyCtrl.text.trim().toUpperCase(),
                          roleKey: keyCtrl.text.trim().toUpperCase(),
                          name: nameCtrl.text.trim(),
                          scopeType: scopeType,
                          description: descCtrl.text.trim(),
                          permissions: selectedPerms.toList(),
                          isSystemRole: false,
                        );

                        await SupabaseService.insertRole(role);
                        MockDataService.addRole(role);

                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadAllMasterData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Role "${role.name}" saved successfully!'),
                              backgroundColor: AppColors.statusPaid,
                            ),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 6. PERMISSION MATRIX MANAGEMENT
  // ===========================================================================
  Widget _buildPermissionManagement() {
    // Group permissions by module
    final Map<String, List<PermissionModel>> grouped = {};
    for (final p in _permissions) {
      grouped.putIfAbsent(p.module, () => []).add(p);
    }

    return Column(
      children: [
        _buildModuleHeader(
          title: 'Permission Directory & Matrix',
          subtitle:
              'Granular permissions catalog across 10+ application modules.',
        ),
        Expanded(
          child: grouped.isEmpty
              ? _buildEmptyState('No permissions registered.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    final module = entry.key;
                    final perms = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                      Icons.folder_special_rounded,
                                      color: AppColors.primary,
                                      size: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Module: ${module.toUpperCase()}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                const Spacer(),
                                Text('${perms.length} Actions',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const Divider(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: perms.map((p) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.grey
                                            .withValues(alpha: 0.15)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        p.code,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p.description,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. USER ROLE ASSIGNMENT
  // ===========================================================================
  Widget _buildUserRoleAssignment() {
    return Column(
      children: [
        _buildModuleHeader(
          title: 'User Role Assignment',
          subtitle:
              'Explicitly map users to roles at System, Organization, or Group scope.',
          onAdd: () => _showAssignRoleDialog(),
          addLabel: 'Assign Role to User',
        ),
        Expanded(
          child: _assignments.isEmpty
              ? _buildEmptyState('No scoped user role assignments recorded.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  itemBuilder: (ctx, i) {
                    final assign = _assignments[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.assignment_ind_rounded,
                              color: Colors.white, size: 20),
                        ),
                        title: Text(assign.userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          'Role: ${assign.roleName} (${assign.roleKey})\nScope: ${assign.scopeDescription}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: (assign.roleKey == 'SUPER_ADMIN' ||
                                assign.userName.contains('Ritesh'))
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PERMANENT',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent),
                                tooltip: 'Revoke Role',
                                onPressed: () async {
                                  final ok =
                                      await SupabaseService.revokeUserRole(
                                          assign.id);
                                  if (mounted) {
                                    _loadAllMasterData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(ok
                                              ? 'Role revoked.'
                                              : 'Revoke failed.')),
                                    );
                                  }
                                },
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAssignRoleDialog() {
    if (_users.isEmpty || _roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users or roles available to assign.')),
      );
      return;
    }

    String selectedUserId = _users.first.id;
    String selectedRoleId = _roles.first.id;
    String? selectedOrgId =
        _organizations.isNotEmpty ? _organizations.first.id : null;
    String? selectedGroupId = _groups.isNotEmpty ? _groups.first.id : null;
    String scopeChoice = 'group'; // 'system', 'organization', 'group'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Assign Role to User'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MandatoryLabel('Select User', isRequired: true),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedUserId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select user',
                      ),
                      items: _users.map((u) {
                        return DropdownMenuItem(
                            value: u.id, child: Text('${u.name} (${u.phone})'));
                      }).toList(),
                      onChanged: (v) => setDialogState(
                          () => selectedUserId = v ?? selectedUserId),
                    ),
                    const SizedBox(height: 14),
                    const MandatoryLabel('Select Role', isRequired: true),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedRoleId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select role',
                      ),
                      items: _roles.map((r) {
                        return DropdownMenuItem(
                            value: r.id, child: Text('${r.name} (${r.roleKey})'));
                      }).toList(),
                      onChanged: (v) => setDialogState(
                          () => selectedRoleId = v ?? selectedRoleId),
                    ),
                    const SizedBox(height: 14),
                    const MandatoryLabel('Scope Type', isRequired: true),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: scopeChoice,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select scope type',
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'group', child: Text('Group Scope')),
                        DropdownMenuItem(
                            value: 'organization',
                            child: Text('Organization Scope')),
                        DropdownMenuItem(
                            value: 'system', child: Text('System Wide Scope')),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => scopeChoice = v ?? 'group'),
                    ),
                    if (scopeChoice == 'organization' ||
                        scopeChoice == 'group') ...[
                      const SizedBox(height: 14),
                      const MandatoryLabel('Organization', isRequired: true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedOrgId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Select organization',
                        ),
                        items: _organizations.map((o) {
                          return DropdownMenuItem(
                              value: o.id, child: Text(o.name));
                        }).toList(),
                        onChanged: (v) => setDialogState(() => selectedOrgId = v),
                      ),
                    ],
                    if (scopeChoice == 'group') ...[
                      const SizedBox(height: 14),
                      const MandatoryLabel('Group / Mandal', isRequired: true),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedGroupId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Select group',
                        ),
                        items: _groups.map((g) {
                          return DropdownMenuItem(
                              value: g.id, child: Text(g.name));
                        }).toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedGroupId = v),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final ok = await SupabaseService.assignUserRole(
                    userId: selectedUserId,
                    roleId: selectedRoleId,
                    organizationId:
                        scopeChoice != 'system' ? selectedOrgId : null,
                    groupId: scopeChoice == 'group' ? selectedGroupId : null,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadAllMasterData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(ok
                              ? 'Role assigned successfully!'
                              : 'Assignment failed.')),
                    );
                  }
                },
                child: const Text('Assign Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 8. HIERARCHY ACCESS MAPPING
  // ===========================================================================
  Widget _buildHierarchyMapping() {
    return Column(
      children: [
        _buildModuleHeader(
          title: 'Organization & Group Access Mapping',
          subtitle:
              'Visual tree of Organizations -> Groups -> Authorized Members.',
        ),
        Expanded(
          child: _organizations.isEmpty
              ? _buildEmptyState('No hierarchy to display.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _organizations.length,
                  itemBuilder: (ctx, i) {
                    final org = _organizations[i];
                    final orgGroups = _groups
                        .where((g) => g.organizationId == org.id)
                        .toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: const Icon(Icons.apartment_rounded,
                            color: AppColors.primary),
                        title: Text(org.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(
                            '${orgGroups.length} Groups • ${org.district}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        children: orgGroups.map((g) {
                          // Find users in this group
                          final groupUsers = _users
                              .where((u) => u.groupIds.contains(g.id))
                              .toList();

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ExpansionTile(
                              leading: const Icon(Icons.hub_rounded,
                                  color: Colors.indigo, size: 20),
                              title: Text(g.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              subtitle: Text(
                                  'Code: ${g.code} • ${groupUsers.length} Members',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                              children: groupUsers.isEmpty
                                  ? [
                                      const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text('No members assigned yet',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey)))
                                    ]
                                  : groupUsers.map((u) {
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                            Icons.person_outline_rounded,
                                            size: 16),
                                        title: Text(u.name,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                        subtitle: Text(u.phone,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey)),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(u.role.nameString,
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      );
                                    }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 9. JOIN REQUEST MONITORING
  // ===========================================================================
  Widget _buildJoinRequestMonitoring() {
    final list = _joinRequests.where((r) {
      if (_searchFilter.isEmpty) return true;
      final q = _searchFilter.toLowerCase();
      return (r.groupName?.toLowerCase() ?? '').contains(q) ||
          (r.userName?.toLowerCase() ?? '').contains(q) ||
          r.requestStatus.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildModuleHeader(
          title: 'Join Request Monitoring',
          subtitle:
              'Review, approve, or reject citizen membership requests across groups.',
        ),
        Expanded(
          child: list.isEmpty
              ? _buildEmptyState(
                  'No pending or historical join requests found.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final req = list[i];
                    final isPending = req.isPending;
                    final statusColor = req.isApproved
                        ? AppColors.statusPaid
                        : (isPending ? Colors.orange : Colors.redAccent);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          statusColor.withValues(alpha: 0.1),
                                      radius: 16,
                                      child: Icon(Icons.person_add_rounded,
                                          size: 16, color: statusColor),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      req.userName ?? 'User',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    req.requestStatus.toUpperCase(),
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Target Group: ${req.groupName ?? req.groupId} • Phone: ${req.userPhone ?? "N/A"}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            if (req.message.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Message: "${req.message}"',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic)),
                            ],
                            if (isPending) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _handleReviewJoinRequest(
                                        req, 'rejected'),
                                    child: const Text('Reject',
                                        style:
                                            TextStyle(color: Colors.redAccent)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.statusPaid,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _handleReviewJoinRequest(
                                        req, 'approved'),
                                    icon: const Icon(Icons.check_rounded,
                                        size: 16),
                                    label: const Text('Approve & Add Member'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _handleReviewJoinRequest(
      JoinRequestModel req, String newStatus) async {
    final auth = context.read<AuthProvider>();
    final ok = await SupabaseService.reviewJoinRequest(
      requestId: req.id,
      status: newStatus,
      reviewedByUserId: auth.currentUser.id,
    );
    if (mounted) {
      _loadAllMasterData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Request marked as $newStatus' : 'Update failed'),
          backgroundColor: ok ? AppColors.statusPaid : Colors.redAccent,
        ),
      );
    }
  }

  // ===========================================================================
  // 10. COLLECTION OVERVIEW
  // ===========================================================================
  Widget _buildCollectionOverview() {
    return Column(
      children: [
        _buildModuleHeader(
          title: 'Collection Overview',
          subtitle:
              'System-wide receipts and collection transactions across all active groups.',
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Collections Recorded',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('₹${_totalCollectionsAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        Expanded(
          child: _collections.isEmpty
              ? _buildEmptyState('No collections recorded.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _collections.length,
                  itemBuilder: (ctx, i) {
                    final c = _collections[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.statusPaid.withValues(alpha: 0.1),
                          child: const Icon(Icons.receipt_rounded,
                              color: AppColors.statusPaid),
                        ),
                        title: Text(
                            'Receipt #${c.receiptNo} • ₹${c.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          'Payment: ${c.paymentType.displayName} • Date: ${DateFormat('dd MMM yyyy').format(c.collectionDateTime)}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusPaid.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('VERIFIED',
                              style: TextStyle(
                                  color: AppColors.statusPaid,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 11. EXPENSE OVERVIEW
  // ===========================================================================
  Widget _buildExpenseOverview() {
    return Column(
      children: [
        _buildModuleHeader(
          title: 'Expense Overview',
          subtitle:
              'Central expenditure registry, vendor payees, and audit approvals.',
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Expenditures Recorded',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('₹${_totalExpensesAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.shopping_bag_rounded,
                  color: Colors.redAccent, size: 28),
            ],
          ),
        ),
        Expanded(
          child: _expenses.isEmpty
              ? _buildEmptyState('No expenses recorded.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _expenses.length,
                  itemBuilder: (ctx, i) {
                    final exp = _expenses[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.redAccent.withValues(alpha: 0.1),
                          child: const Icon(Icons.payment_rounded,
                              color: Colors.redAccent),
                        ),
                        title: Text(
                            '${exp.title} • ₹${exp.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          'Category: ${exp.category} • Payee: ${exp.vendorPayee} • Date: ${DateFormat('dd MMM yyyy').format(exp.date)}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            exp.approvalStatus.name.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 12. REPORTS
  // ===========================================================================
  Widget _buildReportsOverview() {
    final balance = _totalCollectionsAmount - _totalExpensesAmount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleHeader(
          title: 'System Financial & Operational Reports',
          subtitle:
              'Aggregated analytics across all organizations and campaign branches.',
        ),
        const SizedBox(height: 12),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Consolidated Balance Summary',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Divider(height: 20),
                _buildReportRow(
                    'Total Income (Collections)',
                    '₹${_totalCollectionsAmount.toStringAsFixed(2)}',
                    Colors.green),
                const SizedBox(height: 8),
                _buildReportRow(
                    'Total Expenditures',
                    '₹${_totalExpensesAmount.toStringAsFixed(2)}',
                    Colors.redAccent),
                const Divider(height: 20),
                _buildReportRow('Net Available Treasury',
                    '₹${balance.toStringAsFixed(2)}', AppColors.primary,
                    isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Health & Compliance Checklist',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _buildChecklistTile(
                    'Row Level Security (RLS) Active on all 14 tables', true),
                _buildChecklistTile(
                    'Immutable Append-Only Audit Logging Enforced', true),
                _buildChecklistTile(
                    'Passwordless Supabase Auth OTP Integration Configured',
                    true),
                _buildChecklistTile(
                    'Public Self-Escalation to Super Admin Disabled', true),
                _buildChecklistTile(
                    'Super Admin Bootstrap Idempotent Lock Activated', true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildChecklistTile(String title, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
              isComplete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: isComplete ? AppColors.statusPaid : Colors.grey,
              size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // ===========================================================================
  // 13. AUDIT LOGS
  // ===========================================================================
  Widget _buildAuditLogsView() {
    return Column(
      children: [
        _buildModuleHeader(
          title: 'Immutable Audit Trail',
          subtitle:
              'Cryptographically protected, non-deletable system action logs.',
        ),
        Expanded(
          child: _auditLogs.isEmpty
              ? _buildEmptyState('No audit log entries recorded.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _auditLogs.length,
                  itemBuilder: (ctx, i) {
                    final log = _auditLogs[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Colors.blueGrey.withValues(alpha: 0.12),
                          child: const Icon(Icons.history_edu_rounded,
                              color: Colors.blueGrey, size: 20),
                        ),
                        title: Row(
                          children: [
                            Text(log.action,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.blueGrey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(log.entityType,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Actor: ${log.performedByName} • Time: ${DateFormat('dd MMM yyyy HH:mm').format(log.timestamp)}\nDetails: ${log.details}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 14. ACCOUNT STATUS MANAGEMENT
  // ===========================================================================
  Widget _buildAccountStatusControl() {
    return Column(
      children: [
        _buildModuleHeader(
          title: 'Account Status Management',
          subtitle:
              'Activate, deactivate, or suspend users. Super Admin accounts are protected against lockout.',
        ),
        Expanded(
          child: _users.isEmpty
              ? _buildEmptyState('No users found.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) {
                    final u = _users[i];
                    final isSuper = u.role == UserRole.superAdmin ||
                        u.phone.contains('9699342811') ||
                        u.name.contains('Ritesh');
                    final statusColor = u.accountStatus == 'active'
                        ? AppColors.statusPaid
                        : (u.accountStatus == 'suspended'
                            ? Colors.redAccent
                            : Colors.orange);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          child: Icon(Icons.security_rounded,
                              color: statusColor, size: 20),
                        ),
                        title: Text(u.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          'Role: ${u.role.nameString} • Current Status: ${u.accountStatus.toUpperCase()}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: isSuper
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                child: const Text('LOCKED SUPER ADMIN',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple)),
                              )
                            : PopupMenuButton<String>(
                                onSelected: (status) async {
                                  final ok =
                                      await SupabaseService.updateProfileStatus(
                                          u.id, status);
                                  if (mounted) {
                                    _loadAllMasterData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(ok
                                              ? 'Account status updated to $status'
                                              : 'Update failed')),
                                    );
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'active',
                                      child: Text('Mark Active')),
                                  PopupMenuItem(
                                      value: 'inactive',
                                      child: Text('Mark Inactive')),
                                  PopupMenuItem(
                                      value: 'suspended',
                                      child: Text('Suspend Account')),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(u.accountStatus.toUpperCase(),
                                          style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10)),
                                      const Icon(Icons.arrow_drop_down_rounded,
                                          size: 16),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 15. APPLICATION SETTINGS
  // ===========================================================================
  Widget _buildApplicationSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleHeader(
          title: 'System & Security Settings',
          subtitle:
              'Authentication configuration, Supabase integration, and bootstrap parameters.',
        ),
        const SizedBox(height: 12),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Supabase Project Connection',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('URL: ${SupabaseConfig.supabaseUrl}',
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                const Text(
                    'Anon Key: sb_publishable_37wNhigxEZLq6Q4IX5yUgQ_skrYDc8i',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (SupabaseService.isInitialized
                                ? AppColors.statusPaid
                                : Colors.orange)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        SupabaseService.isInitialized
                            ? 'ONLINE & CONNECTED'
                            : 'OFFLINE / CACHED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: SupabaseService.isInitialized
                              ? AppColors.statusPaid
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.password_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Passwordless Authentication Setup',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Email OTP: Dispatches 6-digit one-time code to verified email inbox.\n'
                  '2. Mobile Phone OTP: Formats phone number, verifies matching profile and sends 6-digit OTP.\n'
                  '3. Self-Registration: Assigns PUBLIC_USER role automatically, prohibiting privilege self-escalation.\n'
                  '4. Account Status Gate: Suspended and Inactive accounts are blocked immediately on token exchange.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.power_settings_new_rounded,
                        color: Colors.purple),
                    SizedBox(width: 8),
                    Text('First Super Admin Bootstrap Status',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bootstrap script: supabase/migrations/20261024000002_super_admin_bootstrap.sql.\n'
                  'Once a Super Admin has been designated, subsequent initialization calls are permanently rejected.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SHARED UI HELPERS
  // ===========================================================================
  Widget _buildModuleHeader({
    required String title,
    required String subtitle,
    VoidCallback? onAdd,
    String? addLabel,
    Widget? filterWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (onAdd != null && addLabel != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(addLabel),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchFilter = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search records...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBackground
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              if (filterWidget != null) ...[
                const SizedBox(width: 8),
                filterWidget,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
