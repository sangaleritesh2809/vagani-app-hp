import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../widgets/mandatory_label.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';
import '../../../core/navigation/app_navigator.dart';

enum LoginTab { mobileOtp, emailOtp, password }

class LoginScreen extends StatefulWidget {
  final LoginTab initialTab;

  const LoginScreen({
    super.key,
    this.initialTab = LoginTab
        .password, // default to password for backwards-compat with existing widget tests
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late LoginTab _activeTab;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final FocusNode _passwordFocusNode;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _phoneError;
  String? _passwordError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _passwordFocusNode = FocusNode(
      onKeyEvent: (node, event) => _handleBackspacedKey(
        node,
        event,
        _passwordController,
        () {
          if (_passwordError != null) setState(() => _passwordError = null);
        },
      ),
    );
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Explicitly handle Backspace, Delete, and Cut keys for Web & Desktop reliability
  KeyEventResult _handleBackspacedKey(
    FocusNode node,
    KeyEvent event,
    TextEditingController controller,
    VoidCallback? onClearError,
  ) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      final text = controller.text;

      // Handle Ctrl+X (Cut)
      if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyX) {
        if (text.isNotEmpty) {
          final sel = controller.selection;
          int start = sel.start;
          int end = sel.end;
          if (start < 0 || end < 0) {
            start = 0;
            end = text.length;
          }
          final min = start < end ? start : end;
          final max = start < end ? end : start;
          if (min != max) {
            Clipboard.setData(ClipboardData(text: text.substring(min, max)));
            final newText = text.replaceRange(min, max, '');
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: min),
            );
            onClearError?.call();
            return KeyEventResult.handled;
          }
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (text.isNotEmpty) {
          final sel = controller.selection;
          int start = sel.start;
          int end = sel.end;
          // When Web has uninitialized cursor, assume end of string
          if (start < 0 || end < 0) {
            start = text.length;
            end = text.length;
          }
          if (start != end) {
            final min = start < end ? start : end;
            final max = start < end ? end : start;
            final newText = text.replaceRange(min, max, '');
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: min),
            );
            onClearError?.call();
            return KeyEventResult.handled;
          } else if (start > 0) {
            final newText = text.replaceRange(start - 1, start, '');
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: start - 1),
            );
            onClearError?.call();
            return KeyEventResult.handled;
          }
        }
      } else if (event.logicalKey == LogicalKeyboardKey.delete) {
        if (text.isNotEmpty) {
          final sel = controller.selection;
          int start = sel.start;
          int end = sel.end;
          if (start < 0 || end < 0) {
            start = text.length;
            end = text.length;
          }
          if (start != end) {
            final min = start < end ? start : end;
            final max = start < end ? end : start;
            final newText = text.replaceRange(min, max, '');
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: min),
            );
            onClearError?.call();
            return KeyEventResult.handled;
          } else if (start < text.length) {
            final newText = text.replaceRange(start, start + 1, '');
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: start),
            );
            onClearError?.call();
            return KeyEventResult.handled;
          }
        }
      }
    }
    return KeyEventResult.ignored;
  }

  /// Request OTP for Mobile Number (resolves to registered verified email)
  Future<void> _handleMobileOtpRequest() async {
    setState(() {
      _phoneError = null;
    });
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');

    if (phone.isEmpty) {
      setState(() => _phoneError = 'Please enter your mobile number');
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      setState(
          () => _phoneError = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final res = await auth.sendLoginOtp(phone: phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final targetEmail = res['email']?.toString() ?? '';
      final maskedEmail = res['maskedEmail']?.toString() ?? targetEmail;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent successfully to $maskedEmail'),
          backgroundColor: AppColors.statusPaid,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to dedicated 6-digit OTP Verification Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: targetEmail,
            maskedEmail: maskedEmail,
            phone: phone,
            otpType: OtpType.email,
          ),
        ),
      );
    } else {
      setState(() {
        _phoneError = res['message']?.toString() ??
            'Unable to send OTP. Please try again.';
      });
    }
  }

  /// Request OTP for Email Address directly
  Future<void> _handleEmailOtpRequest() async {
    setState(() {
      _emailError = null;
    });
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address');
      return;
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email)) {
      setState(() => _emailError =
          'Please enter a valid email address (e.g. name@gmail.com)');
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final res = await auth.sendLoginOtp(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final masked = res['maskedEmail']?.toString() ?? email;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent successfully to $masked'),
          backgroundColor: AppColors.statusPaid,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            maskedEmail: masked,
            otpType: OtpType.email,
          ),
        ),
      );
    } else {
      setState(() {
        _emailError = res['message']?.toString() ??
            'Unable to send OTP. Please try again.';
      });
    }
  }

  /// Handle Password Login
  Future<void> _handlePasswordLogin() async {
    setState(() {
      _phoneError = null;
      _passwordError = null;
    });

    final rawInput = _phoneController.text.trim();
    final isEmail = rawInput.contains('@');
    final cleanPhone = rawInput.replaceAll(RegExp(r'\D'), '');
    final password = _passwordController.text;

    bool hasError = false;

    if (rawInput.isEmpty) {
      _phoneError = 'Please enter mobile number or email';
      hasError = true;
    } else if (!isEmail && (cleanPhone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone))) {
      _phoneError = 'Please enter a valid 10-digit mobile number or email address';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter your password';
      hasError = true;
    } else if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final result = await auth.loginWithPassword(rawInput, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Login successful! Welcome, ${result.user?.name ?? auth.currentUser.name}.'),
          backgroundColor: AppColors.statusPaid,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      AppNavigator.navigateToHome(auth);
    } else {
      setState(() {
        _passwordError = result.message.isNotEmpty
            ? result.message
            : 'Incorrect mobile number or password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langTheme = context.watch<LanguageThemeProvider>();
    final lang = langTheme.localizations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final isMarathi = langTheme.isMarathi;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon and Title
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vargani Collection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.blueGrey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Digital Vargani & Receipt Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Three Modern Login Option Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(
                          tab: LoginTab.password,
                          title: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        _buildTabButton(
                          tab: LoginTab.mobileOtp,
                          title: 'Mobile OTP',
                          icon: Icons.phone_android_rounded,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        _buildTabButton(
                          tab: LoginTab.emailOtp,
                          title: 'Email OTP',
                          icon: Icons.email_outlined,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form content based on active tab
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _activeTab == LoginTab.password
                        ? _buildPasswordForm(
                            lang, isDark, primaryColor, isMarathi)
                        : (_activeTab == LoginTab.mobileOtp
                            ? _buildMobileOtpForm(
                                lang, isDark, primaryColor, isMarathi)
                            : _buildEmailOtpForm(
                                lang, isDark, primaryColor, isMarathi)),
                  ),

                  const SizedBox(height: 24),

                  // Don't have an account -> Sign up link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                initialPhone: _phoneController.text.trim(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Guest Public Transparency View Button
                  OutlinedButton.icon(
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      auth.continueAsGuest();
                      AppNavigator.navigateToHome(auth);
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text(
                      'Continue as Citizen / Public',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.blueGrey.shade300
                          : AppColors.lightTextSecondary,
                      side: BorderSide(
                        color: isDark
                            ? Colors.blueGrey.shade700
                            : Colors.blueGrey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required LoginTab tab,
    required String title,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
  }) {
    final isSelected = _activeTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tab;
            _phoneError = null;
            _passwordError = null;
            _emailError = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? primaryColor
                    : (isDark
                        ? Colors.blueGrey.shade400
                        : Colors.blueGrey.shade600),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.blueGrey.shade900)
                      : (isDark
                          ? Colors.blueGrey.shade400
                          : Colors.blueGrey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Mobile Number OTP Form
  Widget _buildMobileOtpForm(
      dynamic lang, bool isDark, Color primaryColor, bool isMarathi) {
    return Column(
      key: const ValueKey('mobile_otp_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MandatoryLabel(
          'Registered Mobile Number',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: (_) {
            if (_phoneError != null) setState(() => _phoneError = null);
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 42, minHeight: 42),
            hintText: 'Enter 10-digit mobile number',
            counterText: '',
            errorText: _phoneError,
            errorStyle: const TextStyle(fontSize: 12, color: Colors.redAccent),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleMobileOtpRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Send 6-Digit OTP',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// 2. Email Address OTP Form
  Widget _buildEmailOtpForm(
      dynamic lang, bool isDark, Color primaryColor, bool isMarathi) {
    return Column(
      key: const ValueKey('email_otp_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MandatoryLabel(
          'Registered Email Address',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email_outlined),
            hintText: 'name@gmail.com',
            errorText: _emailError,
            errorStyle: const TextStyle(fontSize: 12, color: Colors.redAccent),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailOtpRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_email_read_rounded,
                          size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Send OTP to Email',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// 3. Password Login Form
  Widget _buildPasswordForm(
      dynamic lang, bool isDark, Color primaryColor, bool isMarathi) {
    return Column(
      key: const ValueKey('password_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MandatoryLabel(
          'Mobile Number or Email',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Focus(
          onKeyEvent: (node, event) => _handleBackspacedKey(
            node,
            event,
            _phoneController,
            () {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 42, minHeight: 42),
              hintText: 'Enter 10-digit mobile number or email',
              counterText: '',
              errorText: _phoneError,
              errorStyle:
                  const TextStyle(fontSize: 12, color: Colors.redAccent),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        const MandatoryLabel(
          'Password',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          focusNode: _passwordFocusNode,
          controller: _passwordController,
          obscureText: _obscurePassword,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: (_) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            } else {
              setState(() {}); // refresh to toggle clear button
            }
          },
          decoration: InputDecoration(
            hintText: 'Enter password',
            counterText: '',
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 42, minHeight: 42),
            errorText: _passwordError,
            errorStyle:
                const TextStyle(fontSize: 12, color: Colors.redAccent),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_passwordController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear password',
                    icon: const Icon(Icons.cancel_rounded,
                        size: 20, color: Colors.grey),
                    onPressed: () {
                      _passwordController.clear();
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      } else {
                        setState(() {});
                      }
                    },
                  ),
                IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.remove_red_eye
                        : Icons.visibility_off,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Forgot Password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ForgotPasswordScreen(
                    initialPhone: _phoneController.text.trim(),
                  ),
                ),
              );
            },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Login Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handlePasswordLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded,
                          size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
