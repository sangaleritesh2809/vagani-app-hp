import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vargani_app/core/models/group_model.dart';
import 'package:vargani_app/core/models/user_model.dart';
import 'package:vargani_app/providers/auth_provider.dart';
import 'package:vargani_app/providers/language_theme_provider.dart';
import 'package:vargani_app/providers/vargani_data_provider.dart';
import 'package:vargani_app/core/services/supabase_auth_service.dart';
import 'package:vargani_app/ui/screens/auth/forgot_password_screen.dart';
import 'package:vargani_app/ui/screens/auth/group_selection_screen.dart';
import 'package:vargani_app/ui/screens/auth/login_screen.dart';
import 'package:vargani_app/ui/screens/auth/otp_verification_screen.dart';
import 'package:vargani_app/ui/screens/auth/register_screen.dart';
import 'package:vargani_app/ui/screens/main_navigation_shell.dart';
import 'package:vargani_app/core/services/email_otp_service.dart';

Widget _buildAuthTestApp({
  required AuthProvider authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageThemeProvider()),
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProvider(create: (_) => VarganiDataProvider()),
    ],
    child: Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          home: !auth.isAuthenticated
              ? const LoginScreen()
              : (auth.needsGroupSelection
                  ? const GroupSelectionScreen()
                  : const MainNavigationShell()),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider & RBAC Unit Tests', () {
    test('Initial state: defaultPhone is 9699342811, unauthenticated', () {
      final auth = AuthProvider();
      expect(AuthProvider.defaultPhone, '9699342811');
      expect(auth.isAuthenticated, isFalse);
    });

    test('loginWithOtp with invalid OTP fails', () async {
      final auth = AuthProvider();
      final res = await auth.loginWithOtp('9699342811', '000000');
      expect(res.success, isFalse);
      expect(auth.isAuthenticated, isFalse);
    });

    test('loginWithPassword with 9699342811 and valid password succeeds',
        () async {
      final auth = AuthProvider();
      final res = await auth.loginWithPassword('9699342811', 'vargani@123');
      expect(res.success, isTrue);
      expect(auth.isAuthenticated, isTrue);
    });

    test('Inactive user cannot log in (Requirement 5)', () async {
      final auth = AuthProvider();
      const inactiveUser = UserModel(
        id: 'usr_inactive_test',
        name: 'Inactive User',
        phone: '9111122222',
        email: 'inactive@varganipro.in',
        organizationId: 'org_001',
        role: UserRole.collector,
        isActive: false,
      );
      auth.switchUser(inactiveUser);
      expect(auth.currentUser.isActive, isFalse);

      auth.logout();
      // Try login with inactive user phone
      final res = await auth.loginWithOtp('9111122222', '123456');
      expect(res.success, isFalse);
      expect(res.message, contains('निष्क्रिय'));
    });

    test(
        'Super Admin cannot be self-assigned during registration (Requirement 1)',
        () async {
      final auth = AuthProvider();
      final res = await auth.registerUser(
        name: 'Hacker User',
        phone: '9888899999',
        role: UserRole.superAdmin,
        password: 'password123',
      );
      expect(res.success, isFalse);
      expect(res.message, contains('Super Admin'));
    });

    test(
        'Group selection updates selectedGroup and clears needsGroupSelection (Requirement 6)',
        () async {
      final auth = AuthProvider();
      final loginRes = await auth.loginWithPassword('9822054321', 'admin@123');
      expect(loginRes.success, isTrue);
      expect(auth.needsGroupSelection, isTrue);

      const testGroup = GroupModel(
        id: 'grp_001',
        organizationId: 'org_001',
        name: 'Shivaji Chowk Mandal Group',
        code: 'GRP-SC-01',
        description: 'Test group',
      );

      final selectRes = await auth.selectGroup(testGroup);
      expect(selectRes['success'], isTrue);
      expect(auth.selectedGroup?.id, 'grp_001');
      expect(auth.needsGroupSelection, isFalse);
    });

    test('PBAC: SuperAdmin has all permissions (*)', () {
      final auth = AuthProvider();
      const superUser = UserModel(
        id: 'usr_super',
        name: 'Vikram Deshmukh',
        phone: '9888811111',
        email: 'super@varganipro.in',
        organizationId: 'org_001',
        role: UserRole.superAdmin,
        permissions: ['*'],
      );
      auth.switchUser(superUser);
      expect(auth.hasPermission('any.random.permission'), isTrue);
      expect(auth.canManageOrganizations, isTrue);
      expect(auth.canManageRoles, isTrue);
      expect(auth.canManageUsers, isTrue);
    });

    test(
        'PBAC: Citizen cannot manage expenses, campaigns or roles (Requirement 4)',
        () {
      final auth = AuthProvider();
      auth.continueAsGuest();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentRole, UserRole.citizen);
      expect(auth.hasPermission('expenses.create'), isFalse);
      expect(auth.hasPermission('campaigns.manage'), isFalse);
      expect(auth.hasPermission('roles.manage'), isFalse);
      expect(auth.hasPermission('reports.view'), isTrue);
    });

    test('resetPassword with valid OTP updates password', () async {
      final auth = AuthProvider();
      final otpRes = await EmailOtpService.sendOtpToEmail(
        phone: '9822054321',
        email: 'admin@varganipro.in',
        userName: 'Admin User',
        purpose: 'Reset',
      );
      final validOtp = (otpRes['otp'] ?? '') as String;
      expect(validOtp.isNotEmpty, isTrue);
      final resetSuccess = auth.resetPassword(
        phone: '9822054321',
        otp: validOtp,
        newPassword: 'myNewSecurePassword123',
      );
      expect(resetSuccess, isTrue);
    });

    test('continueAsGuest logs in as citizen without group selection', () {
      final auth = AuthProvider();
      auth.continueAsGuest();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentRole, UserRole.citizen);
      expect(auth.needsGroupSelection, isFalse);
    });

    test('logout clears authentication and group selection', () async {
      final auth = AuthProvider();
      final loginRes = await auth.loginWithPassword('9822054321', 'admin@123');
      expect(loginRes.success, isTrue);
      expect(auth.isAuthenticated, isTrue);

      auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.selectedGroup, isNull);
    });
  });

  group('LoginScreen & Group Selection Widget Tests', () {
    void setupViewport(WidgetTester tester) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets(
        'Password Login proceeds to GroupSelectionScreen and then to MainNavigationShell',
        (tester) async {
      setupViewport(tester);

      final auth = AuthProvider();
      await tester.pumpWidget(_buildAuthTestApp(authProvider: auth));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Enter phone and password
      await tester.enterText(textFields.at(0), '9822054321');
      await tester.enterText(textFields.at(1), 'admin@123');
      await tester.pumpAndSettle();

      // Tap Login button
      final loginBtn = find.widgetWithIcon(ElevatedButton, Icons.login_rounded);
      expect(loginBtn, findsOneWidget);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Should be authenticated and routed to GroupSelectionScreen (Requirement 6)
      expect(auth.isAuthenticated, isTrue);
      expect(find.byType(GroupSelectionScreen), findsOneWidget);

      // Now tap "Proceed to Dashboard" to enter MainNavigationShell
      final enterGroupButton = find.textContaining('Proceed to Dashboard');
      expect(enterGroupButton, findsOneWidget);
      await tester.tap(enterGroupButton);
      await tester.pumpAndSettle();

      expect(auth.needsGroupSelection, isFalse);
      expect(find.byType(MainNavigationShell), findsOneWidget);
    });

    testWidgets(
        'Guest / Public View button allows instant citizen access without group selection',
        (tester) async {
      setupViewport(tester);

      final auth = AuthProvider();
      await tester.pumpWidget(_buildAuthTestApp(authProvider: auth));
      await tester.pumpAndSettle();

      final guestButton = find.byIcon(Icons.visibility_outlined);
      expect(guestButton, findsOneWidget);
      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      expect(auth.isAuthenticated, isTrue);
      expect(auth.isCitizen, isTrue);
      expect(find.byType(MainNavigationShell), findsOneWidget);
    });

    testWidgets('Navigation to RegisterScreen works', (tester) async {
      setupViewport(tester);

      final auth = AuthProvider();
      await tester.pumpWidget(_buildAuthTestApp(authProvider: auth));
      await tester.pumpAndSettle();

      // Find Sign Up text or button
      final signUpButton = find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'नोंदणी करा' || w.data == 'Sign Up'),
      );
      expect(signUpButton, findsOneWidget);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('Navigation to ForgotPasswordScreen works from Password tab',
        (tester) async {
      setupViewport(tester);

      final auth = AuthProvider();
      await tester.pumpWidget(_buildAuthTestApp(authProvider: auth));
      await tester.pumpAndSettle();

      // Find Forgot Password button
      final forgotPasswordButton = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data?.contains('विसरलात') == true ||
                w.data?.contains('Forgot') == true),
      );
      expect(forgotPasswordButton, findsOneWidget);
      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets(
        'OtpVerificationScreen displays masked email, 6-digit inputs, 5-minute expiry and resend countdown',
        (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => VarganiDataProvider()),
          ],
          child: const MaterialApp(
            home: OtpVerificationScreen(
              email: 'testuser@gmail.com',
              maskedEmail: 't***r@gmail.com',
              phone: '9822000000',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Masked email is displayed
      expect(find.text('t***r@gmail.com'), findsOneWidget);

      // Check 5-minute expiry notice
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data?.contains('5 minute') == true ||
                w.data?.contains('५ मिनिट') == true)),
        findsOneWidget,
      );

      // Check 6 single-digit TextFields exist
      final digitFields = find.byType(TextField);
      expect(digitFields, findsNWidgets(6));

      // Check Resend Cooldown is active
      expect(find.textContaining('00:'), findsOneWidget);

      // Check Verify button exists
      expect(
        find.byWidgetPredicate((w) =>
            w is Text &&
            (w.data?.contains('Verify') == true ||
                w.data?.contains('तपासा') == true)),
        findsOneWidget,
      );
    });
  });

  group('Supabase Auth Service & Enhanced Features Tests', () {
    test(
        'SupabaseAuthService.maskEmail correctly masks username while keeping domain',
        () {
      expect(
        SupabaseAuthService.maskEmail('riteshsangale71@gmail.com'),
        'r***1@gmail.com',
      );
      expect(
        SupabaseAuthService.maskEmail('admin@varganipro.in'),
        'a***n@varganipro.in',
      );
      expect(
        SupabaseAuthService.maskEmail('ab@test.com'),
        'a***@test.com',
      );
    });

    test(
        'AuthProvider.sendLoginOtp with phone resolves to registered masked email',
        () async {
      final auth = AuthProvider();
      final res = await auth.sendLoginOtp(phone: '9699342811');
      expect(res['success'], isTrue);
      expect(res['maskedEmail'], isNotNull);
      expect(res['maskedEmail'], contains('***'));
    });

    test(
        'AuthProvider.sendLoginOtp with unregistered phone fails with descriptive message',
        () async {
      final auth = AuthProvider();
      final res = await auth.sendLoginOtp(phone: '9111111111');
      expect(res['success'], isFalse);
      expect(
          res['message'],
          anyOf(contains('नोंदणीकृत खाते आढळले नाही'),
              contains('No account found')));
    });

    test(
        'AuthProvider.sendLoginOtp with valid email returns masked destination',
        () async {
      final auth = AuthProvider();
      final res = await auth.sendLoginOtp(email: 'ritesh@gmail.com');
      expect(res['success'], isTrue);
      expect(res['maskedEmail'], 'r***h@gmail.com');
    });

    test(
        'AuthProvider.registerWithSupabase validates fields and detects duplicate phone',
        () async {
      final auth = AuthProvider();
      // Duplicate phone check
      final duplicateRes = await auth.registerWithSupabase(
        name: 'Duplicate Test',
        phone: '9699342811',
        email: 'newunique@gmail.com',
        password: 'password123',
        confirmPassword: 'password123',
      );
      expect(duplicateRes.success, isFalse);
      expect(duplicateRes.message,
          anyOf(contains('आधीच नोंदणीकृत'), contains('already registered')));
    });

    test('AuthProvider.registerWithSupabase detects mismatched passwords',
        () async {
      final auth = AuthProvider();
      final res = await auth.registerWithSupabase(
        name: 'Mismatch Test',
        phone: '9899999999',
        email: 'mismatch@gmail.com',
        password: 'password123',
        confirmPassword: 'differentPassword456',
      );
      expect(res.success, isFalse);
      expect(
          res.message, anyOf(contains('जुळत नाहीत'), contains('do not match')));
    });
  });
}
