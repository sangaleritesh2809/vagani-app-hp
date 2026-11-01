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

    if (data.activeGroup == null && auth.selectedGroup != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        data.setActiveGroup(auth.selectedGroup);
      });
    }

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
                    auth.selectedGroup != null
                        ? '${data.organization.name} • ${auth.selectedGroup!.name}'
                        : data.organization.name,
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
    final drawerWidth = (MediaQuery.of(context).size.width * 0.82).clamp(280.0, 320.0);

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 1. Modern Curved Gradient Drawer Header
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 16, 16, 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFFF7043), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name.substring(0, 1).toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            auth.currentRole.nameString,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
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

            // 2. Interactive Organization & Group Selector Card
            InkWell(
              onTap: () => _showGroupSelectionModal(
                  context, auth, data, langTheme, isDark),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBg
                      : AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organization Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.temple_hindu_rounded,
                              color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.organization.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isMarathi ? 'संस्था' : 'Org',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // Active Group Selector Pill
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMarathi ? 'सक्रिय ग्रुप / मंडळ:' : 'ACTIVE GROUP:',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.selectedGroup?.name ??
                                    (isMarathi ? 'ग्रुप निवडा' : 'Select Group'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isMarathi ? 'बदला' : 'Switch',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. Navigation Items & Settings
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 8, bottom: 4),
                    child: Text(
                      isMarathi ? 'खाते व मंडळ' : 'ACCOUNT & MANDAL',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),


                  // User Profile
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    iconColor: Colors.blue,
                    title: isMarathi ? 'माझी प्रोफाईल' : 'User Profile',
                    subtitle: isMarathi
                        ? 'नाव, मोबाईल व माहिती'
                        : 'View & update personal details',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserProfileScreen()),
                      );
                    },
                  ),

                  // Find Groups / Mandals
                  _buildDrawerItem(
                    icon: Icons.travel_explore_rounded,
                    iconColor: Colors.teal,
                    title: isMarathi ? 'मंडळ / ग्रुप शोधा' : 'Find Groups & Mandals',
                    subtitle: isMarathi
                        ? 'नोंदणीकृत मंडळे व मोहिमा'
                        : 'Search registered groups & mandals',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GroupSearchScreen()),
                      );
                    },
                  ),

                  // Super Admin Console (if super admin)
                  if (auth.isSuperAdmin)
                    _buildDrawerItem(
                      icon: Icons.admin_panel_settings_rounded,
                      iconColor: Colors.purple,
                      title: 'Super Admin Console',
                      subtitle: 'Global organizations & roles',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SuperAdminScreen()),
                        );
                      },
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Divider(height: 12),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                    child: Text(
                      isMarathi ? 'ॲप सेटिंग्ज' : 'PREFERENCES',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Language Tile
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.translate_rounded,
                            size: 18, color: Colors.orange),
                      ),
                      title: Text(
                        isMarathi ? 'भाषा' : 'Language',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardBg
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: langTheme.languageCode,
                          underline: const SizedBox(),
                          isDense: true,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
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
                    ),
                  ),

                  // Dark Mode Tile
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          langTheme.isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          size: 18,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      title: Text(
                        isMarathi ? 'डार्क मोड' : 'Dark Mode',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      trailing: Switch.adaptive(
                        value: langTheme.isDarkMode,
                        activeColor: AppColors.primary,
                        onChanged: (_) => langTheme.toggleTheme(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Vargani Pro Branding Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/app_logo_small.png',
                      width: 15, height: 15),
                  const SizedBox(width: 6),
                  const Text(
                    'Vargani Pro • वर्गणी v1.0',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),

            // 5. Modern Red Sign Out Button
            Container(
              margin: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.redAccent, size: 16),
                ),
                title: Text(
                  isMarathi ? 'लॉगआउट करा' : 'Sign Out',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.redAccent, size: 12),
                onTap: () {
                  Navigator.pop(context);
                  auth.logout();
                  AppNavigator.navigateToLogin();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showGroupSelectionModal(
    BuildContext context,
    AuthProvider auth,
    VarganiDataProvider data,
    LanguageThemeProvider langTheme,
    bool isDark,
  ) {
    final isMarathi = langTheme.isMarathi;
    final groups = auth.organizationGroups;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMarathi ? 'मंडळ / ग्रुप निवडा' : 'Select Group',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isMarathi ? "संस्था" : "Organization"}: ${data.organization.name}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (groups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      isMarathi
                          ? 'कोणतेही ग्रुप आढळले नाहीत.'
                          : 'No groups available in this organization.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final g = groups[index];
                      final isSelected = g.id == auth.selectedGroup?.id;

                      return InkWell(
                        onTap: () async {
                          Navigator.pop(ctx); // close modal
                          final res = await auth.selectGroup(g);
                          data.setActiveGroup(g);
                          await data.initDataFromBackend();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isMarathi
                                      ? 'सक्रिय ग्रुप बदलला: ${g.name}'
                                      : 'Switched to group: ${g.name}',
                                ),
                                backgroundColor: AppColors.statusPaid,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : (isDark ? AppColors.darkCardBg : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkSurface : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.groups_rounded,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      g.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected ? AppColors.primary : null,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${g.code}${g.location.isNotEmpty ? " • ${g.location}" : ""} • ₹${g.perPersonRate.toInt()}/व्यक्ती',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                )
                              else
                                Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: Colors.grey.shade400,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
