import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/household_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/mandatory_label.dart';

class HouseholdFormDialog extends StatefulWidget {
  final HouseholdModel? householdToEdit;

  const HouseholdFormDialog({super.key, this.householdToEdit});

  @override
  State<HouseholdFormDialog> createState() => _HouseholdFormDialogState();
}

class _HouseholdFormDialogState extends State<HouseholdFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _areaController;
  late final TextEditingController _membersController;

  late int _memberCount;

  bool get _isEdit => widget.householdToEdit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.householdToEdit;
    _nameController = TextEditingController(text: h?.headOfFamilyName ?? '');
    _mobileController = TextEditingController(text: h?.mobileNumber ?? '');
    _areaController = TextEditingController(text: h?.villageArea ?? '');
    _membersController = TextEditingController(
        text: h != null ? h.familyMemberCount.toString() : '');
    _memberCount = h?.familyMemberCount ?? 0;
  }

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
    final rate = _isEdit
        ? widget.householdToEdit!.perPersonRateSnapshot
        : campaign.perPersonRate;
    final expectedTotal = _memberCount * rate;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEdit ? 'Edit Household' : 'Register Household',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                  const MandatoryLabel('Head of Family Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter head of family name',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter head of family name'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number
                  const MandatoryLabel('Mobile Number'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: 'Enter 10-digit mobile number',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    validator: (v) {
                      final val = (v ?? '').trim();
                      if (val.isEmpty) {
                        return 'Please enter 10-digit mobile number';
                      }
                      if (val.length != 10) {
                        return 'Mobile number must be exactly 10 digits';
                      }
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val)) {
                        return 'Must be valid mobile number (starting with 6, 7, 8, or 9)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Village / Area / Ward
                  const MandatoryLabel('Village / Ward / Area'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      hintText: 'Enter village, ward or area',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter area or lane'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Family Member Count (Reactive auto-calculation SRS 5.3)
                  const MandatoryLabel('Family Member Count'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _membersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter total family members',
                      prefixIcon: Icon(Icons.group_rounded),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val.trim()) ?? 0;
                      setState(() {
                        _memberCount = parsed > 0 ? parsed : 0;
                      });
                    },
                    validator: (v) {
                      final val = int.tryParse(v?.trim() ?? '');
                      if (val == null || val <= 0) {
                        return 'Enter valid count (e.g. 1, 2, 4...)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Reactive Calculation Highlight Card (SRS 5.3)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.calculate_rounded,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Auto Expected Vargani Calculation',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runAlignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              _memberCount > 0
                                  ? '$_memberCount members × ₹${rate.toStringAsFixed(0)} / person'
                                  : '0 members × ₹${rate.toStringAsFixed(0)} / person',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
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
                        const SizedBox(height: 6),
                        const Text(
                          '* Rate snapshot will be permanently preserved for this household.',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey),
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
                            if (_isEdit) {
                              final ok = data.updateHousehold(
                                id: widget.householdToEdit!.id,
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
                                    ok
                                        ? 'Updated ${_nameController.text.trim()}! Expected: ₹${expectedTotal.toStringAsFixed(0)}'
                                        : 'Failed to update: only pending households can be edited.',
                                  ),
                                  backgroundColor: ok
                                      ? AppColors.statusPaid
                                      : Colors.redAccent,
                                ),
                              );
                            } else {
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
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Save'),
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
