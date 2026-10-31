import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/models/cash_handover_model.dart';
import '../../../core/models/campaign_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../households/household_form_dialog.dart';
import '../collections/new_collection_dialog.dart';
import '../expenses/add_expense_dialog.dart';
import '../handovers/cash_handover_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<VarganiDataProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final lang = langTheme.localizations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Campaign Banner Card
            _buildCampaignBanner(context, data, currencyFormat, isDark),
            const SizedBox(height: 16),

            // Role-Specific Action Banner
            if (auth.currentRole == UserRole.collector)
              _buildCollectorHighlight(
                  context, auth, data, currencyFormat, lang, isDark)
            else if (auth.currentRole == UserRole.treasurer)
              _buildTreasurerHighlight(
                  context, auth, data, currencyFormat, lang, isDark)
            else if (auth.currentRole == UserRole.citizen)
              _buildCitizenHighlight(
                  context, auth, data, currencyFormat, lang, isDark),

            const SizedBox(height: 16),

            // Main KPI Grid (SRS 2 & 11)
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: lang.tr('expectedTotal'),
                    value: currencyFormat.format(data.totalExpectedVargani),
                    subtitle: '${data.households.length} Households registered',
                    icon: Icons.assignment_outlined,
                    accentColor: AppColors.secondaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: lang.tr('verifiedReceived'),
                    value: currencyFormat.format(data.totalVerifiedReceived),
                    subtitle:
                        '${data.totalExpectedVargani > 0 ? ((data.totalVerifiedReceived / data.totalExpectedVargani) * 100).toStringAsFixed(1) : 0}% Collected',
                    icon: Icons.account_balance_wallet_rounded,
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
                    title: lang.tr('remainingAmount'),
                    value: currencyFormat.format(data.totalRemainingDue),
                    subtitle: 'Pending collection',
                    icon: Icons.timelapse_rounded,
                    accentColor: AppColors.statusPending,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: lang.tr('availableBalance'),
                    value: currencyFormat.format(data.availableNetBalance),
                    subtitle: 'Received - Actual Paid',
                    icon: Icons.savings_rounded,
                    accentColor: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions Bar (For staff roles)
            if (auth.currentRole != UserRole.citizen &&
                _hasQuickActionPermissions(auth)) ...[
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionsRow(context, auth, data, isDark),
              const SizedBox(height: 24),
            ],

            // Payment Mode Breakdown & Visual Chart
            _buildPaymentTypeBreakdown(context, data, currencyFormat, isDark),
            const SizedBox(height: 24),

            // Recent Collections Feed
            _buildRecentCollections(context, data, langTheme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignBanner(
    BuildContext context,
    VarganiDataProvider data,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final campaign = data.currentCampaign;
    final progress = campaign.targetAmount > 0
        ? (data.totalVerifiedReceived / campaign.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.saffronRoyalGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.festival_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      campaign.varganiType.displayName.split('(').first.trim(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              // Campaign Selector Dropdown
              PopupMenuButton<String>(
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white),
                tooltip: 'Select Campaign',
                onSelected: (id) => data.selectCampaign(id),
                itemBuilder: (context) {
                  return data.campaigns.map((c) {
                    return PopupMenuItem<String>(
                      value: c.id,
                      child: Text(c.name,
                          style: TextStyle(
                              fontWeight: c.id == campaign.id
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    );
                  }).toList();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            campaign.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Per Person Rate: ₹${campaign.perPersonRate.toStringAsFixed(0)} | Target: ${currencyFormat.format(campaign.targetAmount)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Raised: ${currencyFormat.format(data.totalVerifiedReceived)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% of Target',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectorHighlight(
    BuildContext context,
    AuthProvider auth,
    VarganiDataProvider data,
    NumberFormat currencyFormat,
    dynamic lang,
    bool isDark,
  ) {
    final cashBalance = data.getPersonCashBalance(auth.currentUser.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wallet_rounded,
                color: AppColors.secondaryLight, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Cash in Hand (SRS 6.3)',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryLight),
                ),
                Text(
                  currencyFormat.format(cashBalance),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Text(
                  'Cash Collected − Confirmed Handovers',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashHandoverScreen()),
              );
            },
            icon: const Icon(Icons.arrow_upward_rounded, size: 16),
            label: const Text('Handover'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasurerHighlight(
    BuildContext context,
    AuthProvider auth,
    VarganiDataProvider data,
    NumberFormat currencyFormat,
    dynamic lang,
    bool isDark,
  ) {
    final pendingHandovers = data.handovers
        .where((h) => h.status == HandoverStatus.pending)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pending_actions_rounded,
                color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pendingHandovers.length} Pending Cash Handover(s)',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total pending: ${currencyFormat.format(pendingHandovers.fold(0.0, (s, h) => s + h.amount))}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CashHandoverScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildCitizenHighlight(
    BuildContext context,
    AuthProvider auth,
    VarganiDataProvider data,
    NumberFormat currencyFormat,
    dynamic lang,
    bool isDark,
  ) {
    final citizenHousehold = data.households.firstWhere(
      (h) =>
          h.mobileNumber.contains('9823401122') ||
          h.headOfFamilyName.contains('Rahul Patil'),
      orElse: () => data.households.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusPaid.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Household Status (Rahul Patil)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              StatusBadge.fromPaymentStatus(citizenHousehold.paymentStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${citizenHousehold.familyMemberCount} Family Members × ₹${citizenHousehold.perPersonRateSnapshot.toStringAsFixed(0)} = ${currencyFormat.format(citizenHousehold.expectedTotalVargani)} Expected',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Paid: ${currencyFormat.format(citizenHousehold.amountReceived)} | Remaining: ${currencyFormat.format(citizenHousehold.remainingAmount)}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  bool _hasQuickActionPermissions(AuthProvider auth) {
    return auth.hasPermission('households.create') ||
        auth.hasPermission('collections.create') ||
        auth.hasPermission('handovers.view') ||
        auth.hasPermission('handovers.create') ||
        auth.hasPermission('expenses.create') ||
        auth.hasPermission('expenses.view');
  }

  Widget _buildQuickActionsRow(
    BuildContext context,
    AuthProvider auth,
    VarganiDataProvider data,
    bool isDark,
  ) {
    final actions = <Widget>[];

    if (auth.hasPermission('households.create')) {
      actions.add(_buildActionBtn(
        context,
        icon: Icons.person_add_alt_1_rounded,
        label: 'Add House',
        color: AppColors.primary,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => const HouseholdFormDialog(),
          );
        },
      ));
    }

    if (auth.hasPermission('collections.create')) {
      actions.add(_buildActionBtn(
        context,
        icon: Icons.receipt_long_rounded,
        label: 'Collect',
        color: AppColors.statusPaid,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => const NewCollectionDialog(),
          );
        },
      ));
    }

    if (auth.hasPermission('handovers.view') ||
        auth.hasPermission('handovers.create')) {
      actions.add(_buildActionBtn(
        context,
        icon: Icons.currency_exchange_rounded,
        label: 'Handover',
        color: AppColors.secondaryLight,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CashHandoverScreen()),
          );
        },
      ));
    }

    if (auth.hasPermission('expenses.create') ||
        auth.hasPermission('expenses.view')) {
      actions.add(_buildActionBtn(
        context,
        icon: Icons.receipt_rounded,
        label: 'Expense',
        color: Colors.purple,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => const AddExpenseDialog(),
          );
        },
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeBreakdown(
    BuildContext context,
    VarganiDataProvider data,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final breakdown = data.paymentBreakdown;
    final total = data.totalVerifiedReceived;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collection Modes (SRS 6 & 11)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                currencyFormat.format(total),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.statusPaid),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress breakdown bars
          _buildBreakdownItem('Cash', breakdown[PaymentType.cash] ?? 0.0, total,
              AppColors.primary, currencyFormat),
          const SizedBox(height: 10),
          _buildBreakdownItem('UPI / QR', breakdown[PaymentType.upi] ?? 0.0,
              total, AppColors.accentEmerald, currencyFormat),
          const SizedBox(height: 10),
          _buildBreakdownItem(
              'Bank Transfer',
              breakdown[PaymentType.bankTransfer] ?? 0.0,
              total,
              AppColors.secondaryLight,
              currencyFormat),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double amount,
    double total,
    Color color,
    NumberFormat currencyFormat,
  ) {
    final percentage = total > 0 ? (amount / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text(
              '${currencyFormat.format(amount)} (${(percentage * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCollections(
    BuildContext context,
    VarganiDataProvider data,
    LanguageThemeProvider langTheme,
    bool isDark,
  ) {
    final recentPayments = data.payments.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Collections (SRS 6)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              '${data.payments.length} Records',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentPayments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final p = recentPayments[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.paymentType == PaymentType.cash
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.statusPaid.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      p.paymentType == PaymentType.cash
                          ? Icons.money_rounded
                          : Icons.qr_code_2_rounded,
                      color: p.paymentType == PaymentType.cash
                          ? AppColors.primary
                          : AppColors.statusPaid,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.householdHeadName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${p.receiptNo} • ${p.paymentType.displayName} • By ${p.collectedByName}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        langTheme.formatCurrency(p.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.statusPaid),
                      ),
                      Text(
                        langTheme.formatDate(p.collectionDateTime),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
