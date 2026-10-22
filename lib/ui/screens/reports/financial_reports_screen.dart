import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/payment_model.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/stat_card.dart';

class FinancialReportsScreen extends StatelessWidget {
  const FinancialReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Export Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Audit & Reports (SRS 11)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Campaign: ${data.currentCampaign.name}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final csvData = data.generateHouseholdsCsv();
                    Clipboard.setData(ClipboardData(text: csvData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Household & Collection CSV data copied to clipboard! (SRS 11)'),
                        backgroundColor: AppColors.statusPaid,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Key Summary KPI Grid
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Expected (Dues)',
                    value: currencyFormat.format(data.totalExpectedVargani),
                    subtitle: 'From ${data.households.length} families',
                    icon: Icons.pie_chart_rounded,
                    accentColor: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Verified Received',
                    value: currencyFormat.format(data.totalVerifiedReceived),
                    subtitle: 'Verified bank/cash',
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
                    title: 'Approved Expenses',
                    value: currencyFormat.format(data.totalApprovedExpenses),
                    subtitle: 'Sanctioned committee bills',
                    icon: Icons.receipt_rounded,
                    accentColor: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Net Available Balance',
                    value: currencyFormat.format(data.availableNetBalance),
                    subtitle: 'Received − Disbursed',
                    icon: Icons.savings_rounded,
                    accentColor: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Payment Mode Donut Chart (fl_chart)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Mode Distribution (SRS 11)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              sections: [
                                PieChartSectionData(
                                  value: (data.paymentBreakdown[PaymentType.cash] ?? 1.0) + 0.1,
                                  title: 'Cash',
                                  color: AppColors.primary,
                                  radius: 40,
                                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  value: (data.paymentBreakdown[PaymentType.upi] ?? 1.0) + 0.1,
                                  title: 'UPI',
                                  color: AppColors.statusPaid,
                                  radius: 40,
                                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  value: (data.paymentBreakdown[PaymentType.bankTransfer] ?? 1.0) + 0.1,
                                  title: 'Bank',
                                  color: AppColors.secondaryLight,
                                  radius: 40,
                                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem('Cash', AppColors.primary, data.paymentBreakdown[PaymentType.cash] ?? 0.0, currencyFormat),
                            const SizedBox(height: 8),
                            _buildLegendItem('UPI / QR', AppColors.statusPaid, data.paymentBreakdown[PaymentType.upi] ?? 0.0, currencyFormat),
                            const SizedBox(height: 8),
                            _buildLegendItem('Bank Transfer', AppColors.secondaryLight, data.paymentBreakdown[PaymentType.bankTransfer] ?? 0.0, currencyFormat),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Collector Performance Breakdown (SRS 11)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Collector-wise Collection Summary (SRS 11)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  _buildCollectorRow('Rohan Gaikwad', 3, 800.0, currencyFormat),
                  const Divider(height: 16),
                  _buildCollectorRow('Pooja Sawant', 2, 1100.0, currencyFormat),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // System Audit Log Stream (SRS 12 FR-15)
            Text(
              'Audit Trail (SRS 12 FR-15)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.auditLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = data.auditLogs[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.details, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(
                              'Action: ${log.action} • By ${log.performedByName} • ${DateFormat('dd MMM, hh:mm a').format(log.timestamp)}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double amount, NumberFormat currencyFormat) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(currencyFormat.format(amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildCollectorRow(String name, int records, double amount, NumberFormat currencyFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('$records Collections Recorded', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        Text(
          currencyFormat.format(amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.statusPaid),
        ),
      ],
    );
  }
}
