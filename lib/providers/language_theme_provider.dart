import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/localization/app_localizations.dart';

class LanguageThemeProvider extends ChangeNotifier {
  static const String _prefLangKey = 'vargani_language_code';
  static const String _prefNumeralsKey = 'vargani_marathi_numerals';
  static const String _prefThemeKey = 'vargani_theme_mode';

  // Primary language is English ('en') by default
  String _languageCode = 'en';
  bool _useMarathiNumerals = false;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  String get languageCode => _languageCode;
  bool get useMarathiNumerals => _useMarathiNumerals;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isMarathi => _languageCode == 'mr';
  bool get isHindi => _languageCode == 'hi';
  bool get isEnglish => _languageCode == 'en';
  bool get isInitialized => _isInitialized;

  AppLocalizations get localizations => AppLocalizations(
        _languageCode,
        useMarathiNumerals: _useMarathiNumerals,
      );

  LanguageThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefLangKey);
      if (savedLang != null &&
          (savedLang == 'mr' || savedLang == 'en' || savedLang == 'hi')) {
        _languageCode = savedLang;
      } else {
        _languageCode = 'en'; // English primary default
      }

      _useMarathiNumerals = prefs.getBool(_prefNumeralsKey) ?? false;

      final savedTheme = prefs.getString(_prefThemeKey);
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.light;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != 'mr' && code != 'en' && code != 'hi') return;
    if (_languageCode != code) {
      _languageCode = code;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefLangKey, code);
      } catch (_) {}
    }
  }

  Future<void> setUseMarathiNumerals(bool value) async {
    if (_useMarathiNumerals != value) {
      _useMarathiNumerals = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefNumeralsKey, value);
      } catch (_) {}
    }
  }

  Future<void> toggleLanguage() async {
    // Cycle: mr -> en -> hi -> mr
    if (_languageCode == 'mr') {
      await setLanguage('en');
    } else if (_languageCode == 'en') {
      await setLanguage('hi');
    } else {
      await setLanguage('mr');
    }
  }

  Future<void> toggleTheme() async {
    final newMode =
        (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefThemeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  // Formatting helpers
  String tr(String key) => localizations.tr(key);
  String formatDate(DateTime date) => localizations.formatDate(date);
  String formatNumber(dynamic number) => localizations.formatNumber(number);
  String formatCurrency(num amount) => localizations.formatCurrency(amount);
}
