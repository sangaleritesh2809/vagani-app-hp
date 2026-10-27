import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_theme_provider.dart';
import 'providers/vargani_data_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/group_selection_screen.dart';
import 'ui/screens/main_navigation_shell.dart';
import 'ui/screens/super_admin/super_admin_screen.dart';
import 'ui/screens/auth/organization_selection_screen.dart';
import 'ui/screens/groups/group_search_screen.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  final authProvider = AuthProvider();
  await authProvider.initStorage(); // Restore active session BEFORE initial frame
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageThemeProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => VarganiDataProvider()),
      ],
      child: const VarganiApp(),
    ),
  );
}

class VarganiApp extends StatelessWidget {
  const VarganiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langTheme = context.watch<LanguageThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Vargani Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: langTheme.themeMode,
      locale: Locale(langTheme.languageCode),
      supportedLocales: const [
        Locale('mr', 'IN'),
        Locale('en', 'US'),
        Locale('hi', 'IN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _resolveHomeScreen(auth),
    );
  }

  Widget _resolveHomeScreen(AuthProvider auth) {
    // If auth is still initializing, do not show login screen
    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Guard: Inactive or suspended accounts are blocked
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
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 1. SUPER_ADMIN -> Navigate to Organization Selection if needed, else Super Admin Dashboard
    if (auth.isSuperAdmin) {
      if (auth.needsOrganizationSelection) {
        return const OrganizationSelectionScreen();
      }
      return const SuperAdminScreen();
    }

    // 2. PUBLIC_USER -> Navigate to Group Search & Join Requests if not yet in a group
    if (auth.isPublicUser && auth.selectedGroup == null && auth.authorizedGroups.isEmpty) {
      return const GroupSearchScreen();
    }

    // 3. Default Authenticated App Shell (Dashboard)
    // Note: User lands directly on Dashboard and selects a Group manually when required
    return const MainNavigationShell();
  }
}
