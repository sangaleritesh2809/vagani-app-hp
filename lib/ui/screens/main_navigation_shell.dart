import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_theme_provider.dart';
import '../../providers/vargani_data_provider.dart';
import '../widgets/responsive_bottom_nav_bar.dart';
import '../widgets/role_switch_header.dart';
import 'dashboard/dashboard_screen.dart';
import 'dashboard/public_transparency_view.dart';
import 'households/household_list_screen.dart';
import 'collections/receipts_screen.dart';
import 'handovers/cash_handover_screen.dart';
import 'expenses/expense_list_screen.dart';
import 'complaints/complaint_list_screen.dart';
import 'reports/financial_reports_screen.dart';
import 'campaigns/campaign_list_screen.dart';
import 'settings/settings_screen.dart';
import 'auth/group_selection_screen.dart';
import 'profile/user_profile_dialog.dart';
import 'profile/user_profile_screen.dart';
import 'super_admin/super_admin_screen.dart';
import 'groups/group_search_screen.dart';
import '../../core/navigation/app_navigator.dart';

enum StaffDestination {
  dashboard,
  households,
  receipts,
  handover,
  expenses,
  complaints,
  reports,
  campaigns,
  settings,
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  StaffDestination _staffDestination = StaffDestination.dashboard;
  int _citizenIndex = 0;
  bool _lastWasCitizen = false;

  // The 7 primary bottom navigation destinations for staff
  static const List<StaffDestination> _staffBottomDestinations = [
    StaffDestination.dashboard,
    StaffDestination.households,
    StaffDestination.receipts,
    StaffDestination.handover,
    StaffDestination.expenses,
    StaffDestination.reports,
    StaffDestination.settings,
  ];

  // All 9 destinations available on wide desktop/tablet NavigationRail
  static const List<StaffDestination> _staffRailDestinations = [
    StaffDestination.dashboard,
    StaffDestination.households,
    StaffDestination.receipts,
    StaffDestination.handover,
    StaffDestination.expenses,
    StaffDestination.complaints,
    StaffDestination.reports,
    StaffDestination.campaigns,
    StaffDestination.settings,
  ];

  bool _hasStaffDestinationAccess(
      StaffDestination destination, AuthProvider auth) {
    switch (destination) {
      case StaffDestination.dashboard:
        return true;
      case StaffDestination.households:
        return auth.hasPermission('households.view');
      case StaffDestination.receipts:
        return auth.hasPermission('collections.view');
      case StaffDestination.handover:
        return auth.hasPermission('handovers.view');
      case StaffDestination.expenses:
        return auth.hasPermission('expenses.view');
      case StaffDestination.complaints:
        return auth.hasPermission('complaints.view');
      case StaffDestination.reports:
        return auth.hasPermission('reports.view');
      case StaffDestination.campaigns:
        return auth.hasPermission('campaigns.view');
      case StaffDestination.settings:
        return true;
    }
  }

  List<StaffDestination> _getVisibleStaffBottomDestinations(AuthProvider auth) {
    return _staffBottomDestinations
        .where((d) => _hasStaffDestinationAccess(d, auth))
        .toList();
  }

  List<StaffDestination> _getVisibleStaffRailDestinations(AuthProvider auth) {
    return _staffRailDestinations
        .where((d) => _hasStaffDestinationAccess(d, auth))
        .toList();
  }

  Widget _getStaffScreen(StaffDestination destination, AuthProvider auth) {
    // PBAC Check for Screen Access (Requirement 4)
    bool hasAccess = true;
    String requiredPerm = '';

    switch (destination) {
      case StaffDestination.dashboard:
        return const DashboardScreen();
      case StaffDestination.households:
        hasAccess = auth.hasPermission('households.view');
        requiredPerm = 'households.view';
        if (hasAccess) return const HouseholdListScreen();
        break;
      case StaffDestination.receipts:
        hasAccess = auth.hasPermission('collections.view');
        requiredPerm = 'collections.view';
        if (hasAccess) return const ReceiptsScreen();
        break;
      case StaffDestination.handover:
        hasAccess = auth.hasPermission('handovers.view');
        requiredPerm = 'handovers.view';
        if (hasAccess) return const CashHandoverScreen();
        break;
      case StaffDestination.expenses:
        hasAccess = auth.hasPermission('expenses.view');
        requiredPerm = 'expenses.view';
        if (hasAccess) return const ExpenseListScreen();
        break;
      case StaffDestination.complaints:
        hasAccess = auth.hasPermission('complaints.view');
        requiredPerm = 'complaints.view';
        if (hasAccess) return const ComplaintListScreen();
        break;
      case StaffDestination.reports:
        hasAccess = auth.hasPermission('reports.view');
        requiredPerm = 'reports.view';
        if (hasAccess) return const FinancialReportsScreen();
        break;
      case StaffDestination.campaigns:
        hasAccess = auth.hasPermission('campaigns.view');
        requiredPerm = 'campaigns.view';
        if (hasAccess) return const CampaignListScreen();
        break;
      case StaffDestination.settings:
        return const SettingsScreen();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  size: 48, color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Restricted',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Your role (${auth.currentRole.nameString}) does not have permission to view this section.\nRequired permission: $requiredPerm',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<VarganiDataProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final lang = langTheme.localizations;
    final isCitizen = auth.isCitizen;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reset navigation index if switching between Staff and Citizen roles
    if (isCitizen != _lastWasCitizen) {
      _lastWasCitizen = isCitizen;
      _citizenIndex = 0;
      _staffDestination = StaffDestination.dashboard;
    }

    final List<Widget> citizenScreens = [
      const PublicTransparencyView(),
      const ReceiptsScreen(),
      const ComplaintListScreen(),
      const SettingsScreen(),
    ];

    final visibleStaffBottom = _getVisibleStaffBottomDestinations(auth);
    final visibleStaffRail = _getVisibleStaffRailDestinations(auth);

    if (!_hasStaffDestinationAccess(_staffDestination, auth)) {
      _staffDestination = visibleStaffBottom.isNotEmpty
          ? visibleStaffBottom.first
          : StaffDestination.dashboard;
    }

    final currentScreen = isCitizen
        ? citizenScreens[_citizenIndex.clamp(0, citizenScreens.length - 1)]
        : _getStaffScreen(_staffDestination, auth);

    final staffBottomIndex =
        visibleStaffBottom.indexOf(_staffDestination);
    final safeStaffBottomIndex = staffBottomIndex >= 0 ? staffBottomIndex : 0;

    final staffRailIndex = visibleStaffRail.indexOf(_staffDestination);
    final safeStaffRailIndex = staffRailIndex >= 0 ? staffRailIndex : 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/app_logo_small.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.tr('appName'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data.organization.name,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

      ),
      drawer: _buildDrawer(context, auth, data, langTheme, isDark),
      body: Column(
        children: [
          if (data.hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade800,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => data.initDataFromBackend(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Retry',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                // If Wide Screen (Desktop / Tablet / Web) show NavigationRail
                if (isWide)
                  SingleChildScrollView(
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex:
                            isCitizen ? _citizenIndex : safeStaffRailIndex,
                        onDestinationSelected: (index) {
                          setState(() {
                            if (isCitizen) {
                              _citizenIndex = index;
                            } else {
                              _staffDestination = visibleStaffRail[index];
                            }
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        backgroundColor:
                            isDark ? AppColors.darkSurface : Colors.white,
                        indicatorColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        selectedIconTheme:
                            const IconThemeData(color: AppColors.primary),
                        unselectedIconTheme:
                            const IconThemeData(color: Colors.grey),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        unselectedLabelTextStyle:
                            const TextStyle(color: Colors.grey, fontSize: 11),
                        destinations: isCitizen
                            ? _buildCitizenRailDestinations(lang)
                            : visibleStaffRail
                                .map((d) => _buildStaffRailDestination(d, lang))
                                .toList(),
                      ),
                    ),
                  ),
                Expanded(
                  child: currentScreen,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : ResponsiveBottomNavBar(
              selectedIndex: isCitizen ? _citizenIndex : safeStaffBottomIndex,
              onItemSelected: (index) {
                setState(() {
                  if (isCitizen) {
                    _citizenIndex = index;
                  } else {
                    _staffDestination = visibleStaffBottom[index];
                  }
                });
              },
              items: isCitizen
                  ? _buildCitizenBottomNav(lang)
                  : visibleStaffBottom
                      .map((d) => _buildStaffBottomNavItem(d, lang))
                      .toList(),
            ),
    );
  }

  NavigationRailDestination _buildStaffRailDestination(
      StaffDestination dest, dynamic lang) {
    switch (dest) {
      case StaffDestination.dashboard:
        return NavigationRailDestination(
          icon: const Icon(Icons.dashboard_rounded),
          label: Text(lang.tr('dashboard')),
        );
      case StaffDestination.households:
        return NavigationRailDestination(
          icon: const Icon(Icons.home_work_rounded),
          label: Text(lang.tr('households')),
        );
      case StaffDestination.receipts:
        return NavigationRailDestination(
          icon: const Icon(Icons.receipt_long_rounded),
          label: Text(lang.tr('receipts')),
        );
      case StaffDestination.handover:
        return NavigationRailDestination(
          icon: const Icon(Icons.currency_exchange_rounded),
          label: Text(lang.tr('handover')),
        );
      case StaffDestination.expenses:
        return NavigationRailDestination(
          icon: const Icon(Icons.receipt_rounded),
          label: Text(lang.tr('expenses')),
        );
      case StaffDestination.complaints:
        return NavigationRailDestination(
          icon: const Icon(Icons.support_agent_rounded),
          label: Text(lang.tr('complaints')),
        );
      case StaffDestination.reports:
        return NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_rounded),
          label: Text(lang.tr('reportsShort')),
        );
      case StaffDestination.campaigns:
        return NavigationRailDestination(
          icon: const Icon(Icons.festival_rounded),
          label: Text(lang.tr('campaigns')),
        );
      case StaffDestination.settings:
        return NavigationRailDestination(
          icon: const Icon(Icons.settings_rounded),
          label: Text(lang.tr('settings')),
        );
    }
  }

  List<NavigationRailDestination> _buildCitizenRailDestinations(dynamic lang) {
    return [
      NavigationRailDestination(
          icon: const Icon(Icons.verified_user_rounded),
          label: Text(lang.tr('transparency'))),
      NavigationRailDestination(
          icon: const Icon(Icons.receipt_long_rounded),
          label: Text(lang.tr('receipts'))),
      NavigationRailDestination(
          icon: const Icon(Icons.support_agent_rounded),
          label: Text(lang.tr('complaints'))),
      NavigationRailDestination(
          icon: const Icon(Icons.settings_rounded),
          label: Text(lang.tr('settings'))),
    ];
  }

  ResponsiveBottomNavItem _buildStaffBottomNavItem(
      StaffDestination dest, dynamic lang) {
    switch (dest) {
      case StaffDestination.dashboard:
        return ResponsiveBottomNavItem(
          icon: Icons.dashboard_rounded,
          label: lang.tr('dashboard'),
        );
      case StaffDestination.households:
        return ResponsiveBottomNavItem(
          icon: Icons.home_work_rounded,
          label: lang.tr('households'),
        );
      case StaffDestination.receipts:
        return ResponsiveBottomNavItem(
          icon: Icons.receipt_long_rounded,
          label: lang.tr('receipts'),
        );
      case StaffDestination.handover:
        return ResponsiveBottomNavItem(
          icon: Icons.currency_exchange_rounded,
          label: lang.tr('handover'),
        );
      case StaffDestination.expenses:
        return ResponsiveBottomNavItem(
          icon: Icons.receipt_rounded,
          label: lang.tr('expenses'),
        );
      case StaffDestination.complaints:
        return ResponsiveBottomNavItem(
          icon: Icons.support_agent_rounded,
          label: lang.tr('complaints'),
        );
      case StaffDestination.reports:
        return ResponsiveBottomNavItem(
          icon: Icons.bar_chart_rounded,
          label: lang.tr('reportsShort'),
        );
      case StaffDestination.campaigns:
        return ResponsiveBottomNavItem(
          icon: Icons.festival_rounded,
          label: lang.tr('campaigns'),
        );
      case StaffDestination.settings:
        return ResponsiveBottomNavItem(
          icon: Icons.settings_rounded,
          label: lang.tr('settings'),
        );
    }
  }

  List<ResponsiveBottomNavItem> _buildCitizenBottomNav(dynamic lang) {
    return [
      ResponsiveBottomNavItem(
        icon: Icons.verified_user_rounded,
        label: lang.tr('transparency'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.receipt_long_rounded,
        label: lang.tr('receipts'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.support_agent_rounded,
        label: lang.tr('complaints'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.settings_rounded,
        label: lang.tr('settings'),
      ),
    ];
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthProvider auth,
    VarganiDataProvider data,
    LanguageThemeProvider langTheme,
    bool isDark,
  ) {
    final user = auth.currentUser;
    final isMarathi = langTheme.isMarathi;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: Column(
        children: [
          // Drawer Header with User Profile info
          Container(
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 16, 16, 16),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.currentRole.nameString,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                      'assets/images/app_logo_small.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 1. My Profile
                ListTile(
                  leading: const Icon(Icons.person_rounded,
                      color: AppColors.primary),
                  title: Text(
                    isMarathi ? 'माझी प्रोफाईल' : 'User Profile',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isMarathi
                        ? 'नाव, मोबाईल व माहिती अपडेट करा'
                        : 'View & update personal details',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UserProfileScreen()),
                    );
                  },
                ),

                // 2. Find Groups / Mandals
                ListTile(
                  leading: const Icon(Icons.travel_explore_rounded,
                      color: AppColors.primary),
                  title: Text(
                    isMarathi ? 'मंडळ / ग्रुप शोधा' : 'Find Groups & Mandals',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    isMarathi
                        ? 'नोंदणीकृत मंडळे व मोहिमा शोधा'
                        : 'Search registered groups & mandals',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GroupSearchScreen()),
                    );
                  },
                ),

                const Divider(),

                // 3. Organization & Group Details Info Tile
                ListTile(
                  leading: const Icon(Icons.business_rounded,
                      color: Colors.blueGrey),
                  title: Text(
                    data.organization.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    auth.selectedGroup != null
                        ? auth.selectedGroup!.name
                        : (auth.isCitizen
                            ? 'Citizen Transparency Portal'
                            : 'Main Jurisdiction'),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),

                // 4. Super Admin Console (Only for super admins)
                if (auth.isSuperAdmin) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.purple),
                    title: const Text(
                      'Super Admin Console',
                      style: TextStyle(
                          color: Colors.purple, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Global organizations, roles & settings',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SuperAdminScreen()),
                      );
                    },
                  ),
                ],

                const Divider(),

                // 5. Language Selector Tile
                ListTile(
                  leading: const Icon(Icons.translate_rounded,
                      color: AppColors.primary),
                  title: Text(isMarathi ? 'भाषा बदला' : 'Language'),
                  trailing: DropdownButton<String>(
                    value: langTheme.languageCode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                      DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                    ],
                    onChanged: (val) {
                      if (val != null) langTheme.setLanguage(val);
                    },
                  ),
                ),

                // 6. Theme Toggle Tile
                SwitchListTile(
                  secondary: Icon(
                    langTheme.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: Colors.amber,
                  ),
                  title: Text(isMarathi ? 'डार्क मोड' : 'Dark Mode'),
                  value: langTheme.isDarkMode,
                  onChanged: (_) => langTheme.toggleTheme(),
                ),
              ],
            ),
          ),

          // Vargani Pro Branding Footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/app_logo_small.png', width: 18, height: 18),
                const SizedBox(width: 8),
                const Text(
                  'Vargani Pro • वर्गणी',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Sign Out Tile at Bottom of Drawer
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                isMarathi ? 'लॉगआउट करा' : 'Sign Out',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                auth.logout();
                AppNavigator.navigateToLogin();
              },
            ),
          ),
        ],
      ),
    );
  }
}
