import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/expense_model.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import 'add_expense_dialog.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      body: Column(
        children: [
          // Header Summary Card (SRS 8: Distinguish Approved Expenses from Actual Paid)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Approved Expenses', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          currencyFormat.format(data.totalApprovedExpenses),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusPending.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.statusPending.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Actual Paid Expenses', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          currencyFormat.format(data.totalActualPaidExpenses),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.statusPending),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expense Items List
          Expanded(
            child: data.expenses.isEmpty
                ? const Center(child: Text('No expenses recorded for this campaign'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final exp = data.expenses[index];
                      return _buildExpenseCard(context, exp, auth, data, currencyFormat, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: auth.currentRole != UserRole.citizen
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddExpenseDialog(),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    ExpenseModel exp,
    AuthProvider auth,
    VarganiDataProvider data,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exp.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Text(
                currencyFormat.format(exp.amount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exp.category.displayName.split('(').first.trim(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${exp.vendorPayee} • Bill: ${exp.billNumber}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              Text(dateFormat.format(exp.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),

          // SRS 8 Requirements: Proof Not Uploaded indicator & Approval status
          Row(
            children: [
              // Proof badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: exp.hasProof ? AppColors.statusPaid.withOpacity(0.12) : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: exp.hasProof ? AppColors.statusPaid : Colors.orange),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      exp.hasProof ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                      size: 11,
                      color: exp.hasProof ? AppColors.statusPaid : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      exp.hasProof ? 'Proof Uploaded' : 'Proof Not Uploaded (SRS 8)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: exp.hasProof ? AppColors.statusPaid : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Approval status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: exp.approvalStatus == ExpenseApprovalStatus.approved
                      ? AppColors.statusPaid.withOpacity(0.12)
                      : exp.approvalStatus == ExpenseApprovalStatus.rejected
                          ? Colors.red.withOpacity(0.12)
                          : Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exp.approvalStatus.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: exp.approvalStatus == ExpenseApprovalStatus.approved
                        ? AppColors.statusPaid
                        : exp.approvalStatus == ExpenseApprovalStatus.rejected
                            ? Colors.red
                            : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),

          // Review Actions for Treasurer or Admin
          if (exp.approvalStatus == ExpenseApprovalStatus.pending && auth.canApproveExpenses) ...[
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    data.updateExpenseApproval(
                      expenseId: exp.id,
                      status: ExpenseApprovalStatus.rejected,
                      currentUser: auth.currentUser,
                    );
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    data.updateExpenseApproval(
                      expenseId: exp.id,
                      status: ExpenseApprovalStatus.approved,
                      currentUser: auth.currentUser,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense Approved!'),
                        backgroundColor: AppColors.statusPaid,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusPaid),
                  child: const Text('Approve Expense'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
