import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Royal Saffron & Deep Navy / Slate
  static const Color primary = Color(0xFFFF6F00); // Amber 900 / Deep Saffron
  static const Color primaryLight = Color(0xFFFF8F00);
  static const Color primaryDark = Color(0xFFE65100);
  
  static const Color secondary = Color(0xFF1E3A8A); // Royal Blue
  static const Color secondaryLight = Color(0xFF3B82F6);
  static const Color secondaryDark = Color(0xFF172554);
  
  // Accents
  static const Color accentGold = Color(0xFFFFB300);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentViolet = Color(0xFF8B5CF6);

  // Status Colors
  static const Color statusPaid = Color(0xFF10B981); // Emerald
  static const Color statusPartiallyPaid = Color(0xFFF59E0B); // Amber
  static const Color statusPending = Color(0xFFEF4444); // Crimson
  static const Color statusApproved = Color(0xFF059669);
  static const Color statusRejected = Color(0xFFDC2626);
  static const Color statusEscalated = Color(0xFF7C3AED);

  // Light Theme Neutrals
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark Theme Neutrals
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCardBg = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6F00), Color(0xFFFF8F00), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient saffronRoyalGradient = LinearGradient(
    colors: [Color(0xFFEA580C), Color(0xFFC2410C), Color(0xFF7C2D12)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
