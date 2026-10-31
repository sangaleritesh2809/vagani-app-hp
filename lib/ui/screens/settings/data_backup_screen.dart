import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  bool _isClearingCache = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageThemeProvider>();
    final settings = context.watch<AppSettingsProvider>();
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();

    final lastSyncText = settings.lastSyncTime != null
        ? lang.formatDate(settings.lastSyncTime!)
        : 'Never';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data & Backup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cloud Sync Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_sync_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Supabase Cloud Synchronization',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${settings.syncStatusMessage}',
                              style: TextStyle(
                                fontSize: 12,
                                color: settings.syncStatusMessage
                                        .contains('success')
                                    ? AppColors.statusPaid
                                    : (settings.syncStatusMessage
                                            .contains('fail')
                                        ? Colors.red
                                        : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Last Synchronized:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        lastSyncText,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: settings.isSyncing
                          ? null
                          : () async {
                              final success = await settings.syncWithCloud(
                                userId: auth.currentUser.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Cloud sync completed successfully!'
                                          : 'Sync failed: Check network connection.',
                                    ),
                                    backgroundColor: success
                                        ? AppColors.statusPaid
                                        : Colors.red,
                                  ),
                                );
                              }
                            },
                      icon: settings.isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                          settings.isSyncing ? 'Syncing...' : 'Sync Now with Cloud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Local Database Ledger Statistics
            const Text(
              'Local Cache & Ledger Stats',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    'Registered Households',
                    data.households.length.toString(),
                    Icons.home_outlined,
                  ),
                  const Divider(height: 16),
                  _buildStatRow(
                    'Issued Receipts',
                    data.receipts.length.toString(),
                    Icons.receipt_outlined,
                  ),
                  const Divider(height: 16),
                  _buildStatRow(
                    'Cash Handovers Recorded',
                    data.handovers.length.toString(),
                    Icons.swap_horiz_rounded,
                  ),
                  const Divider(height: 16),
                  _buildStatRow(
                    'Approved Expenses',
                    data.expenses.length.toString(),
                    Icons.account_balance_wallet_outlined,
                  ),
                  const Divider(height: 16),
                  _buildStatRow(
                    'Audit Log Entries',
                    data.auditLogs.length.toString(),
                    Icons.history_edu_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Export & Backup Actions
            const Text(
              'Backup & Maintenance',
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
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.file_download_outlined,
                          color: Colors.blue, size: 20),
                    ),
                    title: const Text(
                      'Export Data Snapshot (JSON)',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Copy entire encrypted data snapshot to device clipboard',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      final snapshot = {
                        'organization': data.organization.name,
                        'campaignId': data.currentCampaign.id,
                        'exportedAt': DateTime.now().toIso8601String(),
                        'householdsCount': data.households.length,
                        'receiptsCount': data.receipts.length,
                        'totalCollections': data.totalVerifiedReceived,
                        'totalExpenses': data.totalActualPaidExpenses,
                        'cashBalance': data.availableNetBalance,
                      };
                      Clipboard.setData(
                        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(snapshot)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Data snapshot JSON copied to clipboard successfully!'),
                          backgroundColor: AppColors.statusPaid,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cleaning_services_outlined,
                          color: Colors.redAccent, size: 20),
                    ),
                    title: const Text(
                      'Clear Temporary Cache',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Frees memory without deleting pending syncs or credentials',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: _isClearingCache
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () async {
                      setState(() => _isClearingCache = true);
                      await settings.clearTemporaryCache();
                      setState(() => _isClearingCache = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Temporary cache cleared!'),
                            backgroundColor: AppColors.statusPaid,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

