import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/cash_handover_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/mock_data_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/mandatory_label.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/empty_state_widget.dart';

class CashHandoverScreen extends StatefulWidget {
  const CashHandoverScreen({super.key});

  @override
  State<CashHandoverScreen> createState() => _CashHandoverScreenState();
}

class _CashHandoverScreenState extends State<CashHandoverScreen>
    with SingleTickerProviderStateMixin {
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
    final langTheme = context.watch<LanguageThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userCashBalance = data.getPersonCashBalance(auth.currentUser.id);
    final pendingHandovers = data.handovers
        .where((h) => h.status == HandoverStatus.pending)
        .toList();
    final confirmedHandovers = data.handovers
        .where((h) => h.status != HandoverStatus.pending)
        .toList();

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
              border: Border(
                  bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Your Cash In Hand (SRS 6.3)',
                    value: langTheme.formatCurrency(userCashBalance),
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
                      value: langTheme.formatCurrency(
                          data.getTreasurerCashInHand(auth.currentUser.id)),
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
                    ? const EmptyStateWidget(
                        title: 'No pending handovers',
                        subtitle:
                            'All cash collections have been reconciled and confirmed.',
                        imageAsset: 'assets/images/not_found.png',
                      )
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
                            langTheme: langTheme,
                            isDark: isDark,
                          );
                        },
                      ),

                // History Tab
                confirmedHandovers.isEmpty
                    ? const EmptyStateWidget(
                        title: 'No handover history',
                        subtitle: 'No past completed cash handovers found.',
                        imageAsset: 'assets/images/not_found.png',
                      )
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
                            langTheme: langTheme,
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
        onPressed: () =>
            _showInitiateHandoverDialog(context, auth, data, userCashBalance),
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
    required LanguageThemeProvider langTheme,
    required bool isDark,
  }) {
    final isReceiver =
        auth.currentUser.id == handover.handoverToId || auth.canConfirmHandover;

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
                '${langTheme.tr('handover')} ${handover.id}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey),
              ),
              _buildHandoverStatusBadge(handover.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                langTheme.formatCurrency(handover.amount),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const Spacer(),
              Text(langTheme.formatDate(handover.dateTime),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${langTheme.tr('handoverFrom')}: ${handover.handoverFromName}',
              style: const TextStyle(fontSize: 13)),
          Text('${langTheme.tr('handoverTo')}: ${handover.handoverToName}',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (handover.remarks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Note: ${handover.remarks}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                        content: Text(
                            'Confirmed receipt of ${langTheme.formatCurrency(handover.amount)}!'),
                        backgroundColor: AppColors.statusPaid,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Confirm Cash Received'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusPaid),
                ),
              ],
            ),
          ] else if (handover.status == HandoverStatus.confirmed) ...[
            const SizedBox(height: 6),
            Text(
              'Confirmed by ${handover.confirmedByName ?? 'Treasurer'} at ${handover.confirmedAt != null ? langTheme.formatDate(handover.confirmedAt!) : ''}',
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
          decoration: BoxDecoration(
              color: AppColors.statusPaid.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Text('Confirmed',
              style: TextStyle(
                  color: AppColors.statusPaid,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        );
      case HandoverStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Text('Rejected',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        );
      case HandoverStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: const Text('Pending Confirmation',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
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
    final amountController = TextEditingController(
        text: userCashBalance > 0 ? userCashBalance.toStringAsFixed(0) : '');
    final remarksController = TextEditingController();

    // Safely collect eligible handover receivers strictly scoped to active organization
    final seenIds = <String>{auth.currentUser.id};
    final eligibleReceivers = <UserModel>[];
    final activeOrgId =
        auth.selectedOrganization?.id ?? auth.currentUser.organizationId;
    final isSuper = auth.isSuperAdmin;

    // 1. All active members of the current active organization with staff roles
    for (final u in auth.availableUsers) {
      if (seenIds.contains(u.id)) continue;
      if (!u.isActive) continue;

      // Super Admin is never shown to other roles
      if (!isSuper && (u.isSuperAdmin || u.role == UserRole.superAdmin)) {
        continue;
      }

      // Must belong to this active organization
      if (u.organizationId.isNotEmpty && u.organizationId != activeOrgId) {
        continue;
      }

      // Any staff/committee member: Treasurer, Org Admin, Group Admin, etc.
      if (u.role == UserRole.treasurer ||
          u.role == UserRole.orgAdmin ||
          u.role == UserRole.groupAdmin ||
          (isSuper && u.role == UserRole.superAdmin) ||
          (u.role != UserRole.citizen && u.role != UserRole.publicUser)) {
        seenIds.add(u.id);
        eligibleReceivers.add(u);
      }
    }

    // 2. Default fallback organization committee receivers if no other staff added yet
    if (eligibleReceivers.isEmpty) {
      eligibleReceivers.add(
        UserModel(
          id: 'usr_default_treasurer_$activeOrgId',
          name: 'Mandal Treasurer (खजिनदार)',
          phone: '',
          email: 'treasurer@mandal.org',
          organizationId: activeOrgId,
          role: UserRole.treasurer,
          accountStatus: 'active',
          isActive: true,
        ),
      );
      eligibleReceivers.add(
        UserModel(
          id: 'usr_default_admin_$activeOrgId',
          name: 'Mandal President / Admin (अध्यक्ष)',
          phone: '',
          email: 'admin@mandal.org',
          organizationId: activeOrgId,
          role: UserRole.orgAdmin,
          accountStatus: 'active',
          isActive: true,
        ),
      );
    }

    UserModel selectedToUser = eligibleReceivers.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Submit Cash Handover',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Handover From: ${auth.currentUser.name} (${auth.currentUser.role.nameString})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Handover To (Receiver) - Label outside input box
                  const MandatoryLabel('Handover To (Receiver)'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserModel>(
                    value: selectedToUser,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    items: eligibleReceivers.map((u) {
                      return DropdownMenuItem<UserModel>(
                        value: u,
                        child: Text(
                          '${u.name} (${u.role.nameString})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (u) {
                      if (u != null) setDialogState(() => selectedToUser = u);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount - Label outside input box
                  const MandatoryLabel('Amount (₹)'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter amount to handover',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                      helperText: userCashBalance > 0
                          ? 'Available Cash in Hand: ₹${userCashBalance.toStringAsFixed(0)}'
                          : null,
                    ),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Remarks - Label outside input box
                  const Text(
                    'Remarks / Handover Note',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: remarksController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Day 1 collection cash envelope',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final amt = double.parse(amountController.text.trim());
                  data.submitCashHandover(
                    fromUser: auth.currentUser,
                    toUser: selectedToUser,
                    amount: amt,
                    remarks: remarksController.text.trim(),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cash handover of ₹${amt.toStringAsFixed(0)} submitted successfully!',
                      ),
                      backgroundColor: AppColors.statusPaid,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
