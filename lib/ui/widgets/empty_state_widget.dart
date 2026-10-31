import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable modern Empty State Widget matching the Vargani App UI theme.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageAsset;
  final IconData? fallbackIcon;
  final String? actionText;
  final VoidCallback? onAction;
  final double imageSize;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.imageAsset = 'assets/images/not_found.png',
    this.fallbackIcon = Icons.search_off_rounded,
    this.actionText,
    this.onAction,
    this.imageSize = 160,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Illustration or Fallback Icon
            if (imageAsset != null)
              Image.asset(
                imageAsset!,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildFallbackIllustration(isDark),
              )
            else
              _buildFallbackIllustration(isDark),

            const SizedBox(height: 20),

            // 2. Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),

            // 3. Subtitle
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // 4. Optional Action Button
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIllustration(bool isDark) {
    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: imageSize * 0.55,
          height: imageSize * 0.55,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            fallbackIcon ?? Icons.search_off_rounded,
            size: imageSize * 0.32,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

