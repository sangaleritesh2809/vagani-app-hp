import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';

class HouseholdFormDialog extends StatefulWidget {
  const HouseholdFormDialog({super.key});

  @override
  State<HouseholdFormDialog> createState() => _HouseholdFormDialogState();
}

class _HouseholdFormDialogState extends State<HouseholdFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _areaController = TextEditingController();
  final _membersController = TextEditingController(text: '4');

  int _memberCount = 4;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _areaController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final campaign = data.currentCampaign;
    final rate = campaign.perPersonRate;
    final expectedTotal = _memberCount * rate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Register Household (Option A)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
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

                  // Head of Family Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Head of Family Name (कुटुंबप्रमुख) *',
                      hintText: 'e.g. Rahul Patil',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter head of family name' : null,
                  ),
                  const SizedBox(height: 14),

                  // Mobile Number
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      hintText: 'e.g. 9823401122',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    validator: (v) => (v == null || v.length < 10) ? 'Enter valid 10-digit mobile' : null,
                  ),
                  const SizedBox(height: 14),

                  // Village / Area / Ward
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Village / Ward / Area *',
                      hintText: 'e.g. Shivaji Chowk, Lane 3',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter area or lane' : null,
                  ),
                  const SizedBox(height: 14),

                  // Family Member Count (Reactive auto-calculation SRS 5.3)
                  TextFormField(
                    controller: _membersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Family Member Count (एकूण सदस्य) *',
                      hintText: 'e.g. 4',
                      prefixIcon: Icon(Icons.group_rounded),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      setState(() {
                        _memberCount = parsed > 0 ? parsed : 0;
                      });
                    },
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Must be positive whole number (BR-02)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Reactive Calculation Highlight Card (SRS 5.3)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calculate_rounded, color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Auto Expected Vargani Calculation (SRS 5.3)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$_memberCount members × ₹${rate.toStringAsFixed(0)} / person',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '= ₹${expectedTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '* Rate snapshot will be permanently preserved for this household.',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            data.registerHousehold(
                              headOfFamilyName: _nameController.text.trim(),
                              mobileNumber: _mobileController.text.trim(),
                              villageArea: _areaController.text.trim(),
                              familyMemberCount: _memberCount,
                              currentUser: auth.currentUser,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Registered ${_nameController.text.trim()}! Expected: ₹${expectedTotal.toStringAsFixed(0)}',
                                ),
                                backgroundColor: AppColors.statusPaid,
                              ),
                            );
                          }
                        },
                        child: const Text('Save Household'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
