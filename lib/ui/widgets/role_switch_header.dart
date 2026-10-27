import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_theme_provider.dart';
import '../../providers/vargani_data_provider.dart';

class RoleSwitchHeader extends StatelessWidget {
  const RoleSwitchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final data = context.watch<VarganiDataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : const Color(0xFFFFFBEB),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFFDE68A),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Current Role Pill with Icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    auth.currentRole.nameString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // User Name & Org
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  auth.currentUser.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  data.organization.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Quick Role Switch Dropdown / Popup
          PopupMenuButton<UserRole?>(
            tooltip: 'Switch Demo Role / Logout',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  size: 18, color: AppColors.primary),
            ),
            onSelected: (role) {
              if (role == null) {
                auth.logout();
              } else {
                auth.switchRole(role);
              }
            },
            itemBuilder: (context) {
              return [
                ...UserRole.values.map((role) {
                  final isSelected = auth.currentRole == role;
                  return PopupMenuItem<UserRole?>(
                    value: role,
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 16,
                          color: isSelected ? AppColors.primary : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          role.nameString,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const PopupMenuDivider(),
                const PopupMenuItem<UserRole?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded,
                          size: 16, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),

          const SizedBox(width: 4),

          // Language Toggle (English)
          InkWell(
            onTap: () => langTheme.toggleLanguage(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Text(
                langTheme.languageCode.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Theme Mode Toggle
          IconButton(
            icon: Icon(
              langTheme.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? Colors.amber : AppColors.lightTextSecondary,
            ),
            onPressed: () => langTheme.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
    );
  }
}
