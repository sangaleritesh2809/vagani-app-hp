import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/payment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import 'receipt_detail_dialog.dart';
import 'new_collection_dialog.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<VarganiDataProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final receipts = data.receipts.where((r) {
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return r.receiptNo.toLowerCase().contains(q) ||
            r.householdHeadName.toLowerCase().contains(q) ||
            (r.referenceId ?? '').toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
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
            child: TextField(
              onChanged: (val) => setState(() => _search = val),
              decoration: const InputDecoration(
                hintText:
                    'Search by receipt number (e.g. VRG-2026-0001) or head name...',
                prefixIcon: Icon(Icons.search_rounded),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: receipts.isEmpty
                ? const Center(child: Text('No receipts found'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: receipts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = receipts[index];
                      return InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => ReceiptDetailDialog(receipt: r),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCardBg
                                : AppColors.lightCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: r.isCancelled
                                  ? Colors.red.withOpacity(0.5)
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: r.isCancelled
                                      ? Colors.red.withOpacity(0.12)
                                      : AppColors.statusPaid.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  r.isCancelled
                                      ? Icons.cancel_outlined
                                      : Icons.receipt_rounded,
                                  color: r.isCancelled
                                      ? Colors.red
                                      : AppColors.statusPaid,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.householdHeadName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          r.receiptNo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: r.isCancelled
                                                ? Colors.red
                                                : AppColors.primary,
                                          ),
                                        ),
                                        if (r.isCancelled) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                                color: Colors.red
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: const Text('CANCELLED',
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${r.paymentType.displayName} • By ${r.collectedByName} • ${langTheme.formatDate(r.issuedAt)}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    langTheme.formatCurrency(r.amountReceived),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: r.isCancelled
                                          ? Colors.grey
                                          : AppColors.statusPaid,
                                      decoration: r.isCancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 12, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: (auth.isCitizen || auth.isPublicUser || !auth.canCollectVargani)
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const NewCollectionDialog(),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Receipt'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
    );
  }
}
