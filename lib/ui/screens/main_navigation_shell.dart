import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_theme_provider.dart';
import '../../providers/vargani_data_provider.dart';
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

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<VarganiDataProvider>();
    final lang = context.watch<LanguageThemeProvider>().localizations;
    final isCitizen = auth.isCitizen;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define items for Staff vs Citizen
    final List<Widget> staffScreens = [
      const DashboardScreen(),
      const HouseholdListScreen(),
      const ReceiptsScreen(),
      const CashHandoverScreen(),
      const ExpenseListScreen(),
      const ComplaintListScreen(),
      const FinancialReportsScreen(),
      const CampaignListScreen(),
      const SettingsScreen(),
    ];

    final List<Widget> citizenScreens = [
      const PublicTransparencyView(),
      const ReceiptsScreen(),
      const ComplaintListScreen(),
      const SettingsScreen(),
    ];

    final activeScreens = isCitizen ? citizenScreens : staffScreens;
    final safeIndex = _selectedIndex >= activeScreens.length ? 0 : _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.tr('appName'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  data.organization.name,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Quick Transparency Portal shortcut for staff
          if (!isCitizen)
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Public Transparency Portal Preview')),
                      body: const PublicTransparencyView(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_rounded, size: 16, color: AppColors.primary),
              label: const Text('Public View', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const RoleSwitchHeader(),
          Expanded(
            child: Row(
              children: [
                // If Wide Screen (Desktop / Tablet / Web) show NavigationRail
                if (isWide)
                  NavigationRail(
                    selectedIndex: safeIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                    indicatorColor: AppColors.primary.withValues(alpha: 0.15),
                    selectedIconTheme: const IconThemeData(color: AppColors.primary),
                    unselectedIconTheme: const IconThemeData(color: Colors.grey),
                    selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
                    unselectedLabelTextStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                    destinations: isCitizen ? _buildCitizenRailDestinations(lang) : _buildStaffRailDestinations(lang),
                  ),
                Expanded(
                  child: activeScreens[safeIndex],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: safeIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: isCitizen ? _buildCitizenBottomNav(lang) : _buildStaffBottomNav(lang),
            ),
    );
  }

  List<NavigationRailDestination> _buildStaffRailDestinations(dynamic lang) {
    return [
      NavigationRailDestination(icon: const Icon(Icons.dashboard_rounded), label: Text(lang.tr('dashboard'))),
      NavigationRailDestination(icon: const Icon(Icons.home_work_rounded), label: Text(lang.tr('households'))),
      NavigationRailDestination(icon: const Icon(Icons.receipt_long_rounded), label: Text(lang.tr('receipts'))),
      NavigationRailDestination(icon: const Icon(Icons.currency_exchange_rounded), label: Text(lang.tr('handovers'))),
      NavigationRailDestination(icon: const Icon(Icons.receipt_rounded), label: Text(lang.tr('expenses'))),
      NavigationRailDestination(icon: const Icon(Icons.support_agent_rounded), label: Text(lang.tr('complaints'))),
      NavigationRailDestination(icon: const Icon(Icons.bar_chart_rounded), label: Text(lang.tr('reports'))),
      NavigationRailDestination(icon: const Icon(Icons.festival_rounded), label: Text(lang.tr('campaigns'))),
      NavigationRailDestination(icon: const Icon(Icons.settings_rounded), label: Text(lang.tr('settings'))),
    ];
  }

  List<NavigationRailDestination> _buildCitizenRailDestinations(dynamic lang) {
    return [
      NavigationRailDestination(icon: const Icon(Icons.verified_user_rounded), label: Text(lang.tr('transparency'))),
      NavigationRailDestination(icon: const Icon(Icons.receipt_long_rounded), label: Text(lang.tr('receipts'))),
      NavigationRailDestination(icon: const Icon(Icons.support_agent_rounded), label: Text(lang.tr('complaints'))),
      NavigationRailDestination(icon: const Icon(Icons.settings_rounded), label: Text(lang.tr('settings'))),
    ];
  }

  List<NavigationDestination> _buildStaffBottomNav(dynamic lang) {
    return [
      NavigationDestination(icon: const Icon(Icons.dashboard_rounded), label: lang.tr('dashboard')),
      NavigationDestination(icon: const Icon(Icons.home_work_rounded), label: lang.tr('households')),
      NavigationDestination(icon: const Icon(Icons.receipt_long_rounded), label: lang.tr('receipts')),
      NavigationDestination(icon: const Icon(Icons.currency_exchange_rounded), label: 'Handover'),
      NavigationDestination(icon: const Icon(Icons.receipt_rounded), label: lang.tr('expenses')),
      NavigationDestination(icon: const Icon(Icons.bar_chart_rounded), label: 'Reports'),
      NavigationDestination(icon: const Icon(Icons.settings_rounded), label: lang.tr('settings')),
    ];
  }

  List<NavigationDestination> _buildCitizenBottomNav(dynamic lang) {
    return [
      NavigationDestination(icon: const Icon(Icons.verified_user_rounded), label: lang.tr('transparency')),
      NavigationDestination(icon: const Icon(Icons.receipt_long_rounded), label: lang.tr('receipts')),
      NavigationDestination(icon: const Icon(Icons.support_agent_rounded), label: lang.tr('complaints')),
      NavigationDestination(icon: const Icon(Icons.settings_rounded), label: lang.tr('settings')),
    ];
  }
}
