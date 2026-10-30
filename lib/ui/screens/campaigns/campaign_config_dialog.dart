import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/mandatory_label.dart';

class CampaignConfigDialog extends StatefulWidget {
  const CampaignConfigDialog({super.key});

  @override
  State<CampaignConfigDialog> createState() => _CampaignConfigDialogState();
}

class _CampaignConfigDialogState extends State<CampaignConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rateController;

  @override
  void initState() {
    super.initState();
    final data = Provider.of<VarganiDataProvider>(context, listen: false);
    _rateController = TextEditingController(
      text: data.currentCampaign.perPersonRate.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final campaign = data.currentCampaign;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Configure Vargani Rate',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Campaign: ${campaign.name}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    label: MandatoryLabel('Per-Person Vargani Amount (₹)'),
                    hintText: 'e.g. 100',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                  validator: (v) {
                    final p = double.tryParse(v ?? '');
                    if (p == null || p <= 0) return 'Must be a positive rate';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // BR-10 Historical Rate Preservation Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'SRS Rule BR-10 / 5.1: Rate changes apply only to future registrations. Existing households preserve their recorded rate snapshot with full audit history.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final newRate =
                              double.parse(_rateController.text.trim());
                          data.updateCampaignPerPersonRate(
                            newRate: newRate,
                            currentUser: auth.currentUser,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Campaign rate updated to ₹${newRate.toStringAsFixed(0)} / person!'),
                              backgroundColor: AppColors.statusPaid,
                            ),
                          );
                        }
                      },
                      child: const Text('Update Rate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
