import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_theme_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/vargani_data_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'core/navigation/app_navigator.dart';
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
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
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
      title: 'Vargani Collection',
      navigatorKey: AppNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: langTheme.themeMode,
      locale: Locale(langTheme.languageCode),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('mr', 'IN'),
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

    return AppNavigator.getHomeScreen(auth);
  }
}
