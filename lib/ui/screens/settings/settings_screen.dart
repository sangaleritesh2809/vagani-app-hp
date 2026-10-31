import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../auth/group_selection_screen.dart';
import '../campaigns/campaign_config_dialog.dart';
import '../profile/user_profile_dialog.dart';
import '../profile/user_profile_screen.dart';
import '../management/organization_management_screen.dart';
import '../management/role_management_screen.dart';
import '../management/user_management_screen.dart';
import '../auth/login_screen.dart';
import '../../widgets/organization_status_card.dart';

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
          // User Card with Role Badge & Profile Details
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
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      auth.currentUser.name.isNotEmpty
                          ? auth.currentUser.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${auth.currentUser.phone} • ${auth.selectedGroup?.name ?? "Central Division"}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                auth.currentRole.nameString,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: auth.currentUser.isActive
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                auth.currentUser.isActive
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: auth.currentUser.isActive
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
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),



          // Administration & PBAC Management (Rules 1, 2, 3, 4, 5)
          if (!auth.isCitizen) ...[
            const Text(
              'Administration & Access Control (RBAC)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Material(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    // User Management (Rule 5)
                    if (auth.canViewUsers || auth.canManageUsers)
                      ListTile(
                        leading: const Icon(Icons.manage_accounts_rounded,
                            color: AppColors.primary),
                        title: const Text('User Management'),
                        subtitle: const Text(
                            'Manage users, roles and active/inactive status'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserManagementScreen()),
                          );
                        },
                      ),

                    // Role Management (Rule 3 & 4)
                    if (auth.canManageRoles) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security_rounded,
                            color: Colors.indigo),
                        title: const Text('Roles & Dynamic PBAC'),
                        subtitle: const Text(
                            'Create roles and assign granular permissions'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RoleManagementScreen()),
                          );
                        },
                      ),
                    ],

                    // Organization Management (Rule 1 & 2 - Super Admin)
                    if (auth.isSuperAdmin) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.business_rounded,
                            color: Colors.purple),
                        title: const Text('Organization Management'),
                        subtitle: const Text(
                            'Super Admin: Manage organizations and divisions'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const OrganizationManagementScreen()),
                          );
                        },
                      ),
                    ],

                    // Change Group Jurisdiction (Rule 6)
                    if (auth.authorizedGroups.length > 1) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.group_work_rounded,
                            color: Colors.teal),
                        title: const Text('Switch Active Group'),
                        subtitle: Text(
                          'Current: ${auth.selectedGroup?.name ?? "Central Division"}',
                        ),
                        trailing:
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const GroupSelectionScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quick Role Switcher for Testing (SRS 3 & Requirement 9) - Only visible to Super Admin (Hidden for Citizens)
          if (auth.isSuperAdmin && !auth.isCitizen) ...[
            const Text('Switch Demo Role (Testing RBAC)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Material(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  children: auth.availableUsers.map((user) {
                    final isSelected = auth.currentUser.id == user.id;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_off_rounded,
                        color: isSelected ? AppColors.primary : Colors.grey,
                      ),
                      title: Text(user.name,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      subtitle: Text(
                          '${user.role.nameString} • ${user.phone} • ${user.isActive ? "Active" : "Inactive"}'),
                      onTap: () => auth.switchUser(user),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Citizen Phone OTP Login Simulator (SRS 9 & 12 FR-01)
            const Text('Citizen Phone OTP Login (FR-01)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // App Settings & Preferences
          const Text('Preferences & Localization',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Material(
            color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded,
                        color: AppColors.primary),
                    title: Text(langTheme.tr('language')),
                    subtitle: Text(
                      langTheme.languageCode == 'mr'
                          ? 'Marathi'
                          : (langTheme.languageCode == 'hi'
                              ? 'Hindi'
                              : 'English (Primary)'),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () =>
                        _showLanguageSelectionSheet(context, langTheme),
                  ),

                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      langTheme.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: Colors.amber,
                    ),
                    title: Text(langTheme.tr('themeMode')),
                    subtitle: Text(langTheme.isDarkMode
                        ? langTheme.tr('darkMode')
                        : langTheme.tr('lightMode')),
                    trailing: Switch(
                      value: langTheme.isDarkMode,
                      activeColor: AppColors.primary,
                      onChanged: (val) => langTheme.toggleTheme(),
                    ),
                  ),
                  if (auth.canManageCampaigns) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.price_change_rounded,
                          color: AppColors.statusPaid),
                      title: const Text('Configure Vargani Rate (SRS 5.1)'),
                      subtitle: Text(
                          'Current Rate: ₹${data.currentCampaign.perPersonRate.toStringAsFixed(0)} / person'),
                      trailing:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) => const CampaignConfigDialog());
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Organization Info (SRS 4)
          const Text('Organization Information (SRS 4)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.organization.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Registration: ${data.organization.registrationNumber}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('President / Contact: ${data.organization.contactPerson}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Address: ${data.organization.address}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                    'Location: ${data.organization.village}, ${data.organization.taluka}, ${data.organization.district}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // About Vargani Card with Official Logo
          Container(
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
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vargani Pro (वर्गणी)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Digital Vargani & Receipt Management System',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version 1.0.0 • Production Build',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log Out Button Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 22),
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              subtitle: const Text(
                'Return to Login Screen',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: Colors.redAccent),
              onTap: () {
                auth.logout();
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showCitizenOtpDialog(BuildContext context, AuthProvider auth) {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Citizen Phone OTP Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter mobile number and OTP received:',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Mobile Number')),
            const SizedBox(height: 12),
            TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: 'OTP')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              auth.simulateCitizenOtpLogin(
                  phoneController.text.trim(), otpController.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Logged in as Citizen! Switched to Public Transparency view.'),
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    langTheme.tr('chooseLanguage'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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
                  title: const Text('Marathi',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Regional Language'),
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
                  title: const Text('Hindi',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('National Language'),
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
}
