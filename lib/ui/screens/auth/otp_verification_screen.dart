import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String maskedEmail;
  final String? phone;
  final OtpType otpType;
  final bool isRegistration;
  final String? registrationName;
  final String? registrationPassword;
  final UserRole registrationRole;
  final bool isPasswordReset;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.maskedEmail,
    this.phone,
    this.otpType = OtpType.email,
    this.isRegistration = false,
    this.registrationName,
    this.registrationPassword,
    this.registrationRole = UserRole.citizen,
    this.isPasswordReset = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _cooldownSeconds = 60;
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = _cooldownSeconds;
  Timer? _countdownTimer;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() => _resendCountdown = _cooldownSeconds);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  String get _currentOtp => _digitControllers.map((c) => c.text.trim()).join();

  Future<void> _handleResend() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();

    try {
      final res = await auth.resendOtp(
        email: widget.email,
        phone: widget.phone,
        name: widget.registrationName,
        isRegistration: widget.isRegistration,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        for (final c in _digitControllers) {
          c.clear();
        }
        if (_focusNodes.isNotEmpty) {
          _focusNodes.first.requestFocus();
        }

        _startCooldownTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ??
                'A new 6-digit OTP has been sent to ${widget.maskedEmail}.'),
            backgroundColor: AppColors.statusPaid,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _errorMessage =
            res['message']?.toString() ?? 'Failed to resend OTP.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _currentOtp;
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();

    try {
      if (widget.isRegistration) {
        // Registration verification
        final res = await auth.verifyRegistrationOtp(
          email: widget.email,
          otp: otp,
          name: widget.registrationName ?? 'User',
          phone: widget.phone ?? '',
          password: widget.registrationPassword ?? '',
          role: widget.registrationRole,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor: AppColors.statusPaid,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          setState(() => _errorMessage = res.message);
        }
      } else if (widget.isPasswordReset) {
        // Return OTP to parent screen for password update
        setState(() => _isLoading = false);
        Navigator.pop(context, otp);
      } else {
        // Login OTP verification
        final res = await auth.verifySupabaseOtp(
          email: widget.email,
          otp: otp,
          type: widget.otpType,
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor: AppColors.statusPaid,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          setState(() => _errorMessage = res.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          
          _isLoading = false;
          _errorMessage = 'An error occurred during verification: $e';
        });
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      // If user typed or pasted more than 1 character
      if (value.length > 1) {
        final digits = value.replaceAll(RegExp(r'\D'), '');
        for (int i = 0; i < digits.length && (index + i) < 6; i++) {
          _digitControllers[index + i].text = digits[i];
        }
        final nextIndex =
            (index + digits.length < 6) ? index + digits.length : 5;
        _focusNodes[nextIndex].requestFocus();
      } else {
        if (index < 5) {
          _focusNodes[index + 1].requestFocus();
        } else {
          _focusNodes[index].unfocus();
        }
      }
    }
    setState(() => _errorMessage = null);

    // Auto-submit if all 6 digits entered
    if (_currentOtp.length == 6) {
      _handleVerify();
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
          'OTP Verification',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.12),
                        border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Secure OTP Verification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blueGrey.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Masked destination banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.blueGrey.shade800
                            : Colors.blueGrey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '6-digit OTP has been sent to:',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.blueGrey.shade300
                                : Colors.blueGrey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email_outlined,
                                size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.maskedEmail,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 5-minute validity note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'This OTP is valid for 5 minutes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 6 Digit Input Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: TextField(
                          controller: _digitControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor:
                                isDark ? const Color(0xFF1E293B) : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.blueGrey.shade700
                                    : Colors.blueGrey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (val) => _onDigitChanged(index, val),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                  color: Colors.red.shade800, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Verify Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Verify & Proceed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Resend Cooldown Timer
                  Center(
                    child: _resendCountdown > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_bottom_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.blueGrey.shade400
                                    : Colors.blueGrey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Resend code in (00:${_resendCountdown.toString().padLeft(2, '0')}s)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.blueGrey.shade400
                                      : Colors.blueGrey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : TextButton.icon(
                            onPressed: _isResending ? null : _handleResend,
                            icon: _isResending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text(
                              'Resend OTP to Email',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
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
}
