import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/html_receipt_service.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/mandatory_label.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _prefixCtrl;
  late TextEditingController _headerCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _stampTextCtrl;
  late TextEditingController _htmlTemplateCtrl;
  late bool _showStamp;
  late bool _useCustomHtml;
  late bool _autoShare;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettingsProvider>();
    _prefixCtrl = TextEditingController(text: settings.receiptPrefix);
    _headerCtrl = TextEditingController(text: settings.receiptHeader);
    _footerCtrl = TextEditingController(text: settings.receiptFooter);
    _stampTextCtrl = TextEditingController(text: settings.receiptStampText);
    _htmlTemplateCtrl = TextEditingController(text: settings.customHtmlTemplate);
    _showStamp = settings.showStamp;
    _useCustomHtml = settings.useCustomHtml;
    _autoShare = settings.autoShareWhatsapp;
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    _stampTextCtrl.dispose();
    _htmlTemplateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageThemeProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();

    final isMr = lang.isMarathi;

    return Scaffold(
      appBar: AppBar(
        title: Text(isMr ? 'पावती सेटिंग्ज' : 'Receipt Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMr
                                ? 'डिजिटल पावती आणि शिक्का सानुकूलन'
                                : 'Digital Receipt, Stamp & HTML Customization',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMr
                                ? 'पावती क्रमांक, हेडर, अधिकृत शिक्का आणि HTML कोड कॉन्फिगर करा.'
                                : 'Customize receipt numbering, slogan, official stamp & HTML code.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Prefix & Numbering
              MandatoryLabel(isMr ? 'पावती क्रमांक उपसर्ग (Prefix)' : 'Receipt Number Prefix'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _prefixCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. VRG-2026',
                  prefixIcon: const Icon(Icons.tag_rounded),
                  helperText: isMr
                      ? 'पावती क्रमांक {Prefix}-0001 अशा स्वरूपात जनरेट होईल'
                      : 'Receipts will be generated as {Prefix}-0001, etc.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter receipt prefix'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Header Greeting / Slogan
              MandatoryLabel(isMr ? 'पावती शीर्ष घोषवाक्य (Header Slogan)' : 'Header Greeting / Slogan'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _headerCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. ॥ श्री गणेश प्रसन्न ॥',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter header greeting'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Footer Note
              MandatoryLabel(isMr ? 'पावती तळटीप / आभार संदेश (Footer Note)' : 'Footer Note / Thank You Message'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _footerCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. वर्गणी दिल्याबद्दल धन्यवाद! ही अधिकृत पावती आहे.',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter footer note'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Stamp ("शिका") & Toggles Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        isMr ? 'मंडळाचा अधिकृत शिक्का (Official Stamp / Seal)' : 'Include Mandal Seal & Stamp',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        isMr
                            ? 'पावतीवर मंडळाचा अधिकृत शिक्का (शिका) दाखवा'
                            : 'Display verified circular seal on official receipts',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: Colors.red, size: 20),
                      ),
                      value: _showStamp,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _showStamp = val),
                    ),
                    if (_showStamp) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MandatoryLabel(isMr ? 'शिक्क्यावरील मजकूर (Stamp Text)' : 'Official Stamp Text'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _stampTextCtrl,
                              decoration: const InputDecoration(
                                hintText: 'अधिकृत शिक्का',
                                prefixIcon: Icon(Icons.approval_rounded, color: Colors.red),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        isMr ? 'ऑटो व्हॉट्सअ‍ॅप शेअर (Auto WhatsApp Share)' : 'Auto-Trigger WhatsApp Share',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        isMr
                            ? 'पावती नोंदवल्यानंतर लगेच व्हॉट्सअ‍ॅप डायलॉग उघडा'
                            : 'Automatically open WhatsApp share dialog after logging receipt',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.share_rounded,
                            color: Colors.teal, size: 20),
                      ),
                      value: _autoShare,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _autoShare = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── HTML Code Support Section ──────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.code_rounded,
                        color: Colors.deepPurple, size: 20),
                  ),
                  title: Text(
                    isMr ? 'पावती HTML कोड (HTML Receipt Code)' : 'HTML Receipt Template & Code',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    isMr
                        ? 'पावतीसाठी सानुकूल HTML कोड वापरा किंवा एडिट करा'
                        : 'Use or customize HTML code for print & digital receipts',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              isMr ? 'सानुकूल HTML कोड वापरा' : 'Enable Custom HTML Template',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              isMr
                                  ? 'सक्रिय केल्यावर तुमचा सानुकूल HTML कोड पावतीसाठी वापरला जाईल'
                                  : 'Override default template with custom HTML code below',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            value: _useCustomHtml,
                            activeColor: Colors.deepPurple,
                            onChanged: (val) => setState(() => _useCustomHtml = val),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMr ? 'HTML कोड (HTML Code):' : 'HTML Code:',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      _htmlTemplateCtrl.text = HtmlReceiptService.defaultTemplate;
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Reset to default HTML template'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.restore_rounded, size: 14),
                                    label: Text(isMr ? 'रीसेट' : 'Reset Default',
                                        style: const TextStyle(fontSize: 11)),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _htmlTemplateCtrl.text));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('HTML code copied to clipboard!'),
                                          backgroundColor: AppColors.statusPaid,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 14),
                                    label: Text(isMr ? 'कॉपी करा' : 'Copy HTML',
                                        style: const TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade800),
                            ),
                            child: TextField(
                              controller: _htmlTemplateCtrl,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF38BDF8),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(10),
                                hintText: 'Enter HTML template with {{tags}}...',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isMr
                                ? 'वापरण्याजोगे टॅग्ज: {{org_name}}, {{receipt_no}}, {{household_head}}, {{amount_received}}, {{collected_by}}, {{date}}, {{stamp_html}}'
                                : 'Available tags: {{org_name}}, {{receipt_no}}, {{household_head}}, {{amount_received}}, {{collected_by}}, {{date}}, {{stamp_html}}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Live Preview Section
              Text(
                isMr ? 'थेट पावती पूर्वदृश्य (Live Preview)' : 'Live Receipt Preview',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      _headerCtrl.text.trim().isNotEmpty
                          ? _headerCtrl.text.trim()
                          : '॥ श्री गणेश प्रसन्न ॥',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.organization.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${_prefixCtrl.text.trim()}-0001',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Divider(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sample Contributor: Mahesh Patil',
                            style: TextStyle(fontSize: 12, color: Colors.black87)),
                        Text('₹500',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Collector preview
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isMr ? 'वर्गणी जमा घेणारा:' : 'Collected By:',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                          Text(
                            auth.currentUser.name.isNotEmpty
                                ? auth.currentUser.name
                                : 'Shubhangi Chaudhari',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ],
                      ),
                    ),

                    // Stamp preview
                    if (_showStamp) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 75,
                            height: 75,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.red.shade700, width: 1.5),
                              color: Colors.red.withOpacity(0.04),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('★ ★ ★',
                                    style: TextStyle(fontSize: 6, color: Colors.red)),
                                Text(
                                  _stampTextCtrl.text.trim().isNotEmpty
                                      ? _stampTextCtrl.text.trim()
                                      : 'अधिकृत शिक्का',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                      height: 1.0),
                                ),
                                const Text('VERIFIED',
                                    style: TextStyle(
                                        fontSize: 6,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red)),
                                const Text('★ ★ ★',
                                    style: TextStyle(fontSize: 6, color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 16),
                    Text(
                      _footerCtrl.text.trim(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isSaving = true);
                            await settings.updateReceiptSettings(
                              prefix: _prefixCtrl.text,
                              header: _headerCtrl.text,
                              footer: _footerCtrl.text,
                              showStamp: _showStamp,
                              stampText: _stampTextCtrl.text,
                              customHtml: _htmlTemplateCtrl.text,
                              useCustomHtml: _useCustomHtml,
                              autoShareWhatsapp: _autoShare,
                              currentUser: auth.currentUser,
                            );
                            if (mounted) {
                              setState(() => _isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isMr
                                      ? 'पावती सेटिंग्ज यशस्वीरीत्या सेव्ह केल्या!'
                                      : 'Receipt configuration saved successfully!'),
                                  backgroundColor: AppColors.statusPaid,
                                ),
                              );
                            }
                          }
                        },
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_rounded, color: Colors.white),
                  label: Text(
                    _isSaving ? (isMr ? 'सेव्ह होत आहे...' : 'Saving...') : (isMr ? 'सेव्ह करा' : 'Save'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
