import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/services/html_receipt_service.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/mandatory_label.dart';

class ReceiptDetailDialog extends StatelessWidget {
  final ReceiptModel receipt;

  const ReceiptDetailDialog({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Current version in state
    final currentReceipt = data.receipts.firstWhere(
      (r) => r.id == receipt.id,
      orElse: () => receipt,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
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
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentReceipt.isCancelled
                          ? Colors.red
                          : const Color(0xFFFDE68A),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header greeting
                      Text(
                        settings.receiptHeader.isNotEmpty
                            ? settings.receiptHeader
                            : '॥ श्री गणेश प्रसन्न ॥',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Mandal Name & Reg
                      Text(
                        data.organization.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Reg: ${data.organization.registrationNumber} • ${data.organization.village}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Divider(height: 20),

                      // Cancelled Watermark or Status
                      if (currentReceipt.isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            'CANCELLED / REVERSED: ${currentReceipt.cancellationReason}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),

                      // Receipt Details Rows
                      _buildReceiptRow(langTheme.tr('campaigns'),
                          currentReceipt.campaignName),
                      _buildReceiptRow(langTheme.tr('headOfFamily'),
                          currentReceipt.householdHeadName),
                      _buildReceiptRow(
                          '${langTheme.tr('memberCount')} & ${langTheme.tr('perPersonRate')}',
                          '${langTheme.formatNumber(currentReceipt.familyMemberCount)} × ${langTheme.formatCurrency(currentReceipt.perPersonRate)}'),
                      _buildReceiptRow(langTheme.tr('paymentMode'),
                          currentReceipt.paymentType.displayName),
                      if (currentReceipt.referenceId != null &&
                          currentReceipt.referenceId!.isNotEmpty)
                        _buildReceiptRow(langTheme.tr('referenceId'),
                            currentReceipt.referenceId!),
                      _buildReceiptRow(langTheme.tr('paymentDate'),
                          langTheme.formatDate(currentReceipt.issuedAt)),

                      const SizedBox(height: 6),

                      // Prominently highlight who collected the money (जमा घेणाऱ्याचे नाव)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_pin_circle_rounded,
                                    size: 16, color: Colors.blue),
                                const SizedBox(width: 6),
                                Text(
                                  langTheme.isMarathi
                                      ? 'वर्गणी जमा घेणारा:'
                                      : 'Collected By:',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                              ],
                            ),
                            Text(
                              currentReceipt.collectedByName.isNotEmpty
                                  ? currentReceipt.collectedByName
                                  : (langTheme.isMarathi
                                      ? 'अधिकृत प्रतिनिधी'
                                      : 'Authorized Agent'),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Big Amount Highlight
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${langTheme.tr('verifiedReceived').toUpperCase()}:',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              langTheme.formatCurrency(
                                  currentReceipt.amountReceived),
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

                      // Stamp & QR Verification Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // QR Verification Code
                          Column(
                            children: [
                              QrImageView(
                                data:
                                    'VRG-VERIFY:${currentReceipt.receiptNo}|${currentReceipt.amountReceived}|${currentReceipt.householdHeadName}',
                                version: QrVersions.auto,
                                size: 80.0,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Scan to verify',
                                style:
                                    TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),

                          // Official Stamp / Seal ("शिका")
                          if (settings.showStamp)
                            Container(
                              width: 90,
                              height: 90,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.red.shade700,
                                    width: 2,
                                    style: BorderStyle.solid),
                                color: Colors.red.withOpacity(0.04),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('★ ★ ★',
                                      style: TextStyle(
                                          fontSize: 7, color: Colors.red)),
                                  Text(
                                    settings.receiptStampText.isNotEmpty
                                        ? settings.receiptStampText
                                        : 'अधिकृत शिक्का',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                        height: 1.1),
                                  ),
                                  Text(
                                    data.organization.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 7,
                                        color: Colors.red.shade700),
                                  ),
                                  const Text('VERIFIED',
                                      style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red)),
                                  const Text('★ ★ ★',
                                      style: TextStyle(
                                          fontSize: 7, color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text(
                        settings.receiptFooter.isNotEmpty
                            ? settings.receiptFooter
                            : 'वर्गणी दिल्याबद्दल धन्यवाद! ही अधिकृत पावती आहे.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Share, PDF & HTML Actions (SRS 7)
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
                        icon: const Icon(Icons.print_rounded, size: 16),
                        label: const Text('Print / PDF',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text =
                              '🧾 *${data.organization.name} - वर्गणी पावती*\n'
                              'पावती क्र: ${currentReceipt.receiptNo}\n'
                              'वर्गणीदार: ${currentReceipt.householdHeadName}\n'
                              'रक्कम: ₹${currentReceipt.amountReceived.toStringAsFixed(0)}\n'
                              'तारीख: ${langTheme.formatDate(currentReceipt.issuedAt)}\n'
                              'मोहीम: ${currentReceipt.campaignName}\n'
                              'वर्गणी जमा घेणारा (Collected By): ${currentReceipt.collectedByName}\n'
                              'अधिकृत शिक्का: Verified / प्रमाणित\n'
                              'वर्गणी दिल्याबद्दल धन्यवाद!';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'WhatsApp receipt message copied to clipboard!'),
                              backgroundColor: AppColors.statusPaid,
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('WhatsApp',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showHtmlCodeDialog(
                            context,
                            currentReceipt,
                            data.organization,
                            settings,
                            langTheme,
                          );
                        },
                        icon: const Icon(Icons.code_rounded,
                            size: 16, color: Colors.deepPurple),
                        label: const Text('HTML Code',
                            style: TextStyle(
                                fontSize: 12, color: Colors.deepPurple)),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10)),
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
                        _showCancellationDialog(
                            context, currentReceipt, data, auth);
                      },
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.red, size: 18),
                      label: const Text('Cancel / Reverse Receipt (SRS 7)',
                          style: TextStyle(color: Colors.red)),
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
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showHtmlCodeDialog(
    BuildContext context,
    ReceiptModel receipt,
    dynamic org,
    AppSettingsProvider settings,
    LanguageThemeProvider langTheme,
  ) {
    final htmlCode = HtmlReceiptService.generateHtml(
      receipt: receipt,
      org: org,
      header: settings.receiptHeader,
      footer: settings.receiptFooter,
      showStamp: settings.showStamp,
      stampTitle: settings.receiptStampText,
      customTemplate:
          settings.useCustomHtml ? settings.customHtmlTemplate : null,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.html_rounded, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('HTML Receipt Code', style: TextStyle(fontSize: 16)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You can copy this complete standalone HTML code to print or use on any website, thermal printer, or mailer.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                height: 240,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    htmlCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: htmlCode));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('HTML Receipt code copied to clipboard!'),
                  backgroundColor: AppColors.statusPaid,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy HTML Code'),
          ),
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
                label: MandatoryLabel('Reason for Cancellation'),
                hintText: 'e.g. Duplicate entry / Incorrect household',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss')),
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
