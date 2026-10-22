import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';

class LanguageThemeProvider extends ChangeNotifier {
  String _languageCode = 'en';
  ThemeMode _themeMode = ThemeMode.light;

  String get languageCode => _languageCode;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  AppLocalizations get localizations => AppLocalizations(_languageCode);

  void setLanguage(String code) {
    if (_languageCode != code) {
      _languageCode = code;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _languageCode = (_languageCode == 'en') ? 'mr' : 'en';
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
