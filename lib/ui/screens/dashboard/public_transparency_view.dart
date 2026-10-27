import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/models/expense_model.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/stat_card.dart';
import '../complaints/new_complaint_dialog.dart';

class PublicTransparencyView extends StatelessWidget {
  const PublicTransparencyView({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Only publicly visible expenses (SRS 9)
    final publicExpenses =
        data.expenses.where((e) => e.isPublicVisible).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Public Trust Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PUBLIC FINANCIAL TRANSPARENCY',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            Text(
                              'Verified Citizen & Donor Portal (SRS 9)',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.organization.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    'Reg: ${data.organization.registrationNumber} • ${data.organization.village}, Pune',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const Divider(color: Colors.white24, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Campaign: ${data.currentCampaign.name}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'As on: ${langTheme.formatDate(DateTime.now())}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Mandatory 5 SRS 9 Financial Metric Labels:
            // "Clearly label expected collection, verified money received, approved expense, actual paid expense, and calculated balance."
            const Text(
              'Mandatory Financial Balance Reconciliation (SRS 9)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: '1. ${langTheme.tr('expectedTotal')}',
                    value: langTheme.formatCurrency(data.totalExpectedVargani),
                    subtitle: 'Total budgeted dues',
                    icon: Icons.track_changes_rounded,
                    accentColor: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: '2. ${langTheme.tr('verifiedReceived')}',
                    value: langTheme.formatCurrency(data.totalVerifiedReceived),
                    subtitle: 'Total verified in bank/cash',
                    icon: Icons.check_circle_rounded,
                    accentColor: AppColors.statusPaid,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: '3. ${langTheme.tr('approvedExpenses')}',
                    value: langTheme.formatCurrency(data.totalApprovedExpenses),
                    subtitle: 'Sanctioned committee costs',
                    icon: Icons.rule_rounded,
                    accentColor: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: '4. ${langTheme.tr('paidExpenses')}',
                    value:
                        langTheme.formatCurrency(data.totalActualPaidExpenses),
                    subtitle: 'Disbursed vendor bills',
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppColors.statusPending,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatCard(
              title: '5. ${langTheme.tr('availableBalance')}',
              value: langTheme.formatCurrency(data.availableNetBalance),
              subtitle:
                  '${langTheme.tr('verifiedReceived')} − ${langTheme.tr('paidExpenses')}',
              icon: Icons.account_balance_rounded,
              accentColor: AppColors.primary,
            ),

            const SizedBox(height: 24),

            // Collection Breakdown by Payment Mode (SRS 9)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verified Collections by Payment Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniBadge(
                          'Cash',
                          data.paymentBreakdown[PaymentType.cash] ?? 0.0,
                          AppColors.primary,
                          currencyFormat),
                      _buildMiniBadge(
                          'UPI / QR',
                          data.paymentBreakdown[PaymentType.upi] ?? 0.0,
                          AppColors.statusPaid,
                          currencyFormat),
                      _buildMiniBadge(
                          'Bank Transfer',
                          data.paymentBreakdown[PaymentType.bankTransfer] ??
                              0.0,
                          AppColors.secondaryLight,
                          currencyFormat),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Published Approved Expenses (No private bank details, SRS 9)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Published Approved Expenses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text('${publicExpenses.length} Items',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: publicExpenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final e = publicExpenses[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_rounded,
                            size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                                '${e.category.displayName.split('(').first.trim()} • Vendor: ${e.vendorPayee}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            langTheme.formatCurrency(e.amount),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: e.hasProof
                                  ? AppColors.statusPaid.withOpacity(0.12)
                                  : Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e.hasProof ? 'Proof Verified' : 'Proof Pending',
                              style: TextStyle(
                                fontSize: 9,
                                color: e.hasProof
                                    ? AppColors.statusPaid
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // File a Complaint / Inquiry Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.secondaryLight.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded,
                      color: AppColors.secondaryLight, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Have a Question or Discrepancy?',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                            'File a tracked inquiry or grievance directly with the committee.',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const NewComplaintDialog(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary),
                    child: const Text('Inquire / Grievance',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(
      String label, double amount, Color color, NumberFormat currencyFormat) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: color),
        ),
      ],
    );
  }
}
