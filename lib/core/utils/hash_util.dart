import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  // Constant salt to prevent rainbow table attacks
  static const String _salt = 'vargani_pro_secure_salt_2026';

  /// Hashes a plaintext password using SHA-256 with salt.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies whether the provided plaintext password matches the stored hash.
  static bool verifyPassword(String password, String storedHash) {
    if (storedHash.isEmpty || password.isEmpty) return false;
    final computedHash = hashPassword(password);
    return computedHash == storedHash;
  }
}
