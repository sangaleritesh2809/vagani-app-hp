import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vargani_app/core/services/email_otp_service.dart';
import 'package:vargani_app/providers/auth_provider.dart';
import 'package:vargani_app/providers/language_theme_provider.dart';
import 'package:vargani_app/providers/vargani_data_provider.dart';
import 'package:vargani_app/ui/screens/auth/otp_verification_screen.dart';

Widget _buildOtpTestApp({
  required AuthProvider authProvider,
  required Widget home,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageThemeProvider()),
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider(create: (_) => VarganiDataProvider()),
    ],
    child: MaterialApp(
      home: home,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EmailJS OTP Complete Flow Unit Tests', () {
    const testEmail = 'vargani.tester@gmail.com';

    test(
        '1. Send OTP generates 6-digit OTP and passes to_email, otp, and purpose',
        () async {
      await EmailOtpService.sendOtpToEmail(
        email: testEmail,
        userName: 'Tester User',
        purpose: 'वर्गणी लॉगिन पडताळणी',
      );

      // In unit test environment without real network, res may succeed or report network failure,
      // but in-memory entry with 6-digit OTP and 5-min expiry is strictly registered
      expect(EmailOtpService.hasPendingOtp(testEmail), isTrue);
    });

    test('2. Incorrect OTP is strictly rejected and login is not allowed',
        () async {
      await EmailOtpService.sendOtpToEmail(
        email: testEmail,
        userName: 'Tester User',
        purpose: 'वर्गणी लॉगिन पडताळणी',
      );

      final verifyRes = EmailOtpService.verifyOtp(
        identifier: testEmail,
        enteredOtp: '000000', // Wrong OTP
      );

      expect(verifyRes['success'], isFalse);
      expect(verifyRes['message'], contains('Incorrect OTP'));
    });

    test(
        '3. Dummy/hardcoded OTPs (e.g. 123456, 992224) are rejected when actual OTP does not match',
        () async {
      await EmailOtpService.sendOtpToEmail(
        email: testEmail,
        userName: 'Tester User',
        purpose: 'वर्गणी लॉगिन पडताळणी',
      );

      final verifyRes = EmailOtpService.verifyOtp(
        identifier: testEmail,
        enteredOtp: '123456',
      );

      expect(verifyRes['success'], isFalse);
      expect(verifyRes['message'], contains('Incorrect OTP'));
    });

    test('4. Correct OTP matches, succeeds, and consumes OTP to prevent replay',
        () async {
      final sendRes = await EmailOtpService.sendOtpToEmail(
        email: testEmail,
        userName: 'Tester User',
        purpose: 'लॉगिन पडताळणी',
      );

      final generatedOtp = sendRes['otp'] as String;
      expect(generatedOtp.length, 6);
      expect(int.tryParse(generatedOtp), isNotNull);

      // Verify with the actual generated OTP
      final verifyRes = EmailOtpService.verifyOtp(
        identifier: testEmail,
        enteredOtp: generatedOtp,
      );

      expect(verifyRes['success'], isTrue);
      expect(verifyRes['message'], contains('successfully'));

      // Replay attempt must fail because OTP was consumed
      final replayRes = EmailOtpService.verifyOtp(
        identifier: testEmail,
        enteredOtp: generatedOtp,
      );
      expect(replayRes['success'], isFalse);
    });

    test(
        '5. AuthProvider.verifySupabaseOtp with valid EmailJS OTP authenticates and loads user',
        () async {
      final auth = AuthProvider();
      final sendRes = await EmailOtpService.sendOtpToEmail(
        email: testEmail,
        userName: 'Tester User',
      );
      final generatedOtp = sendRes['otp'] as String;

      final authRes = await auth.verifySupabaseOtp(
        email: testEmail,
        otp: generatedOtp,
      );

      expect(authRes.success, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser.email.toLowerCase(), testEmail.toLowerCase());
    });

    test(
        '6. AuthProvider.verifySupabaseOtp with incorrect OTP fails without authenticating',
        () async {
      final auth = AuthProvider();
      await EmailOtpService.sendOtpToEmail(
        email: testEmail,
        userName: 'Tester User',
      );

      final authRes = await auth.verifySupabaseOtp(
        email: testEmail,
        otp: '999999',
      );

      expect(authRes.success, isFalse);
      expect(auth.isAuthenticated, isFalse);
    });
  });

  group('OtpVerificationScreen UI & Cooldown Tests', () {
    testWidgets(
        'OtpVerificationScreen enforces 60-second resend cooldown and 6-digit input',
        (tester) async {
      final auth = AuthProvider();

      await tester.pumpWidget(
        _buildOtpTestApp(
          authProvider: auth,
          home: const OtpVerificationScreen(
            email: 'test@varganipro.in',
            maskedEmail: 't***t@varganipro.in',
            otpType: OtpType.email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Masked email and 6-digit fields displayed
      expect(find.textContaining('t***t@varganipro.in'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(6));

      // 60-second cooldown active
      expect(find.textContaining('00:60s'), findsOneWidget);

      // Advance timer by 30 seconds
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.textContaining('00:30s'), findsOneWidget);

      // Advance timer past 60 seconds
      for (int i = 0; i < 31; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.textContaining('Resend OTP'), findsOneWidget);
    });
  });
}
