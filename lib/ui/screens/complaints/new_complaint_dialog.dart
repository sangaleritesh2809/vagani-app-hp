import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/complaint_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_theme_provider.dart';
import '../../../providers/vargani_data_provider.dart';

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

  Widget _buildFieldLabel(String label, {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final langTheme = context.watch<LanguageThemeProvider>();
    final isMarathi = langTheme.isMarathi;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Row with close icon (Responsive with Expanded)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isMarathi
                              ? 'तक्रार / चौकशी नोंदवा'
                              : 'Submit Inquiry / Complaint',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Grievance / Inquiry Type Label (Outside input box)
                  _buildFieldLabel(
                    isMarathi
                        ? 'तक्रार / चौकशीचा प्रकार'
                        : 'Grievance / Inquiry Type',
                  ),
                  DropdownButtonFormField<ComplaintType>(
                    value: _selectedType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ComplaintType.values.map((type) {
                      return DropdownMenuItem<ComplaintType>(
                        value: type,
                        child: Text(
                          type.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (t) {
                      if (t != null) setState(() => _selectedType = t);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Subject / Title Label (Outside input box)
                  _buildFieldLabel(
                    isMarathi ? 'विषय / शीर्षक' : 'Subject / Title',
                  ),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: isMarathi
                          ? 'उदा. वर्गणी पावती किंवा रक्कमेत फरक'
                          : 'e.g. Discrepancy in Remaining Dues',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (isMarathi
                            ? 'कृपया विषय प्रविष्ट करा'
                            : 'Please enter subject')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Detailed Explanation Label (Outside input box)
                  _buildFieldLabel(
                    isMarathi
                        ? 'सविस्तर माहिती / कारण'
                        : 'Detailed Explanation',
                  ),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: isMarathi
                          ? 'कृपया आपल्या समस्येचा सविस्तर तपशील द्या...'
                          : 'Please describe your query with payment date/receipt details...',
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (isMarathi
                            ? 'कृपया सविस्तर माहिती द्या'
                            : 'Please provide explanation')
                        : null,
                  ),
                  const SizedBox(height: 22),

                  // Actions: Cancel & Submit buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(isMarathi ? 'रद्द करा' : 'Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                              SnackBar(
                                content: Text(
                                  isMarathi
                                      ? 'तक्रार यशस्वीरित्या नोंदवली गेली आहे!'
                                      : 'Inquiry submitted! Committee notified with tracking ID.',
                                ),
                                backgroundColor: AppColors.statusPaid,
                              ),
                            );
                          }
                        },
                        child: Text(
                          isMarathi ? 'नोंदणी करा' : 'Submit Ticket',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
