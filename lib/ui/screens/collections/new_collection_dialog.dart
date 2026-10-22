import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/household_model.dart';
import '../../../core/models/payment_model.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import 'receipt_detail_dialog.dart';

class NewCollectionDialog extends StatefulWidget {
  final HouseholdModel? preselectedHousehold;

  const NewCollectionDialog({super.key, this.preselectedHousehold});

  @override
  State<NewCollectionDialog> createState() => _NewCollectionDialogState();
}

class _NewCollectionDialogState extends State<NewCollectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedHouseholdId;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _remarksController = TextEditingController();

  PaymentType _selectedPaymentType = PaymentType.cash;
  late UserModel _selectedReceivedByUser;

  @override
  void initState() {
    super.initState();
    _selectedHouseholdId = widget.preselectedHousehold?.id;
    if (widget.preselectedHousehold != null) {
      final rem = widget.preselectedHousehold!.remainingAmount;
      _amountController.text = (rem > 0 ? rem : widget.preselectedHousehold!.expectedTotalVargani).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final availableHouseholds = data.households;
    final orgUsers = auth.availableUsers.where((u) => u.role != UserRole.citizen).toList();
    _selectedReceivedByUser = orgUsers.firstWhere(
      (u) => u.role == UserRole.treasurer,
      orElse: () => orgUsers.first,
    );

    HouseholdModel? selectedHousehold;
    if (_selectedHouseholdId != null) {
      selectedHousehold = availableHouseholds.firstWhere(
        (h) => h.id == _selectedHouseholdId,
        orElse: () => availableHouseholds.first,
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                        'Record Contribution (SRS 6)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Household Selector
                  DropdownButtonFormField<String>(
                    value: _selectedHouseholdId,
                    decoration: const InputDecoration(
                      labelText: 'Select Household / Contributor *',
                      prefixIcon: Icon(Icons.home_work_rounded),
                    ),
                    items: availableHouseholds.map((h) {
                      return DropdownMenuItem<String>(
                        value: h.id,
                        child: Text('${h.headOfFamilyName} (${h.villageArea})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedHouseholdId = val;
                        final h = availableHouseholds.firstWhere((item) => item.id == val);
                        final rem = h.remainingAmount;
                        _amountController.text = (rem > 0 ? rem : h.expectedTotalVargani).toStringAsFixed(0);
                      });
                    },
                    validator: (v) => v == null ? 'Please select a household' : null,
                  ),
                  const SizedBox(height: 12),

                  // Household Due Summary Banner
                  if (selectedHousehold != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Expected: ₹${selectedHousehold.expectedTotalVargani.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            'Already Paid: ₹${selectedHousehold.amountReceived.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppColors.statusPaid, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            'Remaining: ₹${selectedHousehold.remainingAmount.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppColors.statusPending, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Payment Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount (रक्कम) *',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                      hintText: 'Enter amount paid',
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) return 'Enter valid amount greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Payment Type Selector (Cash, UPI, Bank Transfer, Other)
                  const Text('Payment Mode (पेमेंट पद्धत) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: PaymentType.values.map((type) {
                      final isSelected = _selectedPaymentType == type;
                      return ChoiceChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPaymentType = type;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // UPI QR Display & Reference ID (SRS 6.4)
                  if (_selectedPaymentType == PaymentType.upi) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusPaid.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          QrImageView(
                            data: 'upi://pay?pa=mandal@upi&pn=${Uri.encodeComponent(data.organization.name)}&am=${_amountController.text}&cu=INR',
                            version: QrVersions.auto,
                            size: 70.0,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Scan to Pay via UPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('mandal@upi • PhonePe / GPay / Paytm', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'UPI UTR / Transaction Reference *',
                        hintText: 'e.g. UPI-492019482910',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter UPI transaction reference' : null,
                    ),
                    const SizedBox(height: 14),
                  ] else if (_selectedPaymentType == PaymentType.bankTransfer) ...[
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Reference / NEFT UTR *',
                        hintText: 'e.g. NEFT-SBIN260904001',
                        prefixIcon: Icon(Icons.account_balance_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter bank reference' : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Collected By (Read-only SRS 6.1 & 16)
                  TextFormField(
                    initialValue: auth.currentUser.name,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Collected By (Read-only, Authenticated Collector)',
                      prefixIcon: Icon(Icons.badge_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Received By (Searchable User Dropdown SRS 6.1 & 16)
                  DropdownButtonFormField<UserModel>(
                    value: _selectedReceivedByUser,
                    decoration: const InputDecoration(
                      labelText: 'Authorized Received By (Same Organization) *',
                      prefixIcon: Icon(Icons.verified_user_rounded),
                    ),
                    items: orgUsers.map((u) {
                      return DropdownMenuItem<UserModel>(
                        value: u,
                        child: Text('${u.name} (${u.role.nameString})'),
                      );
                    }).toList(),
                    onChanged: (u) {
                      if (u != null) {
                        setState(() {
                          _selectedReceivedByUser = u;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Remarks
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks / Notes (Optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
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
                            final amount = double.parse(_amountController.text.trim());
                            final receipt = data.recordPayment(
                              householdId: _selectedHouseholdId!,
                              amount: amount,
                              paymentType: _selectedPaymentType,
                              referenceId: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
                              currentUser: auth.currentUser,
                              receivedByUser: _selectedReceivedByUser,
                              remarks: _remarksController.text.trim(),
                            );

                            Navigator.pop(context);

                            // Open the receipt detail modal right away!
                            showDialog(
                              context: context,
                              builder: (_) => ReceiptDetailDialog(receipt: receipt),
                            );
                          }
                        },
                        child: const Text('Issue Receipt (VRG)'),
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
