import 'package:flutter/material.dart';
import '../../core/models/organization_model.dart';
import '../screens/auth/organization_selection_screen.dart';

class OrganizationStatusCard extends StatelessWidget {
  final OrganizationModel? organization;
  final int organizationCount;
  final VoidCallback? onSwitch;
  final EdgeInsetsGeometry? margin;

  const OrganizationStatusCard({
    super.key,
    required this.organization,
    this.organizationCount = 1,
    this.onSwitch,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMultiple = organizationCount > 1;

    // Organization type in parentheses, e.g. "(Festival Committee)" matching "(HRMS & Payroll)"
    final orgType = (organization?.organizationType != null &&
            organization!.organizationType.trim().isNotEmpty)
        ? organization!.organizationType.trim()
        : 'Festival Committee';

    // Organization name, e.g. "munde saheb tarun mitra mandal"
    final orgName = (organization != null && organization!.name.trim().isNotEmpty)
        ? organization!.name.trim()
        : 'Munde Saheb Tarun Mitra Mandal';

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Organization name in parentheses, e.g. "(munde saheb)" or "(Shree Shiv Chhatrapati Mandal)"
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '($orgName)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Clean modern Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: (onSwitch ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrganizationSelectionScreen(
                            isSwitching: true,
                          ),
                        ),
                      );
                    }),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Mint green rounded square container with 2-people icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1B382B)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          color: isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF2E7D32),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Card Title: Switch Organization
                      Expanded(
                        child: Text(
                          'Switch Organization',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Chevron >
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
