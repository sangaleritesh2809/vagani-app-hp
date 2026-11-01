import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../auth/group_selection_screen.dart';
import '../auth/login_screen.dart';
import '../campaigns/campaign_config_dialog.dart';
import '../management/organization_management_screen.dart';
import '../management/role_management_screen.dart';
import '../management/user_management_screen.dart';
import '../profile/user_profile_screen.dart';
import 'about_app_screen.dart';
import 'data_backup_screen.dart';
import 'help_support_screen.dart';
import 'notification_settings_screen.dart';
import 'receipt_settings_screen.dart';
import 'security_privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final data = context.watch<VarganiDataProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = auth.currentUser;
    final isSuperAdmin = auth.isSuperAdmin;
    final isOrgAdmin = auth.isOrgAdmin;
    final isGroupAdmin = auth.isGroupAdmin;
    final isCitizen = auth.isCitizen || auth.isPublicUser;
    final isMr = langTheme.isMarathi;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          langTheme.tr('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── 1. USER PROFILE HEADER CARD ────────────────────────────────────
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${user.phone} • ${auth.selectedGroup?.name ?? "Central Division"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                auth.currentRole.nameString,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: user.isActive
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                user.isActive
                                    ? (isMr ? 'सक्रिय' : 'Active')
                                    : (isMr ? 'निष्क्रिय' : 'Inactive'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: user.isActive
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── 2. ACCOUNT & SECURITY (All Users - Duplicate Profile Settings Removed) ─
          _buildSectionHeader(isMr ? 'खाते आणि सुरक्षा' : 'Account & Security'),
          _buildCardContainer(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.shield_outlined,
                iconColor: Colors.indigo,
                title: isMr ? 'सुरक्षा आणि गोपनीयता' : 'Security & Privacy',
                subtitle: isMr
                    ? 'पासवर्ड बदला, बायोमेट्रिक अनलॉक आणि सक्रिय सत्रे'
                    : 'Password change, biometric unlock & active sessions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SecurityPrivacyScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 3. PREFERENCES & LOCALIZATION (All Users) ─────────────────────
          _buildSectionHeader(isMr ? 'अ‍ॅप प्राधान्ये आणि डिस्प्ले' : 'App Preferences & Display'),
          _buildCardContainer(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.translate_rounded,
                iconColor: Colors.teal,
                title: langTheme.tr('language'),
                subtitle: langTheme.isMarathi
                    ? 'मराठी (Regional)'
                    : (langTheme.isHindi ? 'हिन्दी (National)' : 'English (Primary)'),
                onTap: () => _showLanguageSelectionSheet(context, langTheme),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: langTheme.isDarkMode
                    ? Icons.dark_mode_rounded
                    : (langTheme.isLightMode
                        ? Icons.light_mode_rounded
                        : Icons.settings_brightness_rounded),
                iconColor: Colors.amber,
                title: isMr ? 'रंगसंगती (Theme)' : langTheme.tr('themeMode'),
                subtitle: langTheme.isSystemMode
                    ? (isMr ? 'सिस्टम डिफॉल्ट' : 'System Default')
                    : (langTheme.isDarkMode
                        ? (isMr ? 'डार्क मोड' : 'Dark Mode')
                        : (isMr ? 'लाइट मोड' : 'Light Mode')),
                onTap: () => _showThemeSelectionDialog(context, langTheme),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('१२३',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                ),
                title: Text(
                  isMr ? 'मराठी / देवनागरी अंक' : 'Marathi / Devanagari Digits',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isMr
                      ? 'संख्या आणि रक्कम १, २, ३... स्वरूपात दाखवा'
                      : 'Format amounts and numbers as १, २, ३...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: langTheme.useMarathiNumerals,
                activeColor: AppColors.primary,
                onChanged: (val) => langTheme.setUseMarathiNumerals(val),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 4. NOTIFICATIONS (All Users) ──────────────────────────────────
          _buildSectionHeader(isMr ? 'सूचना आणि संप्रेषण' : 'Notifications & Communication'),
          _buildCardContainer(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.notifications_none_rounded,
                iconColor: Colors.purple,
                title: isMr ? 'सूचना सेटिंग्ज' : 'Notification Settings',
                subtitle: isMr
                    ? 'व्हॉट्सअ‍ॅप पावती, एसएमएस अलर्ट आणि स्मरणपत्रे'
                    : 'WhatsApp receipt slips, SMS alerts & collection reminders',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 5. FINANCIAL & OPERATIONS (Staff Only) ────────────────────────
          if (!isCitizen) ...[
            _buildSectionHeader(isMr ? 'आर्थिक आणि कामकाज सेटिंग्ज' : 'Financial & Operations Configuration'),
            _buildCardContainer(
              isDark: isDark,
              children: [
                if (auth.canCollectVargani || isGroupAdmin || isSuperAdmin)
                  _buildSettingTile(
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.secondary,
                    title: isMr ? 'पावती सेटिंग्ज' : 'Receipt Settings',
                    subtitle: isMr
                        ? 'पावती क्रमांक, घोषवाक्य, अधिकृत शिक्का आणि HTML कोड'
                        : 'Customize receipt numbering, slogan, official stamp & HTML code',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReceiptSettingsScreen()),
                      );
                    },
                  ),
                if (auth.canManageCampaigns || isOrgAdmin || isSuperAdmin) ...[
                  if (auth.canCollectVargani || isGroupAdmin || isSuperAdmin)
                    const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.price_change_rounded,
                    iconColor: AppColors.statusPaid,
                    title: isMr ? 'मोहीम आणि वर्गणी दर (SRS 5.1)' : 'Campaign & Vargani Rate (SRS 5.1)',
                    subtitle: isMr
                        ? 'सध्याचा दर: ₹${data.currentCampaign.perPersonRate.toStringAsFixed(0)} / व्यक्ती'
                        : 'Current: ₹${data.currentCampaign.perPersonRate.toStringAsFixed(0)} / person',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CampaignConfigDialog(),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── 6. ADMINISTRATION & GOVERNANCE (Strict Role Gating) ───────────
          if (!isCitizen &&
              (isSuperAdmin ||
                  auth.canManageRoles ||
                  auth.canViewUsers ||
                  auth.authorizedGroups.length > 1)) ...[
            _buildSectionHeader(isMr ? 'प्रशासन आणि व्यवस्थापन (RBAC)' : 'Administration & Governance (RBAC)'),
            _buildCardContainer(
              isDark: isDark,
              children: [
                // Organization Management (Strictly Super Admin - Req 6)
                if (isSuperAdmin)
                  _buildSettingTile(
                    icon: Icons.apartment_rounded,
                    iconColor: Colors.deepPurple,
                    title: isMr ? 'संस्था / मंडळ व्यवस्थापन' : 'Organization Management',
                    subtitle: isMr
                        ? 'मंडळे, ट्रस्ट, बँक क्यूआर आणि शाखा व्यवस्थापन'
                        : 'Super Admin: Manage mandals, trusts, bank QR & divisions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const OrganizationManagementScreen()),
                      );
                    },
                  ),

                // Group Switching & Settings (Group Admin / Super Admin - Req 7)
                if (auth.authorizedGroups.length > 1 || isSuperAdmin) ...[
                  if (isSuperAdmin) const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.hub_rounded,
                    iconColor: Colors.teal,
                    title: isMr ? 'सक्रिय गट बदला' : 'Switch Active Group',
                    subtitle: isMr
                        ? 'सध्याचा गट: ${auth.selectedGroup?.name ?? "Central Division"}'
                        : 'Current: ${auth.selectedGroup?.name ?? "Central Division"}',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GroupSelectionScreen()),
                      );
                    },
                  ),
                ],

                // User Management
                if (auth.canViewUsers || auth.canManageUsers || isSuperAdmin) ...[
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.manage_accounts_rounded,
                    iconColor: AppColors.primary,
                    title: isMr ? 'वापरकर्ता व्यवस्थापन' : 'User Management',
                    subtitle: isMr
                        ? 'वापरकर्ता प्रोफाइल, सक्रिय स्थिती आणि भूमिका व्यवस्थापन'
                        : 'Manage user profiles, active status & role assignments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserManagementScreen()),
                      );
                    },
                  ),
                ],

                // Role Management (PBAC)
                if (auth.canManageRoles || isSuperAdmin) ...[
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.admin_panel_settings_rounded,
                    iconColor: Colors.indigo,
                    title: isMr ? 'भूमिका आणि परवानग्या' : 'Roles & Granular Permissions',
                    subtitle: isMr
                        ? 'सानुकूल भूमिका आणि 22-मॉड्यूल परवानग्या कॉन्फिगर करा'
                        : 'Configure custom roles and dynamic 22-module PBAC rules',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RoleManagementScreen()),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── 7. DATA, SYNC & STORAGE (Staff Only) ──────────────────────────
          if (!isCitizen) ...[
            _buildSectionHeader(isMr ? 'डेटा आणि स्टोरेज' : 'Data & Storage'),
            _buildCardContainer(
              isDark: isDark,
              children: [
                _buildSettingTile(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: Colors.blue,
                  title: isMr ? 'डेटा आणि बॅकअप' : 'Data & Backup',
                  subtitle: isMr
                      ? 'सुपाबेस सिंक स्थिती, लेजर आकडेवारी आणि बॅकअप'
                      : 'Supabase sync status, ledger stats & data snapshot export',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DataBackupScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── 8. SUPPORT & ABOUT (All Users) ────────────────────────────────
          _buildSectionHeader(isMr ? 'मदत आणि माहिती' : 'Support & Information'),
          _buildCardContainer(
            isDark: isDark,
            children: [
              _buildSettingTile(
                icon: Icons.help_outline_rounded,
                iconColor: Colors.teal,
                title: isMr ? 'मदत आणि तक्रार निवारण' : 'Help & Support',
                subtitle: isMr
                    ? 'मंडळ समिती हेल्पलाइन, चौकशी आणि तक्रार निवारण'
                    : 'Mandal committee helpline, inquiries & grievance portal',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen()),
                  );
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
                title: isMr ? 'वर्गणी अ‍ॅपबद्दल' : 'About Vargani App',
                subtitle: isMr
                    ? 'आवृत्ती १.०.१ • अटी, गोपनीयता आणि नियम'
                    : 'Version 1.0.1 • Terms, Privacy & SRS Compliance',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 9. SUPER ADMIN RBAC TESTING SIMULATOR ─────────────────────────
          if (isSuperAdmin) ...[
            _buildSectionHeader(isMr ? 'चाचणी: भूमिका सिम्युलेटर (फक्त सुपर अ‍ॅडमिन)' : 'Demo Testing: Role Simulator (Super Admin Only)'),
            _buildCardContainer(
              isDark: isDark,
              children: auth.availableUsers.map((u) {
                final isSelected = auth.currentUser.id == u.id;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                  title: Text(
                    u.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${u.role.nameString} • ${u.phone} • ${u.isActive ? (isMr ? "सक्रिय" : "Active") : (isMr ? "निष्क्रिय" : "Inactive")}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => auth.switchUser(u),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // ── 10. LOG OUT ACTION ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.3),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 22),
              ),
              title: Text(
                isMr ? 'लॉगआउट करा' : 'Log Out',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              subtitle: Text(
                isMr
                    ? 'या डिव्हाइसवरून सुरक्षितपणे बाहेर पडा'
                    : 'Safely disconnect and return to login',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.redAccent,
              ),
              onTap: () => _confirmLogout(context, auth, isMr),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showThemeSelectionDialog(
      BuildContext context, LanguageThemeProvider langTheme) {
    final isMr = langTheme.isMarathi;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? 'रंगसंगती निवडा (Theme)' : 'Select Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(isMr ? 'लाइट मोड (Light)' : 'Light Mode'),
              secondary: const Icon(Icons.light_mode_rounded, color: Colors.amber),
              value: ThemeMode.light,
              groupValue: langTheme.themeMode,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) langTheme.setThemeMode(mode);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(isMr ? 'डार्क मोड (Dark)' : 'Dark Mode'),
              secondary: const Icon(Icons.dark_mode_rounded, color: Colors.indigo),
              value: ThemeMode.dark,
              groupValue: langTheme.themeMode,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) langTheme.setThemeMode(mode);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(isMr ? 'सिस्टम डिफॉल्ट (System)' : 'System Default'),
              secondary: const Icon(Icons.settings_brightness_rounded,
                  color: Colors.teal),
              value: ThemeMode.system,
              groupValue: langTheme.themeMode,
              activeColor: AppColors.primary,
              onChanged: (mode) {
                if (mode != null) langTheme.setThemeMode(mode);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelectionSheet(
      BuildContext context, LanguageThemeProvider langTheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Select App Language / भाषा निवडा',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Text('🌐', style: TextStyle(fontSize: 24)),
                  title: const Text('English',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Primary App Language'),
                  trailing: langTheme.languageCode == 'en'
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    langTheme.setLanguage('en');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Text('🚩', style: TextStyle(fontSize: 24)),
                  title: const Text('मराठी (Marathi)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('प्रादेशिक भाषा (संपूर्ण अ‍ॅप)'),
                  trailing: langTheme.languageCode == 'mr'
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    langTheme.setLanguage('mr');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                  title: const Text('हिन्दी (Hindi)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('राष्ट्रीय भाषा'),
                  trailing: langTheme.languageCode == 'hi'
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    langTheme.setLanguage('hi');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth, bool isMr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isMr ? 'लॉगआउटची पुष्टी करा' : 'Confirm Logout'),
        content: Text(
          isMr
              ? 'तुम्हाला या डिव्हाइसवरून नक्की लॉगआउट करायचे आहे का? तुमचा ऑफलाइन डेटा सुरक्षित राहील.'
              : 'Are you sure you want to log out from this device? Your offline data will remain securely saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isMr ? 'रद्द करा' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(isMr ? 'लॉगआउट' : 'Log Out'),
          ),
        ],
      ),
    );
  }
}
