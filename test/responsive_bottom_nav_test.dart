import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vargani_app/core/models/user_model.dart';
import 'package:vargani_app/providers/auth_provider.dart';
import 'package:vargani_app/providers/language_theme_provider.dart';
import 'package:vargani_app/providers/vargani_data_provider.dart';
import 'package:vargani_app/ui/screens/main_navigation_shell.dart';
import 'package:vargani_app/ui/screens/dashboard/dashboard_screen.dart';
import 'package:vargani_app/ui/screens/households/household_list_screen.dart';
import 'package:vargani_app/ui/screens/collections/receipts_screen.dart';
import 'package:vargani_app/ui/screens/handovers/cash_handover_screen.dart';
import 'package:vargani_app/ui/screens/expenses/expense_list_screen.dart';
import 'package:vargani_app/ui/screens/reports/financial_reports_screen.dart';
import 'package:vargani_app/ui/screens/settings/settings_screen.dart';
import 'package:vargani_app/ui/screens/dashboard/public_transparency_view.dart';
import 'package:vargani_app/ui/screens/complaints/complaint_list_screen.dart';
import 'package:vargani_app/ui/widgets/responsive_bottom_nav_bar.dart';

Widget _createTestApp({AuthProvider? authProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageThemeProvider()),
      ChangeNotifierProvider(create: (_) => authProvider ?? AuthProvider()),
      ChangeNotifierProvider(create: (_) => VarganiDataProvider()),
    ],
    child: const MaterialApp(
      home: MainNavigationShell(),
    ),
  );
}

void main() {
  group('ResponsiveBottomNavBar Isolated Tests', () {
    testWidgets(
        'Icon-only mode (showLabels: false) does not show text labels at bottom',
        (tester) async {
      int selectedIndex = 0;
      final items = [
        const ResponsiveBottomNavItem(
            icon: Icons.dashboard_rounded, label: 'Dashboard'),
        const ResponsiveBottomNavItem(
            icon: Icons.home_work_rounded, label: 'Households'),
        const ResponsiveBottomNavItem(
            icon: Icons.receipt_long_rounded, label: 'Receipts'),
        const ResponsiveBottomNavItem(
            icon: Icons.currency_exchange_rounded, label: 'Handover'),
        const ResponsiveBottomNavItem(
            icon: Icons.receipt_rounded, label: 'Expenses'),
        const ResponsiveBottomNavItem(
            icon: Icons.bar_chart_rounded, label: 'Reports'),
        const ResponsiveBottomNavItem(
            icon: Icons.settings_rounded, label: 'Settings'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return ResponsiveBottomNavBar(
                  selectedIndex: selectedIndex,
                  showLabels: false,
                  onItemSelected: (index) {
                    setState(() => selectedIndex = index);
                  },
                  items: items,
                );
              },
            ),
          ),
        ),
      );

      // Verify text labels are NOT shown at the bottom
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Households'), findsNothing);
      expect(find.text('Receipts'), findsNothing);
      expect(find.text('Handover'), findsNothing);
      expect(find.text('Expenses'), findsNothing);
      expect(find.text('Reports'), findsNothing);
      expect(find.text('Settings'), findsNothing);

      // Verify all 7 icons are visible
      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_work_rounded), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
      expect(find.byIcon(Icons.currency_exchange_rounded), findsOneWidget);
      expect(find.byIcon(Icons.receipt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

      // Tap 'Reports' icon
      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();
      expect(selectedIndex, 5);

      // Tap 'Settings' icon
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(selectedIndex, 6);
    });

    testWidgets('Renders all 7 items with showLabels: true when enabled',
        (tester) async {
      int selectedIndex = 0;
      final items = [
        const ResponsiveBottomNavItem(
            icon: Icons.dashboard_rounded, label: 'Dashboard'),
        const ResponsiveBottomNavItem(
            icon: Icons.home_work_rounded, label: 'Households'),
        const ResponsiveBottomNavItem(
            icon: Icons.receipt_long_rounded, label: 'Receipts'),
        const ResponsiveBottomNavItem(
            icon: Icons.currency_exchange_rounded, label: 'Handover'),
        const ResponsiveBottomNavItem(
            icon: Icons.receipt_rounded, label: 'Expenses'),
        const ResponsiveBottomNavItem(
            icon: Icons.bar_chart_rounded, label: 'Reports'),
        const ResponsiveBottomNavItem(
            icon: Icons.settings_rounded, label: 'Settings'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return ResponsiveBottomNavBar(
                  selectedIndex: selectedIndex,
                  showLabels: true,
                  onItemSelected: (index) =>
                      setState(() => selectedIndex = index),
                  items: items,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('MainNavigationShell Destination & Routing Tests', () {
    testWidgets(
        'Tapping each of the 7 staff navigation icons displays the correct screen',
        (tester) async {
      await tester.pumpWidget(_createTestApp());
      await tester.pumpAndSettle();

      // 1. Initially Dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);

      // 2. Tap Households icon
      await tester.tap(find.byIcon(Icons.home_work_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(HouseholdListScreen), findsOneWidget);

      // 3. Tap Receipts icon
      await tester.tap(find.byIcon(Icons.receipt_long_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiptsScreen), findsOneWidget);

      // 4. Tap Handover icon
      await tester.tap(find.byIcon(Icons.currency_exchange_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(CashHandoverScreen), findsOneWidget);

      // 5. Tap Expenses icon
      await tester.tap(find.byIcon(Icons.receipt_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseListScreen), findsOneWidget);

      // 6. Tap Reports icon -> Must open FinancialReportsScreen
      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(FinancialReportsScreen), findsOneWidget);
      expect(find.byType(ComplaintListScreen), findsNothing);

      // 7. Tap Settings icon -> Must open SettingsScreen
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Return to Dashboard
      await tester.tap(find.byIcon(Icons.dashboard_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Citizen mode navigates correctly with icons', (tester) async {
      final auth = AuthProvider();
      auth.switchRole(UserRole.citizen);

      await tester.pumpWidget(_createTestApp(authProvider: auth));
      await tester.pumpAndSettle();

      // Starts on Transparency
      expect(find.byType(PublicTransparencyView), findsOneWidget);

      // Tap Complaints icon
      await tester.tap(find.byIcon(Icons.support_agent_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ComplaintListScreen), findsOneWidget);
    });
  });
}
