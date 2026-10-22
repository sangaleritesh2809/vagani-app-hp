import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/language_theme_provider.dart';
import 'providers/vargani_data_provider.dart';
import 'ui/screens/main_navigation_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

    return MaterialApp(
      title: 'Vargani Pro (वर्गणी)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: langTheme.themeMode,
      home: const MainNavigationShell(),
    );
  }
}
