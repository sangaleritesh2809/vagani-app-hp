import 'package:flutter/material.dart';
import '../../providers/auth_provider.dart';
import '../../ui/screens/auth/group_selection_screen.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/organization_selection_screen.dart';
import '../../ui/screens/main_navigation_shell.dart';
import '../../ui/screens/super_admin/super_admin_screen.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigate immediately to LoginScreen, clearing entire route history
  static void navigateToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Resolve the correct destination screen based on auth state
  static Widget getHomeScreen(AuthProvider auth) {
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    if (auth.currentUser.isSuspended || auth.currentUser.isInactive) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_rounded, size: 54, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Account Inactive or Suspended',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account has been deactivated per organization policies. Please contact your administrator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    auth.logout();
                    navigateToLogin();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (auth.isSuperAdmin) {
      if (auth.needsOrganizationSelection) {
        return const OrganizationSelectionScreen();
      }
      return const SuperAdminScreen();
    }

    if (auth.needsGroupSelection) {
      return const GroupSelectionScreen();
    }

    return const MainNavigationShell();
  }

  /// Navigate immediately to the home screen based on auth state, clearing route history
  static void navigateToHome(AuthProvider auth) {
    final screen = getHomeScreen(auth);
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
