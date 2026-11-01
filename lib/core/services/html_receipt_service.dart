import '../models/receipt_model.dart';
import '../models/organization_model.dart';
import '../models/payment_model.dart';

class HtmlReceiptService {
  HtmlReceiptService._();

  /// Default clean, printable HTML receipt template
  static const String defaultTemplate = '''<!DOCTYPE html>
<html lang="mr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Receipt - {{receipt_no}}</title>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: #f8fafc;
      color: #1e293b;
      padding: 24px;
      display: flex;
      justify-content: center;
    }
    .receipt-container {
      background: #ffffff;
      max-width: 580px;
      width: 100%;
      border: 2px solid #f59e0b;
      border-radius: 16px;
      padding: 28px;
      box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08);
      position: relative;
    }
    .header-greeting {
      text-align: center;
      color: #b45309;
      font-weight: 700;
      font-size: 15px;
      margin-bottom: 6px;
      letter-spacing: 0.5px;
    }
    .org-title {
      text-align: center;
      font-size: 22px;
      font-weight: 800;
      color: #0f172a;
      line-height: 1.2;
    }
    .org-sub {
      text-align: center;
      font-size: 12px;
      color: #64748b;
      margin-top: 4px;
    }
    .divider {
      border: 0;
      height: 1px;
      background: #e2e8f0;
      margin: 16px 0;
    }
    .badge-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: #fef3c7;
      border-radius: 8px;
      padding: 10px 14px;
      margin-bottom: 18px;
    }
    .receipt-id {
      font-weight: 700;
      color: #b45309;
      font-size: 14px;
    }
    .receipt-date {
      font-size: 12px;
      color: #78350f;
    }
    .info-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
    }
    .info-table tr {
      border-bottom: 1px solid #f1f5f9;
    }
    .info-table td {
      padding: 10px 6px;
      font-size: 13px;
    }
    .info-table td.label {
      color: #64748b;
      width: 45%;
    }
    .info-table td.val {
      font-weight: 600;
      color: #0f172a;
      text-align: right;
    }
    .amount-card {
      background: #ecfdf5;
      border: 1.5px dashed #10b981;
      border-radius: 12px;
      padding: 14px 18px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }
    .amount-label {
      font-weight: 700;
      font-size: 13px;
      color: #065f46;
    }
    .amount-value {
      font-size: 24px;
      font-weight: 800;
      color: #047857;
    }
    .collector-highlight {
      background: #eff6ff;
      border-left: 4px solid #3b82f6;
      border-radius: 0 8px 8px 0;
      padding: 10px 14px;
      margin-bottom: 20px;
      font-size: 13px;
      color: #1e40af;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .collector-label {
      font-weight: 600;
    }
    .collector-name {
      font-weight: 700;
      color: #1d4ed8;
      font-size: 14px;
    }
    .bottom-section {
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      margin-top: 24px;
      padding-top: 12px;
      border-top: 1px dashed #cbd5e1;
    }
    .seal-box {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .official-stamp {
      width: 84px;
      height: 84px;
      border: 2px dashed #dc2626;
      border-radius: 50%;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #dc2626;
      font-weight: 700;
      font-size: 9px;
      text-align: center;
      transform: rotate(-8deg);
      line-height: 1.1;
      background: rgba(220, 38, 38, 0.03);
      padding: 4px;
    }
    .sign-box {
      text-align: right;
    }
    .sign-line {
      width: 140px;
      height: 1px;
      background: #94a3b8;
      margin-bottom: 6px;
      display: inline-block;
    }
    .sign-label {
      font-size: 11px;
      color: #64748b;
      font-weight: 600;
    }
    .footer-note {
      text-align: center;
      font-size: 11px;
      color: #94a3b8;
      margin-top: 20px;
    }
    .no-print-bar {
      margin-top: 24px;
      display: flex;
      gap: 12px;
      justify-content: center;
    }
    .btn {
      padding: 10px 20px;
      border: none;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
      font-size: 13px;
    }
    .btn-primary {
      background: #f59e0b;
      color: #ffffff;
    }
    .btn-secondary {
      background: #e2e8f0;
      color: #1e293b;
    }
    @media print {
      body {
        background: #ffffff;
        padding: 0;
      }
      .receipt-container {
        border: 1px solid #d97706;
        box-shadow: none;
        max-width: 100%;
        padding: 16px;
      }
      .no-print-bar {
        display: none !important;
      }
    }
  </style>
</head>
<body>
  <div class="receipt-container">
    <div class="header-greeting">{{header}}</div>
    <div class="org-title">{{org_name}}</div>
    <div class="org-sub">नोंदणी क्र.: {{org_reg}} • {{org_address}} • मो.: {{org_phone}}</div>

    <hr class="divider">

    <div class="badge-bar">
      <div class="receipt-id">पावती क्र. (Receipt No): {{receipt_no}}</div>
      <div class="receipt-date">तारीख: {{date}}</div>
    </div>

    <table class="info-table">
      <tr>
        <td class="label">मोहीम / सण (Campaign)</td>
        <td class="val">{{campaign_name}}</td>
      </tr>
      <tr>
        <td class="label">वर्गणीदार प्रमुख (Head of Family)</td>
        <td class="val">{{household_head}}</td>
      </tr>
      <tr>
        <td class="label">सदस्य संख्या आणि दर</td>
        <td class="val">{{family_members}} व्यक्ती × ₹{{per_person_rate}}</td>
      </tr>
      <tr>
        <td class="label">पेमेंट प्रकार (Payment Mode)</td>
        <td class="val">{{payment_mode}}</td>
      </tr>
      {{reference_row}}
    </table>

    <div class="amount-card">
      <div class="amount-label">जमा केलेली रक्कम (Amount Received)</div>
      <div class="amount-value">₹{{amount_received}}</div>
    </div>

    <div class="collector-highlight">
      <div class="collector-label">वर्गणी जमा घेणारा (Collected By):</div>
      <div class="collector-name">{{collected_by}}</div>
    </div>

    <div class="bottom-section">
      <div class="seal-box">
        {{stamp_html}}
      </div>
      <div class="sign-box">
        <span class="sign-line"></span><br>
        <div class="sign-label">अधिकृत प्रतिनिधी स्वाक्षरी</div>
        <div style="font-size: 10px; color: #94a3b8; margin-top: 2px;">{{received_by}}</div>
      </div>
    </div>

    <div class="footer-note">{{footer}}</div>

    <div class="no-print-bar">
      <button class="btn btn-primary" onclick="window.print()">🖨️ प्रिंट करा (Print Receipt)</button>
    </div>
  </div>
</body>
</html>''';

  /// Official Stamp SVG / HTML element
  static String buildOfficialStampHtml({
    required String orgName,
    String stampTitle = 'अधिकृत शिक्का',
  }) {
    return '''
      <div class="official-stamp">
        <div style="font-size: 7px; opacity: 0.85;">★ ★ ★</div>
        <div>$stampTitle</div>
        <div style="font-size: 7px; margin: 1px 0;">VERIFIED</div>
        <div style="font-size: 6px; overflow: hidden; text-overflow: ellipsis; max-width: 70px; white-space: nowrap;">$orgName</div>
        <div style="font-size: 7px; opacity: 0.85;">★ ★ ★</div>
      </div>
    ''';
  }

  /// Generate finalized HTML receipt by substituting template placeholders
  static String generateHtml({
    required ReceiptModel receipt,
    required OrganizationModel org,
    String? header,
    String? footer,
    bool showStamp = true,
    String? stampTitle,
    String? customTemplate,
  }) {
    final template = (customTemplate != null && customTemplate.trim().isNotEmpty)
        ? customTemplate
        : defaultTemplate;

    final headerText = (header != null && header.trim().isNotEmpty)
        ? header.trim()
        : '॥ श्री गणेश प्रसन्न ॥';

    final footerText = (footer != null && footer.trim().isNotEmpty)
        ? footer.trim()
        : 'वर्गणी दिल्याबद्दल धन्यवाद! ही अधिकृत पावती आहे.';

    final stampHtml = showStamp
        ? buildOfficialStampHtml(
            orgName: org.name,
            stampTitle: stampTitle ?? 'अधिकृत शिक्का',
          )
        : '';

    final refRow = (receipt.referenceId != null && receipt.referenceId!.isNotEmpty)
        ? '<tr><td class="label">संदर्भ / UTR क्रमांक</td><td class="val">${receipt.referenceId}</td></tr>'
        : '';

    final dateStr =
        '${receipt.issuedAt.day.toString().padLeft(2, '0')}/${receipt.issuedAt.month.toString().padLeft(2, '0')}/${receipt.issuedAt.year} '
        '${receipt.issuedAt.hour.toString().padLeft(2, '0')}:${receipt.issuedAt.minute.toString().padLeft(2, '0')}';

    return template
        .replaceAll('{{header}}', headerText)
        .replaceAll('{{org_name}}', org.name)
        .replaceAll('{{org_reg}}', org.registrationNumber)
        .replaceAll('{{org_address}}', '${org.village}, ${org.taluka}')
        .replaceAll('{{org_phone}}', org.phone)
        .replaceAll('{{receipt_no}}', receipt.receiptNo)
        .replaceAll('{{date}}', dateStr)
        .replaceAll('{{campaign_name}}', receipt.campaignName)
        .replaceAll('{{household_head}}', receipt.householdHeadName)
        .replaceAll('{{family_members}}', receipt.familyMemberCount.toString())
        .replaceAll('{{per_person_rate}}', receipt.perPersonRate.toStringAsFixed(0))
        .replaceAll('{{payment_mode}}', receipt.paymentType.displayName)
        .replaceAll('{{reference_row}}', refRow)
        .replaceAll('{{reference_id}}', receipt.referenceId ?? '-')
        .replaceAll('{{amount_received}}', receipt.amountReceived.toStringAsFixed(0))
        .replaceAll('{{collected_by}}', receipt.collectedByName.isNotEmpty ? receipt.collectedByName : 'अधिकृत प्रतिनिधी')
        .replaceAll('{{received_by}}', receipt.receivedByName.isNotEmpty ? receipt.receivedByName : org.name)
        .replaceAll('{{stamp_html}}', stampHtml)
        .replaceAll('{{footer}}', footerText);
  }
}
