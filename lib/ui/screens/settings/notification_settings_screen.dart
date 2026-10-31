import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late bool _whatsapp;
  late bool _sms;
  late bool _reminders;
  late bool _dailyDigest;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppSettingsProvider>();
    _whatsapp = settings.whatsappNotifications;
    _sms = settings.smsNotifications;
    _reminders = settings.remindersEnabled;
    _dailyDigest = settings.dailyDigest;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageThemeProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automated Alerts & Receipts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configure message delivery channels for contributors, donors and committee staff.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notification Channels Card
            const Text(
              'Contributor Receipt Channels',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
                      'WhatsApp Receipt Delivery',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Prompt and send instant WhatsApp receipt slip after payment collection',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.green, size: 20),
                    ),
                    value: _whatsapp,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _whatsapp = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'SMS Confirmation',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Send transaction confirmation SMS via gateway to contributor mobile',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sms_outlined,
                          color: Colors.blue, size: 20),
                    ),
                    value: _sms,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _sms = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Staff & Operational Alerts
            const Text(
              'Staff & Collection Alerts',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
                      'Pending Dues & Follow-up Reminders',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Show in-app reminders for unpaid households and pending handovers',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.alarm_rounded,
                          color: Colors.amber, size: 20),
                    ),
                    value: _reminders,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _reminders = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Daily Financial Summary',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Receive daily 9 PM summary of total funds received and vault balance',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.summarize_outlined,
                          color: Colors.purple, size: 20),
                    ),
                    value: _dailyDigest,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _dailyDigest = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        await settings.updateNotificationSettings(
                          whatsapp: _whatsapp,
                          sms: _sms,
                          reminders: _reminders,
                          dailyDigest: _dailyDigest,
                          currentUser: auth.currentUser,
                        );
                        if (mounted) {
                          setState(() => _isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Notification preferences saved successfully!'),
                              backgroundColor: AppColors.statusPaid,
                            ),
                          );
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
    );
  }
}
