import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/expense_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _vendorController = TextEditingController();
  final _billController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.tent;
  String _paymentMode = 'Cash';
  bool _hasProof = false;
  bool _isPublicVisible = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _vendorController.dispose();
    _billController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        'Record Event Expense (SRS 8)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  DropdownButtonFormField<ExpenseCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Expense Category (खर्चाचा प्रकार) *'),
                    items: ExpenseCategory.values.map((cat) {
                      return DropdownMenuItem<ExpenseCategory>(
                        value: cat,
                        child: Text(cat.displayName),
                      );
                    }).toList(),
                    onChanged: (cat) {
                      if (cat != null) setState(() => _selectedCategory = cat);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Title / Description *',
                      hintText: 'e.g. Mandap and Stage Setup',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter title' : null,
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹) *',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Vendor & Bill
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _vendorController,
                          decoration: const InputDecoration(
                            labelText: 'Vendor / Payee *',
                            hintText: 'e.g. Sai Decors',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter vendor' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _billController,
                          decoration: const InputDecoration(
                            labelText: 'Bill / Invoice No',
                            hintText: 'e.g. INV-904',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Payment Mode
                  DropdownButtonFormField<String>(
                    value: _paymentMode,
                    decoration: const InputDecoration(labelText: 'Payment Mode'),
                    items: ['Cash', 'UPI', 'Bank Transfer', 'Cheque'].map((mode) {
                      return DropdownMenuItem<String>(value: mode, child: Text(mode));
                    }).toList(),
                    onChanged: (mode) {
                      if (mode != null) setState(() => _paymentMode = mode);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Has Proof Toggle (SRS 8 requirement: Display Proof Not Uploaded if false)
                  SwitchListTile(
                    title: const Text('Proof / Bill Uploaded?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _hasProof ? 'Bill attached' : 'Proof Not Uploaded indicator will be shown (SRS 8)',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    value: _hasProof,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _hasProof = val),
                  ),

                  // Public Visibility Toggle (SRS 8 & 9)
                  SwitchListTile(
                    title: const Text('Publicly Visible on Dashboard?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Allow citizens to view this approved expense', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: _isPublicVisible,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isPublicVisible = val),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            data.addExpense(
                              category: _selectedCategory,
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              amount: double.parse(_amountController.text.trim()),
                              vendorPayee: _vendorController.text.trim(),
                              paymentMode: _paymentMode,
                              billNumber: _billController.text.trim().isEmpty ? 'N/A' : _billController.text.trim(),
                              hasProof: _hasProof,
                              currentUser: auth.currentUser,
                              isPublicVisible: _isPublicVisible,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense submitted for review!'),
                                backgroundColor: AppColors.statusPaid,
                              ),
                            );
                          }
                        },
                        child: const Text('Save Expense'),
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
