import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/mandatory_label.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String initialPhone;

  const RegisterScreen({
    super.key,
    this.initialPhone = '',
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  late final TextEditingController _phoneController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final UserRole _selectedRole = UserRole.citizen;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Field-level error messages (displayed directly below each input field in English)
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearAllErrors() {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });
  }

  Future<void> _handleRegister() async {
    _clearAllErrors();

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;

    // 1. Validation checks (field level, in English)
    if (fullName.isEmpty) {
      _nameError = 'Please enter your full name';
      hasError = true;
    } else if (fullName.length < 2) {
      _nameError = 'Full name must be at least 2 characters';
      hasError = true;
    }

    if (phone.isEmpty) {
      _phoneError = 'Please enter mobile number';
      hasError = true;
    } else if (phone.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _phoneError = 'Please enter a valid 10-digit mobile number';
      hasError = true;
    }

    if (email.isEmpty) {
      _emailError = 'Please enter email address';
      hasError = true;
    } else if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email)) {
      _emailError = 'Please enter a valid email address (e.g. name@gmail.com)';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter password';
      hasError = true;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      hasError = true;
    } else if (password != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    // 2. Perform registration via Supabase Auth
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final result = await auth.registerWithSupabase(
      name: fullName,
      phone: phone,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      role: _selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      final maskedEmail = email.contains('@')
          ? '${email.substring(0, 1)}***${email.substring(email.indexOf('@') - 1)}'
          : email;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Registration initiated. Verification OTP sent to your email.'),
          backgroundColor: AppColors.statusPaid,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to dedicated 6-digit OTP verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            maskedEmail: maskedEmail,
            phone: phone,
            otpType: OtpType.signup,
            isRegistration: true,
            registrationName: fullName,
            registrationPassword: password,
            registrationRole: _selectedRole,
          ),
        ),
      );
    } else {
      final msg = result.message.toLowerCase();
      setState(() {
        if (msg.contains('phone') || msg.contains('mobile')) {
          _phoneError = 'Mobile number is already registered. Please login.';
        } else if (msg.contains('email')) {
          _emailError =
              'Email is already registered. Please login or use another email.';
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
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
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header text
                    Text(
                      'Join Vargani Platform',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blueGrey.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your details and complete verification.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.blueGrey.shade400
                            : Colors.blueGrey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. Full Name
                    const MandatoryLabel(
                      'Full Name',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _fullNameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (val) {
                        if (_nameError != null)
                          setState(() => _nameError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        hintText: 'e.g. Ramesh Patil',
                        errorText: _nameError,
                        errorStyle: const TextStyle(
                            fontSize: 12, color: Colors.redAccent),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Mobile Number
                    const MandatoryLabel(
                      'Mobile Number',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (val) {
                        if (_phoneError != null)
                          setState(() => _phoneError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.phone_android_rounded, size: 20),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 42, minHeight: 42),
                        hintText: 'Enter 10-digit mobile number',
                        counterText: '',
                        errorText: _phoneError,
                        errorStyle: const TextStyle(
                            fontSize: 12, color: Colors.redAccent),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Email Address
                    const MandatoryLabel(
                      'Email Address',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) {
                        if (_emailError != null)
                          setState(() => _emailError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined),
                        hintText: 'name@gmail.com',
                        errorText: _emailError,
                        errorStyle: const TextStyle(
                            fontSize: 12, color: Colors.redAccent),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Password
                    const MandatoryLabel(
                      'Password',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (val) {
                        if (_passwordError != null)
                          setState(() => _passwordError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        hintText: 'Minimum 6 characters',
                        errorText: _passwordError,
                        errorStyle: const TextStyle(
                            fontSize: 12, color: Colors.redAccent),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Confirm Password
                    const MandatoryLabel(
                      'Confirm Password',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      onChanged: (val) {
                        if (_confirmPasswordError != null)
                          setState(() => _confirmPasswordError = null);
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        hintText: 'Re-enter password',
                        errorText: _confirmPasswordError,
                        errorStyle: const TextStyle(
                            fontSize: 12, color: Colors.redAccent),
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
                    const SizedBox(height: 18),

                    // 6. Role Selection (Super Admin blocked)
                    // Secure Default Role Indicator (Requirement 5 & 7)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_outlined,
                              size: 20, color: AppColors.primary),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account: Public Citizen Account',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.primary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'You can search public groups and submit join requests after login.',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
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
                                  Icon(Icons.check_circle_outline_rounded,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Register & Verify via OTP',
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
                    const SizedBox(height: 20),

                    // Already have an account -> Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: isDark
                                ? Colors.blueGrey.shade400
                                : Colors.blueGrey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
