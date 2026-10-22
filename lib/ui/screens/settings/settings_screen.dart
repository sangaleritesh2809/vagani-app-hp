import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../campaigns/campaign_config_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final data = context.watch<VarganiDataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card with Role Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    auth.currentUser.name.substring(0, 1),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.currentUser.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        auth.currentUser.phone,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          auth.currentRole.nameString,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Role Switcher Section (SRS 3)
          const Text('Switch Demo Role (SRS 3)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: auth.availableUsers.map((user) {
                final isSelected = auth.currentUser.id == user.id;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                  title: Text(user.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text('${user.role.nameString} • ${user.phone}'),
                  onTap: () => auth.switchUser(user),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Citizen Phone OTP Login Simulator (SRS 9 & 12 FR-01)
          const Text('Citizen Phone OTP Login (FR-01)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simulate citizen sign-in via phone number and OTP for public transparency and grievance tracking.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showCitizenOtpDialog(context, auth),
                  icon: const Icon(Icons.sms_rounded, size: 16),
                  label: const Text('Log In with Phone OTP'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // App Settings & Preferences
          const Text('Preferences & Localization', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: const Text('Language (इंग्रजी / मराठी)'),
                  subtitle: Text(langTheme.languageCode == 'en' ? 'English (इंग्रजी)' : 'मराठी (Marathi)'),
                  trailing: Switch(
                    value: langTheme.languageCode == 'mr',
                    activeColor: AppColors.primary,
                    onChanged: (val) => langTheme.setLanguage(val ? 'mr' : 'en'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    langTheme.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: Colors.amber,
                  ),
                  title: const Text('Theme Mode'),
                  subtitle: Text(langTheme.isDarkMode ? 'Dark Mode' : 'Light Mode'),
                  trailing: Switch(
                    value: langTheme.isDarkMode,
                    activeColor: AppColors.primary,
                    onChanged: (val) => langTheme.toggleTheme(),
                  ),
                ),
                if (auth.canManageCampaigns) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.price_change_rounded, color: AppColors.statusPaid),
                    title: const Text('Configure Vargani Rate (SRS 5.1)'),
                    subtitle: Text('Current Rate: ₹${data.currentCampaign.perPersonRate.toStringAsFixed(0)} / person'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      showDialog(context: context, builder: (_) => const CampaignConfigDialog());
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Organization Info (SRS 4)
          const Text('Organization Information (SRS 4)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.organization.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Registration: ${data.organization.registrationNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('President / Contact: ${data.organization.contactPerson}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Address: ${data.organization.address}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Location: ${data.organization.village}, ${data.organization.taluka}, ${data.organization.district}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showCitizenOtpDialog(BuildContext context, AuthProvider auth) {
    final phoneController = TextEditingController(text: '+91 98234 01122');
    final otpController = TextEditingController(text: '123456');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Citizen Phone OTP Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter mobile number to receive OTP: (Demo: 123456)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Mobile Number')),
            const SizedBox(height: 12),
            TextField(controller: otpController, decoration: const InputDecoration(labelText: 'OTP (Default: 123456)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              auth.simulateCitizenOtpLogin(phoneController.text.trim(), otpController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged in as Citizen (Rahul Patil)! Switched to Public Transparency view.'),
                  backgroundColor: AppColors.statusPaid,
                ),
              );
            },
            child: const Text('Verify & Log In'),
          ),
        ],
      ),
    );
  }
}
