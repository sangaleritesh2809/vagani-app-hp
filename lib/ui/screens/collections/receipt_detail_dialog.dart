import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';

class ReceiptDetailDialog extends StatelessWidget {
  final ReceiptModel receipt;

  const ReceiptDetailDialog({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Current version in state
    final currentReceipt = data.receipts.firstWhere(
      (r) => r.id == receipt.id,
      orElse: () => receipt,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header with Close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentReceipt.receiptNo,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Receipt Slip Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentReceipt.isCancelled ? Colors.red : const Color(0xFFFDE68A),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Mandal Name & Reg
                      Text(
                        data.organization.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Reg: ${data.organization.registrationNumber} • ${data.organization.village}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Divider(height: 20),

                      // Cancelled Watermark or Status
                      if (currentReceipt.isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            'CANCELLED / REVERSED: ${currentReceipt.cancellationReason}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),

                      // Receipt Details Rows
                      _buildReceiptRow('Campaign', currentReceipt.campaignName),
                      _buildReceiptRow('Head of Family', currentReceipt.householdHeadName),
                      _buildReceiptRow('Members & Rate', '${currentReceipt.familyMemberCount} × ₹${currentReceipt.perPersonRate.toStringAsFixed(0)}'),
                      _buildReceiptRow('Payment Mode', currentReceipt.paymentType.displayName),
                      if (currentReceipt.referenceId != null)
                        _buildReceiptRow('Transaction Ref', currentReceipt.referenceId!),
                      _buildReceiptRow('Date & Time', dateFormat.format(currentReceipt.issuedAt)),
                      _buildReceiptRow('Collected By', currentReceipt.collectedByName),
                      _buildReceiptRow('Received By', currentReceipt.receivedByName),

                      const SizedBox(height: 12),

                      // Big Amount Highlight
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'AMOUNT RECEIVED:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              currencyFormat.format(currentReceipt.amountReceived),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // QR Verification Code
                      Center(
                        child: Column(
                          children: [
                            QrImageView(
                              data: 'VRG-VERIFY:${currentReceipt.receiptNo}|${currentReceipt.amountReceived}|${currentReceipt.householdHeadName}',
                              version: QrVersions.auto,
                              size: 90.0,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Scan to verify genuine digital receipt',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Share & PDF Actions (SRS 7)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await PdfInvoiceService.printReceipt(
                            receipt: currentReceipt,
                            org: data.organization,
                          );
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Print / PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text =
                              '🧾 *Vargani Receipt - ${data.organization.name}*\n'
                              'Receipt No: ${currentReceipt.receiptNo}\n'
                              'Head: ${currentReceipt.householdHeadName}\n'
                              'Amount: ₹${currentReceipt.amountReceived.toStringAsFixed(0)}\n'
                              'Date: ${dateFormat.format(currentReceipt.issuedAt)}\n'
                              'Campaign: ${currentReceipt.campaignName}\n'
                              'Thank you for your generous contribution!';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('WhatsApp receipt message copied to clipboard!'),
                              backgroundColor: AppColors.statusPaid,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),

                // Reversal / Cancellation Action (SRS 7: Admin/Treasurer only, preserves audit)
                if (!currentReceipt.isCancelled && auth.canConfirmHandover) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        _showCancellationDialog(context, currentReceipt, data, auth);
                      },
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                      label: const Text('Cancel / Reverse Receipt (SRS 7)', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showCancellationDialog(
    BuildContext context,
    ReceiptModel currentReceipt,
    VarganiDataProvider data,
    AuthProvider auth,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Receipt?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Per SRS Section 7, receipts are marked as cancelled with audit trail (no hard delete) and subtracted from collected dues.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Cancellation *',
                hintText: 'e.g. Duplicate entry / Incorrect household',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                data.cancelReceipt(
                  receiptId: currentReceipt.id,
                  reason: reasonController.text.trim(),
                  currentUser: auth.currentUser,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt cancelled with audit entry.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }
}
