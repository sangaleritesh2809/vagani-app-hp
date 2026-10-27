import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vargani_app/core/localization/app_localizations.dart';
import 'package:vargani_app/providers/language_theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step 3: Multi-Language & Formatting Unit Tests', () {
    test('1. Marathi is primary language by default on first launch', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LanguageThemeProvider();
      // Allow async prefs to load
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.languageCode, equals('mr'));
      expect(provider.isMarathi, isTrue);
      expect(provider.isEnglish, isFalse);
      expect(provider.isHindi, isFalse);
    });

    test('2. Can switch between Marathi, English, and Hindi at any time',
        () async {
      final provider = LanguageThemeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Switch to English
      await provider.setLanguage('en');
      expect(provider.languageCode, equals('en'));
      expect(provider.isEnglish, isTrue);

      // Switch to Hindi
      await provider.setLanguage('hi');
      expect(provider.languageCode, equals('hi'));
      expect(provider.isHindi, isTrue);

      // Switch back to Marathi
      await provider.setLanguage('mr');
      expect(provider.languageCode, equals('mr'));
      expect(provider.isMarathi, isTrue);
    });

    test('3. Chosen language is persisted in SharedPreferences', () async {
      final provider = LanguageThemeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.setLanguage('hi');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vargani_language_code'), equals('hi'));

      // New instance should restore 'hi'
      final newProvider = LanguageThemeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(newProvider.languageCode, equals('hi'));
    });

    test('4. Date format is localized for Marathi, Hindi, and English', () {
      final testDate = DateTime(2026, 8, 15);

      final mrLoc = AppLocalizations('mr', useMarathiNumerals: false);
      expect(mrLoc.formatDate(testDate), equals('15 ऑगस्ट 2026'));

      final mrLocDevanagari = AppLocalizations('mr', useMarathiNumerals: true);
      expect(mrLocDevanagari.formatDate(testDate), equals('१५ ऑगस्ट २०२६'));

      final hiLoc = AppLocalizations('hi', useMarathiNumerals: false);
      expect(hiLoc.formatDate(testDate), equals('15 अगस्त 2026'));

      final enLoc = AppLocalizations('en');
      expect(enLoc.formatDate(testDate), equals('15 Aug 2026'));
    });

    test('5. Marathi numerals toggle converts numbers and currency', () {
      final locEnglishDigits =
          AppLocalizations('mr', useMarathiNumerals: false);
      expect(locEnglishDigits.formatNumber(1250), equals('1250'));
      expect(locEnglishDigits.formatCurrency(1500), equals('₹1500'));

      final locMarathiDigits = AppLocalizations('mr', useMarathiNumerals: true);
      expect(locMarathiDigits.formatNumber(1250), equals('१२५०'));
      expect(locMarathiDigits.formatCurrency(1500), equals('₹१५००'));
    });

    test('6. All primary keys exist across all 3 language dictionaries', () {
      final keysToCheck = [
        'appName',
        'dashboard',
        'households',
        'campaigns',
        'collections',
        'receipts',
        'handovers',
        'expenses',
        'complaints',
        'reports',
        'transparency',
        'settings',
        'expectedTotal',
        'verifiedReceived',
        'remainingAmount',
        'availableBalance',
        'headOfFamily',
        'recordPayment',
        'cancelReceipt',
        'marathiNumerals',
      ];

      for (final lang in ['mr', 'en', 'hi']) {
        final loc = AppLocalizations(lang);
        for (final key in keysToCheck) {
          final translation = loc.tr(key);
          expect(translation, isNotEmpty, reason: 'Key $key missing in $lang');
          expect(translation, isNot(equals(key)),
              reason: 'Key $key not translated in $lang');
        }
      }
    });
  });
}
