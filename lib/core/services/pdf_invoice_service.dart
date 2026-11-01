import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/receipt_model.dart';
import '../models/organization_model.dart';
import '../models/payment_model.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateReceiptPdf({
    required ReceiptModel receipt,
    required OrganizationModel org,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // Load Devanagari font asset for crisp Marathi & Hindi rendering
    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf');
      final boldData =
          await rootBundle.load('assets/fonts/NotoSansDevanagari-Bold.ttf');
      ttfRegular = pw.Font.ttf(regularData);
      ttfBold = pw.Font.ttf(boldData);
    } catch (_) {
      try {
        ttfRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
        ttfBold = await PdfGoogleFonts.notoSansDevanagariBold();
      } catch (_) {
        ttfRegular = null;
        ttfBold = null;
      }
    }

    final pageTheme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pageTheme,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber800, width: 2),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        org.name,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${org.village}, Taluka: ${org.taluka}, Dist: ${org.district}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Reg. No: ${org.registrationNumber} | Phone: ${org.phone}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Divider(color: PdfColors.amber700, thickness: 1),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Receipt Title & Badge
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'VARGANI CONTRIBUTION RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        pw.Text(
                          'Campaign: ${receipt.campaignName}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: receipt.isCancelled
                            ? PdfColors.red50
                            : PdfColors.green50,
                        border: pw.Border.all(
                          color: receipt.isCancelled
                              ? PdfColors.red
                              : PdfColors.green,
                        ),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        receipt.isCancelled ? 'CANCELLED' : 'OFFICIAL RECEIPT',
                        style: pw.TextStyle(
                          color: receipt.isCancelled
                              ? PdfColors.red
                              : PdfColors.green800,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Receipt Meta
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Receipt No: ${receipt.receiptNo}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                      pw.Text(
                        'Date: ${dateFormat.format(receipt.issuedAt)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),

                // Contributor Table
                pw.Table(
                  border:
                      pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Particulars',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Details / Calculation',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Head of Household',
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(receipt.householdHeadName,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Family Members & Rate',
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${receipt.familyMemberCount} members @ Rs. ${receipt.perPersonRate.toStringAsFixed(0)} / person',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Total Expected Contribution',
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Rs. ${(receipt.familyMemberCount * receipt.perPersonRate).toStringAsFixed(0)}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Payment Mode & Reference',
                              style: const pw.TextStyle(fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${receipt.paymentType.displayName.toUpperCase()}${receipt.referenceId != null ? ' (Ref: ${receipt.referenceId})' : ''}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.blue50),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Collected By (जमा घेणारा)',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                  color: PdfColors.blue900)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            receipt.collectedByName.isNotEmpty
                                ? receipt.collectedByName
                                : 'Authorized Agent',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                                color: PdfColors.blue900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Amount Highlight Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.amber600),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'AMOUNT RECEIVED:',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: PdfColors.amber900),
                      ),
                      pw.Text(
                        'INR ${receipt.amountReceived.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                          color: PdfColors.amber900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (receipt.isCancelled) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Cancelled by: ${receipt.cancelledByName} | Reason: ${receipt.cancellationReason ?? 'Reversal'}',
                    style:
                        const pw.TextStyle(fontSize: 8, color: PdfColors.red),
                  ),
                ],
                pw.Spacer(),

                // Signatures, Mandal Seal Stamp & QR Note
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Collected By: ${receipt.collectedByName}',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Received By: ${receipt.receivedByName}',
                            style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                            '* This is a computer generated verifiable digital receipt.',
                            style: const pw.TextStyle(
                                fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),

                    // Official Mandal Stamp ("शिका")
                    pw.Container(
                      width: 65,
                      height: 65,
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.red800, width: 1.5),
                      ),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('★ ★ ★',
                              style: const pw.TextStyle(
                                  fontSize: 5, color: PdfColors.red800)),
                          pw.Text('OFFICIAL SEAL',
                              style: pw.TextStyle(
                                  fontSize: 6,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red800)),
                          pw.Text('अधिकृत शिक्का',
                              style: pw.TextStyle(
                                  fontSize: 6,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red800)),
                          pw.Text('VERIFIED',
                              style: const pw.TextStyle(
                                  fontSize: 5, color: PdfColors.red800)),
                          pw.Text('★ ★ ★',
                              style: const pw.TextStyle(
                                  fontSize: 5, color: PdfColors.red800)),
                        ],
                      ),
                    ),

                    pw.Column(
                      children: [
                        pw.Container(
                          width: 80,
                          height: 1,
                          color: PdfColors.grey700,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Authorized Signatory',
                            style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(org.name,
                            style: const pw.TextStyle(
                                fontSize: 7, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printReceipt({
    required ReceiptModel receipt,
    required OrganizationModel org,
  }) async {
    final pdfBytes = await generateReceiptPdf(receipt: receipt, org: org);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${receipt.receiptNo}.pdf',
    );
  }

  static Future<void> shareReceipt({
    required ReceiptModel receipt,
    required OrganizationModel org,
  }) async {
    final pdfBytes = await generateReceiptPdf(receipt: receipt, org: org);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${receipt.receiptNo}.pdf',
    );
  }
}
