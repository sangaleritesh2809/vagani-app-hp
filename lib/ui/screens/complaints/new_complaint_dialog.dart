import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/complaint_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/mandatory_label.dart';

class NewComplaintDialog extends StatefulWidget {
  const NewComplaintDialog({super.key});

  @override
  State<NewComplaintDialog> createState() => _NewComplaintDialogState();
}

class _NewComplaintDialogState extends State<NewComplaintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  ComplaintType _selectedType = ComplaintType.collectionDiscrepancy;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();

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
                        'Submit Inquiry / Complaint (SRS 10)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ComplaintType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                        label: MandatoryLabel('Grievance / Inquiry Type')),
                    items: ComplaintType.values.map((type) {
                      return DropdownMenuItem<ComplaintType>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (t) {
                      if (t != null) setState(() => _selectedType = t);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      label: MandatoryLabel('Subject / Title'),
                      hintText: 'e.g. Discrepancy in Remaining Dues',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter subject'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      label: MandatoryLabel('Detailed Explanation'),
                      hintText:
                          'Please describe your query with payment date/receipt details...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please provide explanation'
                        : null,
                  ),
                  const SizedBox(height: 20),
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
                            data.submitComplaint(
                              type: _selectedType,
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              citizenUser: auth.currentUser,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Inquiry submitted! Committee notified with tracking ID.'),
                                backgroundColor: AppColors.statusPaid,
                              ),
                            );
                          }
                        },
                        child: const Text('Submit Ticket'),
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
