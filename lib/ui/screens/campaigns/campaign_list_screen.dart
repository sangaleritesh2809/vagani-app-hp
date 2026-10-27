import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/campaign_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import 'campaign_config_dialog.dart';

class CampaignListScreen extends StatelessWidget {
  const CampaignListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: data.campaigns.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final c = data.campaigns[index];
          final isSelected = c.id == data.selectedCampaignId;

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c.varganiType.displayName.split('(').first.trim(),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusPaid.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 12, color: AppColors.statusPaid),
                            SizedBox(width: 4),
                            Text('ACTIVE CAMPAIGN',
                                style: TextStyle(
                                    color: AppColors.statusPaid,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  c.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  c.description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(langTheme.tr('perPersonRate'),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                          langTheme.formatCurrency(c.perPersonRate),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(langTheme.tr('targetAmount'),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                          langTheme.formatCurrency(c.targetAmount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('कालावधी / Duration',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          '${langTheme.formatDate(c.startDate)} - ${langTheme.formatDate(c.endDate)}',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (auth.canManageCampaigns)
                      OutlinedButton.icon(
                        onPressed: () {
                          data.selectCampaign(c.id);
                          showDialog(
                            context: context,
                            builder: (_) => const CampaignConfigDialog(),
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Configure Rate (SRS 5.1)'),
                      ),
                    const SizedBox(width: 10),
                    if (!isSelected)
                      ElevatedButton(
                        onPressed: () {
                          data.selectCampaign(c.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to ${c.name}!'),
                              backgroundColor: AppColors.statusPaid,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Select Campaign'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
