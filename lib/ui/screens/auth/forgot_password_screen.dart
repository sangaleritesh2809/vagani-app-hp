import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialPhone;

  const ForgotPasswordScreen({
    super.key,
    this.initialPhone = '',
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _inputController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _resolvedEmail;
  String? _maskedEmail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() =>
          _errorMessage = 'Please enter your mobile number or email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isEmail = input.contains('@');
    String targetEmail = '';
    String displayMasked = '';

    if (isEmail) {
      targetEmail = input;
      displayMasked = SupabaseAuthService.maskEmail(targetEmail);
    } else {
      final clean = SupabaseAuthService.cleanPhone(input);
      if (clean.length != 10) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please enter a valid 10-digit mobile number.';
        });
        return;
      }

      final lookup = await SupabaseAuthService.lookupEmailByPhone(clean);
      if (lookup['success'] != true || lookup['email'] == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = lookup['message']?.toString() ??
              'No account found linked to this number.';
        });
        return;
      }
      targetEmail = lookup['email'] as String;
      displayMasked =
          lookup['maskedEmail'] ?? SupabaseAuthService.maskEmail(targetEmail);
    }

    // Send reset OTP via Supabase
    try {
      if (SupabaseService.isInitialized && SupabaseService.client != null) {
        await SupabaseAuthService.resetPasswordForEmail(targetEmail);
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
        _resolvedEmail = targetEmail;
        _maskedEmail = displayMasked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset OTP has been sent to $displayMasked.'),
          backgroundColor: AppColors.statusPaid,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Fallback for offline demo
        _otpSent = true;
        _resolvedEmail = targetEmail;
        _maskedEmail = displayMasked;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    final input = _inputController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();

    // 1. Live Supabase reset
    if (SupabaseService.isInitialized &&
        SupabaseService.client != null &&
        _resolvedEmail != null) {
      try {
        await SupabaseAuthService.verifyOtp(
          email: _resolvedEmail!,
          token: otp,
          type: OtpType.recovery,
        );
        await SupabaseAuthService.updatePassword(newPass);

        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password reset successfully! Please login with your new password.'),
            backgroundColor: AppColors.statusPaid,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, input);
        return;
      } catch (e) {
        debugPrint('Supabase recovery note: $e');
      }
    }

    // 2. Local fallback
    final success = auth.resetPassword(
      phone: input,
      otp: otp,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please login.'),
          backgroundColor: AppColors.statusPaid,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, input);
    } else {
      setState(
          () => _errorMessage = 'Invalid OTP! Please check and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 38,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Forgot Password?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blueGrey.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your registered mobile or email to receive password reset OTP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.blueGrey.shade400
                          : Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Destination mask banner if OTP sent
                  if (_otpSent && _maskedEmail != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OTP has been sent to $_maskedEmail. (Valid for 5 minutes)',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Input: Mobile / Email
                  const Text(
                    'Mobile Number or Email',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.account_circle_outlined),
                      hintText: '98xxxxxxxx or name@gmail.com',
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      suffixIcon: !_otpSent
                          ? TextButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              child: const Text(
                                'Send OTP',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_otpSent) ...[
                    // OTP Input
                    const Text(
                      'Enter 6-Digit OTP',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.pin_rounded),
                        hintText: 'Enter 6-digit OTP',
                        counterText: '',
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New Password
                    const Text(
                      'New Password',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        hintText: 'Min 6 characters',
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    const Text(
                      'Confirm New Password',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        hintText: 'Re-enter password',
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Reset button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
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
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Update & Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
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
                                  Icon(Icons.send_rounded,
                                      size: 18, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Send Password Reset OTP',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
