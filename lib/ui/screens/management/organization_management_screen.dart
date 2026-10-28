import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/organization_model.dart';
import '../../../core/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/mandatory_label.dart';

class OrganizationManagementScreen extends StatefulWidget {
  const OrganizationManagementScreen({super.key});

  @override
  State<OrganizationManagementScreen> createState() =>
      _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState
    extends State<OrganizationManagementScreen> {
  List<OrganizationModel> _organizations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    setState(() => _isLoading = true);
    final list = await ApiService.fetchOrganizations();
    if (mounted) {
      setState(() {
        _organizations = list ?? [];
        _isLoading = false;
      });
    }
  }

  void _showAddEditOrgDialog([OrganizationModel? existing]) {
    final auth = context.read<AuthProvider>();
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final regCtrl =
        TextEditingController(text: existing?.registrationNumber ?? '');
    final contactCtrl =
        TextEditingController(text: existing?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final villageCtrl =
        TextEditingController(text: existing?.village ?? 'Pune');
    String selectedType = existing?.organizationType ?? 'Festival Committee';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Edit Organization' : 'Add Organization',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dialogError!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          label: MandatoryLabel('Organization / Mandal Name'),
                        ),
                        validator: (v) => v == null || v.trim().length < 3
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          label: MandatoryLabel('Organization Type'),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Festival Committee',
                            child: Text('Festival Committee'),
                          ),
                          DropdownMenuItem(
                            value: 'Housing Society',
                            child: Text('Housing Society'),
                          ),
                          DropdownMenuItem(
                            value: 'Charitable Trust',
                            child: Text('Charitable Trust'),
                          ),
                          DropdownMenuItem(
                            value: 'Social Organization',
                            child: Text('Social Organization'),
                          ),
                          DropdownMenuItem(
                            value: 'Sports Club',
                            child: Text('Sports Club'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedType = v);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: regCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactCtrl,
                        decoration: const InputDecoration(
                          label: MandatoryLabel('President / Contact Person'),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Contact person is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          label: MandatoryLabel('Mobile Number'),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '10-digit mobile number required';
                          }
                          final clean = v.replaceAll(RegExp(r'\D'), '');
                          if (clean.length != 10 ||
                              !RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
                            return 'Enter a valid 10-digit mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          label: MandatoryLabel('Address / Area'),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Address is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: villageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Village / City',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSaving = true;
                          dialogError = null;
                        });

                        Map<String, dynamic> res;
                        if (isEdit) {
                          res = await ApiService.updateOrganization(
                            orgId: existing.id,
                            name: nameCtrl.text.trim(),
                            contactPerson: contactCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            actorId: auth.currentUser.id,
                          );
                        } else {
                          res = await ApiService.createOrganization(
                            name: nameCtrl.text.trim(),
                            registrationNumber: regCtrl.text.trim(),
                            contactPerson: contactCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            village: villageCtrl.text.trim(),
                            actorId: auth.currentUser.id,
                          );
                        }

                        if (!mounted) return;
                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? 'Organization details updated successfully!'
                                  : 'New organization added successfully!'),
                              backgroundColor: AppColors.statusPaid,
                            ),
                          );
                          _loadOrganizations();
                        } else {
                          setDialogState(() {
                            isSaving = false;
                            dialogError = res['message'];
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Save' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Management'),
        actions: [
          IconButton(
            onPressed: _loadOrganizations,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: auth.isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditOrgDialog(),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Add Organization'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _organizations.isEmpty
              ? const Center(
                  child: Text('No organizations available.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _organizations.length,
                  itemBuilder: (context, index) {
                    final org = _organizations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      color: isDark ? AppColors.darkCardBg : Colors.white,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.business_rounded,
                                      color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        org.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Reg: ${org.registrationNumber} • ID: ${org.id}',
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    org.status,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  'President: ${org.contactPerson}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Spacer(),
                                const Icon(Icons.phone_rounded,
                                    size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  org.phone,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${org.address}, ${org.village}, ${org.district}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (auth.isSuperAdmin) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showAddEditOrgDialog(org),
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 14),
                                    label: const Text('Edit'),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
