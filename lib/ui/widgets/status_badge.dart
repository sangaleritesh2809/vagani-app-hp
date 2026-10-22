import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/household_model.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.fromPaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const StatusBadge(
          label: 'Paid (पूर्ण जमा)',
          color: AppColors.statusPaid,
          icon: Icons.check_circle_rounded,
        );
      case PaymentStatus.partiallyPaid:
        return const StatusBadge(
          label: 'Partially Paid (अंशतः जमा)',
          color: AppColors.statusPartiallyPaid,
          icon: Icons.timelapse_rounded,
        );
      case PaymentStatus.pending:
        return const StatusBadge(
          label: 'Pending (बाकी)',
          color: AppColors.statusPending,
          icon: Icons.pending_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
