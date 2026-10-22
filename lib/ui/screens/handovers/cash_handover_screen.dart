import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/cash_handover_model.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/stat_card.dart';

class CashHandoverScreen extends StatefulWidget {
  const CashHandoverScreen({super.key});

  @override
  State<CashHandoverScreen> createState() => _CashHandoverScreenState();
}

class _CashHandoverScreenState extends State<CashHandoverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final userCashBalance = data.getPersonCashBalance(auth.currentUser.id);
    final pendingHandovers = data.handovers.where((h) => h.status == HandoverStatus.pending).toList();
    final confirmedHandovers = data.handovers.where((h) => h.status != HandoverStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Handover Ledger (SRS 6.3)'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Pending (${pendingHandovers.length})'),
            Tab(text: 'History (${confirmedHandovers.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Cash in Hand Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Your Cash In Hand (SRS 6.3)',
                    value: currencyFormat.format(userCashBalance),
                    subtitle: 'Cash Collected − Confirmed Handovers',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppColors.primary,
                  ),
                ),
                if (auth.canConfirmHandover) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Treasurer Vault Cash',
                      value: currencyFormat.format(data.getTreasurerCashInHand(auth.currentUser.id)),
                      subtitle: 'Handovers In − Cash Paid Out',
                      icon: Icons.savings_rounded,
                      accentColor: AppColors.statusPaid,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pending Tab
                pendingHandovers.isEmpty
                    ? const Center(child: Text('No pending handovers to confirm'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: pendingHandovers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildHandoverCard(
                            context,
                            handover: pendingHandovers[index],
                            auth: auth,
                            data: data,
                            currencyFormat: currencyFormat,
                            isDark: isDark,
                          );
                        },
                      ),

                // History Tab
                confirmedHandovers.isEmpty
                    ? const Center(child: Text('No past handover history'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: confirmedHandovers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildHandoverCard(
                            context,
                            handover: confirmedHandovers[index],
                            auth: auth,
                            data: data,
                            currencyFormat: currencyFormat,
                            isDark: isDark,
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInitiateHandoverDialog(context, auth, data, userCashBalance),
        icon: const Icon(Icons.arrow_upward_rounded),
        label: const Text('Initiate Handover'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHandoverCard(
    BuildContext context, {
    required CashHandoverModel handover,
    required AuthProvider auth,
    required VarganiDataProvider data,
    required NumberFormat currencyFormat,
    required bool isDark,
  }) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isReceiver = auth.currentUser.id == handover.handoverToId || auth.canConfirmHandover;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: handover.status == HandoverStatus.confirmed
              ? AppColors.statusPaid.withOpacity(0.5)
              : handover.status == HandoverStatus.rejected
                  ? Colors.red.withOpacity(0.5)
                  : Colors.amber.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Handover ${handover.id}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              _buildHandoverStatusBadge(handover.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                currencyFormat.format(handover.amount),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const Spacer(),
              Text(dateFormat.format(handover.dateTime), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text('From: ${handover.handoverFromName}', style: const TextStyle(fontSize: 13)),
          Text('To: ${handover.handoverToName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (handover.remarks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${handover.remarks}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],

          // Confirmation Action Buttons (SRS 6.3: "The receiver must confirm actual receipt before status becomes Confirmed")
          if (handover.status == HandoverStatus.pending && isReceiver) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    data.processHandover(
                      handoverId: handover.id,
                      approve: false,
                      confirmedByUser: auth.currentUser,
                    );
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    data.processHandover(
                      handoverId: handover.id,
                      approve: true,
                      confirmedByUser: auth.currentUser,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Confirmed receipt of ${currencyFormat.format(handover.amount)}!'),
                        backgroundColor: AppColors.statusPaid,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Confirm Cash Received'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPaid),
                ),
              ],
            ),
          ] else if (handover.status == HandoverStatus.confirmed) ...[
            const SizedBox(height: 6),
            Text(
              'Confirmed by ${handover.confirmedByName ?? 'Treasurer'} at ${handover.confirmedAt != null ? dateFormat.format(handover.confirmedAt!) : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.statusPaid),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHandoverStatusBadge(HandoverStatus status) {
    switch (status) {
      case HandoverStatus.confirmed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.statusPaid.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Text('Confirmed', style: TextStyle(color: AppColors.statusPaid, fontSize: 11, fontWeight: FontWeight.bold)),
        );
      case HandoverStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Text('Rejected', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
        );
      case HandoverStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Text('Pending Confirmation', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
        );
    }
  }

  void _showInitiateHandoverDialog(
    BuildContext context,
    AuthProvider auth,
    VarganiDataProvider data,
    double userCashBalance,
  ) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: userCashBalance > 0 ? userCashBalance.toStringAsFixed(0) : '');
    final remarksController = TextEditingController();

    final orgTreasurers = auth.availableUsers.where((u) => u.role == UserRole.treasurer || u.role == UserRole.orgAdmin).toList();
    UserModel selectedToUser = orgTreasurers.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Submit Cash Handover'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Handover From: ${auth.currentUser.name} (Current User)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserModel>(
                  value: selectedToUser,
                  decoration: const InputDecoration(labelText: 'Handover To (Receiver) *'),
                  items: orgTreasurers.map((u) {
                    return DropdownMenuItem<UserModel>(
                      value: u,
                      child: Text('${u.name} (${u.role.nameString})'),
                    );
                  }).toList(),
                  onChanged: (u) {
                    if (u != null) setDialogState(() => selectedToUser = u);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹) *',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                  validator: (v) {
                    final parsed = double.tryParse(v ?? '');
                    if (parsed == null || parsed <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks / Handover Note',
                    hintText: 'e.g. Day 1 collection cash envelope',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  data.submitCashHandover(
                    fromUser: auth.currentUser,
                    toUser: selectedToUser,
                    amount: double.parse(amountController.text.trim()),
                    remarks: remarksController.text.trim(),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Submit Handover'),
            ),
          ],
        ),
      ),
    );
  }
}
