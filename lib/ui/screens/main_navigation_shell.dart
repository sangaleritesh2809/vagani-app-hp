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

    final currentScreen = isCitizen
        ? citizenScreens[_citizenIndex.clamp(0, citizenScreens.length - 1)]
        : _getStaffScreen(_staffDestination, auth);

    final staffBottomIndex =
        _staffBottomDestinations.indexOf(_staffDestination);
    final safeStaffBottomIndex = staffBottomIndex >= 0 ? staffBottomIndex : 0;

    final staffRailIndex = _staffRailDestinations.indexOf(_staffDestination);
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
        actions: [
          // Active Group Selector / Manual Selection (Dashboard -> User manually selects a Group when required)
          if (!isCitizen) ...[
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GroupSelectionScreen()),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups_rounded,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      auth.selectedGroup != null
                          ? auth.selectedGroup!.code
                          : 'Select Group',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          // Language Switcher in AppBar (Marathi / English / Hindi)
          PopupMenuButton<String>(
            tooltip: lang.tr('language'),
            offset: const Offset(0, 45),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    langTheme.languageCode == 'mr'
                        ? 'MR'
                        : (langTheme.languageCode == 'hi' ? 'HI' : 'EN'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded,
                      size: 16, color: AppColors.primary),
                ],
              ),
            ),
            onSelected: (String code) => langTheme.setLanguage(code),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🌐 English'),
                    if (langTheme.languageCode == 'en') ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mr',
                child: Row(
                  children: [
                    const Text('🚩 Marathi'),
                    if (langTheme.languageCode == 'mr') ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Row(
                  children: [
                    const Text('🇮🇳 Hindi'),
                    if (langTheme.languageCode == 'hi') ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),

          // Quick Transparency Portal shortcut for staff
          if (!isCitizen)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                          title:
                              const Text('Public Transparency Portal Preview')),
                      body: const PublicTransparencyView(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_rounded,
                  size: 16, color: AppColors.primary),
              label: const Text('Public View',
                  style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(context, auth, data, langTheme, isDark),
      body: Column(
        children: [
          const RoleSwitchHeader(),
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
                              _staffDestination = _staffRailDestinations[index];
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
                            : _buildStaffRailDestinations(lang),
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
                    _staffDestination = _staffBottomDestinations[index];
                  }
                });
              },
              items: isCitizen
                  ? _buildCitizenBottomNav(lang)
                  : _buildStaffBottomNav(lang),
            ),
    );
  }

  List<NavigationRailDestination> _buildStaffRailDestinations(dynamic lang) {
    return [
      NavigationRailDestination(
          icon: const Icon(Icons.dashboard_rounded),
          label: Text(lang.tr('dashboard'))),
      NavigationRailDestination(
          icon: const Icon(Icons.home_work_rounded),
          label: Text(lang.tr('households'))),
      NavigationRailDestination(
          icon: const Icon(Icons.receipt_long_rounded),
          label: Text(lang.tr('receipts'))),
      NavigationRailDestination(
          icon: const Icon(Icons.currency_exchange_rounded),
          label: Text(lang.tr('handover'))),
      NavigationRailDestination(
          icon: const Icon(Icons.receipt_rounded),
          label: Text(lang.tr('expenses'))),
      NavigationRailDestination(
          icon: const Icon(Icons.support_agent_rounded),
          label: Text(lang.tr('complaints'))),
      NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_rounded),
          label: Text(lang.tr('reportsShort'))),
      NavigationRailDestination(
          icon: const Icon(Icons.festival_rounded),
          label: Text(lang.tr('campaigns'))),
      NavigationRailDestination(
          icon: const Icon(Icons.settings_rounded),
          label: Text(lang.tr('settings'))),
    ];
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

  List<ResponsiveBottomNavItem> _buildStaffBottomNav(dynamic lang) {
    return [
      ResponsiveBottomNavItem(
        icon: Icons.dashboard_rounded,
        label: lang.tr('dashboard'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.home_work_rounded,
        label: lang.tr('households'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.receipt_long_rounded,
        label: lang.tr('receipts'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.currency_exchange_rounded,
        label: lang.tr('handover'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.receipt_rounded,
        label: lang.tr('expenses'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.bar_chart_rounded,
        label: lang.tr('reportsShort'),
      ),
      ResponsiveBottomNavItem(
        icon: Icons.settings_rounded,
        label: lang.tr('settings'),
      ),
    ];
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
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user.name.isNotEmpty
                    ? user.name.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            otherAccountsPictures: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/images/app_logo_small.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
            accountName: Text(
              user.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.phone.isNotEmpty)
                  Text(
                    user.phone,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                if (user.email.isNotEmpty)
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
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
