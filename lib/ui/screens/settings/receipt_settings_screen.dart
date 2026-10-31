import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
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
  late bool _showStamp;
  late bool _autoShare;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettingsProvider>();
    _prefixCtrl = TextEditingController(text: settings.receiptPrefix);
    _headerCtrl = TextEditingController(text: settings.receiptHeader);
    _footerCtrl = TextEditingController(text: settings.receiptFooter);
    _showStamp = settings.showStamp;
    _autoShare = settings.autoShareWhatsapp;
  }

  @override
  void dispose() {
    _prefixCtrl.dispose();
    _headerCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageThemeProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Settings'),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Digital Receipt Customization',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Customize receipt numbering format, official letterhead greetings, and stamp styling.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Prefix & Numbering
              const MandatoryLabel('Receipt Number Prefix'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _prefixCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. VRG-2026',
                  prefixIcon: Icon(Icons.tag_rounded),
                  helperText: 'Receipts will be generated as {Prefix}-0001, etc.',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter receipt prefix'
                    : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Header Greeting / Slogan
              const MandatoryLabel('Header Greeting / Slogan'),
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
              const MandatoryLabel('Footer Note / Thank You Message'),
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

              // Toggles Card
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
                      title: const Text(
                        'Include Mandal Seal & Stamp',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Display verified circular seal on official PDF receipts',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: Colors.green, size: 20),
                      ),
                      value: _showStamp,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _showStamp = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Auto-Trigger WhatsApp Share',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Automatically open WhatsApp share dialog after logging receipt',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
              const SizedBox(height: 24),

              // Live Preview Section
              const Text(
                'Live Receipt Preview',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                    if (_showStamp) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green, width: 1.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VERIFIED & STAMPED',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
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
                              autoShareWhatsapp: _autoShare,
                              currentUser: auth.currentUser,
                            );
                            if (mounted) {
                              setState(() => _isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Receipt configuration saved successfully!'),
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
                    _isSaving ? 'Saving...' : 'Save',
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
