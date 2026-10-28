import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'email_otp_service.dart';
import 'supabase_service.dart';

/// Service managing Supabase Authentication (OTP, Email, Registration, Password)
class SupabaseAuthService {
  static SupabaseClient? get _client => SupabaseService.client;

  /// Helper to mask email address (e.g. riteshsangale71@gmail.com -> r***1@gmail.com)
  static String maskEmail(String email) {
    final clean = email.trim();
    final atIndex = clean.indexOf('@');
    if (atIndex <= 1) return '***@***.com';

    final user = clean.substring(0, atIndex);
    final domain = clean.substring(atIndex);

    if (user.length <= 2) {
      return '${user[0]}***$domain';
    }
    return '${user[0]}***${user[user.length - 1]}$domain';
  }

  /// Clean phone number to 10 digits
  static String cleanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Look up the verified email mapped to a mobile number
  /// Uses the secure PostgreSQL RPC function `lookup_phone_email`
  static Future<Map<String, dynamic>> lookupEmailByPhone(String phone) async {
    final clean = cleanPhone(phone);
    if (clean.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return {
        'success': false,
        'message': 'Please enter a valid 10-digit mobile number.',
      };
    }

    final client = _client;
    if (client == null) {
      return {
        'success': false,
        'message':
            'Unable to connect to server. Please check your internet connection.',
      };
    }

    // 1. Try secure PostgreSQL RPC function first
    try {
      final res =
          await client.rpc('lookup_phone_email', params: {'p_phone': clean});
      if (res is Map) {
        final success = res['success'] == true;
        if (success) {
          final rawEmail = res['email']?.toString() ?? '';
          final maskedEmail =
              res['masked_email']?.toString() ?? maskEmail(rawEmail);
          return {
            'success': true,
            'email': rawEmail,
            'maskedEmail': maskedEmail,
            'name': res['name']?.toString() ?? 'User',
          };
        } else {
          return {
            'success': false,
            'message': res['message']?.toString() ??
                'No registered account found with this mobile number.',
          };
        }
      }
    } catch (e) {
      debugPrint('RPC lookup_phone_email fallback: $e');
    }

    // 2. Direct query fallback to public.users table if RPC is not yet executed in Supabase
    try {
      final res = await client
          .from('users')
          .select('email, name, is_active, phone')
          .ilike('phone', '%$clean')
          .limit(1)
          .maybeSingle();

      if (res != null && res['email'] != null) {
        final isActive = res['is_active'] != false;
        if (!isActive) {
          return {
            'success': false,
            'message':
                'Your account is inactive. Please contact administrator.',
          };
        }

        final rawEmail = res['email'].toString();
        return {
          'success': true,
          'email': rawEmail,
          'maskedEmail': maskEmail(rawEmail),
          'name': res['name']?.toString() ?? 'User',
        };
      }
    } catch (e) {
      debugPrint('Direct user table query note: $e');
    }

    return {
      'success': false,
      'message':
          'No registered account found with this mobile number. Please register first.',
    };
  }

  /// Send real 6-digit OTP to an email
  /// Dispatches 6-digit OTP directly to email via EmailJS (so OTP is clearly visible in email body)
  /// and also triggers Supabase Auth session OTP.
  static Future<Map<String, dynamic>> sendEmailOtp({
    required String email,
    String? name,
    String? phone,
    String? purpose,
  }) async {
    final cleanEmail = email.trim();
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(cleanEmail)) {
      return {
        'success': false,
        'message': 'Please enter a valid email address.',
      };
    }

    final purposeText = purpose ?? 'Login Verification';

    // 1. Dispatch real 6-digit OTP to the user's inbox via EmailJS
    final emailJsResult = await EmailOtpService.sendOtpToEmail(
      email: cleanEmail,
      phone: phone,
      userName: name ?? 'User',
      purpose: purposeText,
    );

    if (emailJsResult['success'] != true) {
      return emailJsResult;
    }

    return {
      'success': true,
      'message': '6-digit OTP sent to $cleanEmail. Please check your inbox.',
      'maskedEmail': maskEmail(cleanEmail),
      'otp': emailJsResult['otp'],
    };
  }

  /// Look up email from phone, then trigger 6-digit OTP to that email
  static Future<Map<String, dynamic>> sendPhoneOtp(
      {required String phone}) async {
    final lookup = await lookupEmailByPhone(phone);
    if (lookup['success'] != true || lookup['email'] == null) {
      return lookup;
    }

    final targetEmail = lookup['email'] as String;
    final userName = lookup['name']?.toString() ?? 'User';
    final otpResult = await sendEmailOtp(
      email: targetEmail,
      name: userName,
      phone: phone,
      purpose: 'Mobile Login Verification',
    );

    if (otpResult['success'] == true) {
      return {
        'success': true,
        'email': targetEmail,
        'maskedEmail': lookup['maskedEmail'] ?? maskEmail(targetEmail),
        'name': userName,
        'message': 'OTP sent to ${lookup['maskedEmail']}.',
        'otp': otpResult['otp'],
      };
    } else {
      return otpResult;
    }
  }

  /// Resend 6-digit OTP for either Registration or Login
  /// Ensures a fresh 6-digit OTP is delivered directly to the user's email.
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
    String? phone,
    String? name,
    required bool isRegistration,
  }) async {
    final cleanEmail = email.trim();
    final cleanP = phone != null ? cleanPhone(phone) : null;
    final purpose =
        isRegistration ? 'Registration Verification' : 'Login Verification';

    // 1. Dispatch fresh 6-digit OTP via EmailJS directly to inbox
    final emailJsResult = await EmailOtpService.sendOtpToEmail(
      email: cleanEmail,
      phone: cleanP,
      userName: name ?? 'User',
      purpose: purpose,
    );

    if (emailJsResult['success'] != true) {
      return emailJsResult;
    }

    return {
      'success': true,
      'message':
          'New 6-digit OTP sent to $cleanEmail. Please check your inbox.',
      'maskedEmail': maskEmail(cleanEmail),
      'otp': emailJsResult['otp'],
    };
  }

  /// Verify 6-digit OTP using Supabase Auth
  /// type: OtpType.email (for login) or OtpType.signup (for registration) or OtpType.recovery (for password reset)
  static Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }

    return await client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: type,
    );
  }

  /// Register a new user: Sends verification 6-digit OTP via EmailJS only
  /// Prevents Supabase default magic link email from being dispatched.
  static Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    final clean = cleanPhone(phone);
    final cleanEmail = email.trim();

    // Send real 6-digit OTP to the email using EmailJS only (No Supabase link email)
    return await EmailOtpService.sendOtpToEmail(
      email: cleanEmail,
      phone: clean,
      userName: name.trim(),
      purpose: 'Registration Verification',
    );
  }

  /// Sign in with Email and Password via Supabase Auth
  static Future<AuthResponse?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) return null;
    try {
      return await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      debugPrint('Supabase signInWithPassword note: $e');
      return null;
    }
  }

  /// Send password reset email
  static Future<void> resetPasswordForEmail(String email) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }
    await client.auth.resetPasswordForEmail(email.trim());
  }

  /// Update user password after authenticated or OTP recovery
  static Future<UserResponse> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase client is not initialized.');
    }
    return await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sign out current Supabase session
  static Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('Signout note: $e');
      }
    }
  }

  /// Fetch full user profile from Supabase users table
  static Future<UserModel?> fetchUserProfile(String userId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final res =
          await client.from('users').select().eq('id', userId).maybeSingle();
      if (res != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('fetchUserProfile error: $e');
    }
    return null;
  }

  /// Insert or update profile in public.users table
  static Future<bool> upsertUserProfile(UserModel user) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from('users').upsert({
        'id': user.id,
        'name': user.name,
        'phone': user.phone,
        'email': user.email,
        'role': user.role.name,
        'group_ids': user.groupIds,
        'is_active': user.isActive,
      });
      return true;
    } catch (e) {
      debugPrint('upsertUserProfile error: $e');
      return false;
    }
  }
}
