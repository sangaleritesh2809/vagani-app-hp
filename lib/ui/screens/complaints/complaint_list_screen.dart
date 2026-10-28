import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/complaint_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/mandatory_label.dart';
import 'new_complaint_dialog.dart';

class ComplaintListScreen extends StatelessWidget {
  const ComplaintListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If citizen, filter their own complaints (matching ID, Phone, or Name)
    final complaints = auth.isCitizen
        ? data.complaints.where((c) {
            final userPhoneClean = auth.currentUser.phone.replaceAll(RegExp(r'\D'), '');
            final compPhoneClean = c.submittedByPhone.replaceAll(RegExp(r'\D'), '');
            final matchesPhone = userPhoneClean.isNotEmpty &&
                compPhoneClean.isNotEmpty &&
                (userPhoneClean == compPhoneClean ||
                 userPhoneClean.endsWith(compPhoneClean) ||
                 compPhoneClean.endsWith(userPhoneClean));
            final matchesId = c.submittedById.isNotEmpty && c.submittedById == auth.currentUser.id;
            final matchesName = c.submittedByName.trim().toLowerCase() == auth.currentUser.name.trim().toLowerCase();
            return matchesId || matchesPhone || matchesName;
          }).toList()
        : data.complaints;

    return Scaffold(
      body: complaints.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No active complaints or inquiries found'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (_) => const NewComplaintDialog());
                    },
                    child: const Text('File an Inquiry'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: complaints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = complaints[index];
                return _buildComplaintCard(
                    context, c, auth, data, langTheme, isDark);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const NewComplaintDialog(),
          );
        },
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(langTheme.tr('submitComplaint')),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildComplaintCard(
    BuildContext context,
    ComplaintModel complaint,
    AuthProvider auth,
    VarganiDataProvider data,
    LanguageThemeProvider langTheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complaint.status == ComplaintStatus.resolved
              ? AppColors.statusPaid.withOpacity(0.5)
              : complaint.isEscalated
                  ? Colors.purple.withOpacity(0.5)
                  : isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket: ${complaint.id.toUpperCase()}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey),
              ),
              _buildComplaintStatusBadge(complaint.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            complaint.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_pin_rounded,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'By ${complaint.submittedByName} (${auth.isCitizen ? complaint.submittedByPhone : '••••••${complaint.submittedByPhone.substring(complaint.submittedByPhone.length - 4)}'})',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              Text(langTheme.formatDate(complaint.submittedDate),
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),

          // Admin Response Thread
          if (complaint.adminResponse != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_rounded,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Official Committee Response:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(complaint.adminResponse!,
                      style: const TextStyle(fontSize: 12)),
                  if (complaint.resolvedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                        'Resolved at: ${langTheme.formatDate(complaint.resolvedDate!)}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.statusPaid)),
                  ],
                ],
              ),
            ),
          ],

          // Action Buttons: Admin Response & Super Admin Escalation (SRS 10)
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Escalation Button (SRS 10)
              if (!complaint.isEscalated &&
                  complaint.status != ComplaintStatus.resolved)
                TextButton.icon(
                  onPressed: () {
                    data.escalateComplaintToSuperAdmin(
                      complaintId: complaint.id,
                      currentUser: auth.currentUser,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Complaint escalated to Super Admin review.'),
                        backgroundColor: Colors.purple,
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_upward_rounded,
                      size: 14, color: Colors.purple),
                  label: const Text('Escalate to Super Admin',
                      style: TextStyle(fontSize: 11, color: Colors.purple)),
                ),

              // Admin Reply / Resolve Action
              if (auth.canManageCampaigns &&
                  complaint.status != ComplaintStatus.resolved) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      _showAdminReplyDialog(context, complaint, data, auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Reply & Resolve',
                      style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintStatusBadge(ComplaintStatus status) {
    Color color;
    switch (status) {
      case ComplaintStatus.resolved:
        color = AppColors.statusPaid;
        break;
      case ComplaintStatus.escalated:
        color = Colors.purple;
        break;
      case ComplaintStatus.underReview:
        color = Colors.blue;
        break;
      case ComplaintStatus.actionTaken:
        color = Colors.amber;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.displayName,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAdminReplyDialog(
    BuildContext context,
    ComplaintModel complaint,
    VarganiDataProvider data,
    AuthProvider auth,
  ) {
    final responseController = TextEditingController();
    ComplaintStatus newStatus = ComplaintStatus.resolved;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Respond to: ${complaint.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: responseController,
                maxLines: 3,
                decoration: const InputDecoration(
                  label: MandatoryLabel('Committee Response'),
                  hintText: 'Provide explanation or correction details...',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ComplaintStatus>(
                value: newStatus,
                decoration:
                    const InputDecoration(labelText: 'Status after response'),
                items: [
                  ComplaintStatus.underReview,
                  ComplaintStatus.actionTaken,
                  ComplaintStatus.resolved,
                  ComplaintStatus.rejectedWithReason,
                ]
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.displayName)))
                    .toList(),
                onChanged: (s) {
                  if (s != null) setDialogState(() => newStatus = s);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (responseController.text.trim().isNotEmpty) {
                  data.respondToComplaint(
                    complaintId: complaint.id,
                    response: responseController.text.trim(),
                    status: newStatus,
                    currentUser: auth.currentUser,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Submit Response'),
            ),
          ],
        ),
      ),
    );
  }
}
