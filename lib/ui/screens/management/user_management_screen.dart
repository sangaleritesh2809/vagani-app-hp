import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/organization_model.dart';
import '../../../core/models/role_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/mandatory_label.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  List<OrganizationModel> _organizations = [];
  List<GroupModel> _groups = [];
  List<RoleModel> _roles = [];
  bool _isLoading = true;

  // Search & Filters
  final TextEditingController _searchController = TextEditingController();
  String _selectedOrgFilter = 'all';
  String _selectedGroupFilter = 'all';
  String _selectedRoleFilter = 'all';
  String _selectedStatusFilter = 'all'; // 'all', 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await ApiService.fetchUsers();
    final orgs = await ApiService.fetchOrganizations();
    final groups = await ApiService.fetchGroups();
    final roles = await ApiService.fetchRoles();

    if (mounted) {
      setState(() {
        _users = users ?? [];
        _organizations = orgs ?? [];
        _groups = groups ?? [];
        _roles = roles ?? [];
        _isLoading = false;
      });
    }
  }

  // Filtered Users
  List<UserModel> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users.where((user) {
      // 1. Text Search
      if (query.isNotEmpty) {
        final matchesName = user.name.toLowerCase().contains(query);
        final matchesPhone =
            user.phone.replaceAll(RegExp(r'\D'), '').contains(query);
        final matchesEmail = user.email.toLowerCase().contains(query);
        if (!matchesName && !matchesPhone && !matchesEmail) {
          return false;
        }
      }

      // 2. Organization Filter
      if (_selectedOrgFilter != 'all' &&
          user.organizationId != _selectedOrgFilter) {
        return false;
      }

      // 3. Group Filter
      if (_selectedGroupFilter != 'all') {
        final inSelectedGroup = user.groupIds.contains(_selectedGroupFilter) ||
            user.selectedGroupId == _selectedGroupFilter;
        if (!inSelectedGroup) return false;
      }

      // 4. Role Filter
      if (_selectedRoleFilter != 'all') {
        final matchesRole = user.role.roleKey == _selectedRoleFilter ||
            user.role.name == _selectedRoleFilter ||
            user.customRoleName == _selectedRoleFilter;
        if (!matchesRole) return false;
      }

      // 5. Status Filter
      if (_selectedStatusFilter == 'active' && !user.isActive) return false;
      if (_selectedStatusFilter == 'inactive' && user.isActive) return false;

      return true;
    }).toList();
  }

  // ===========================================================================
  // Toggle Status with Confirmation & Financial Records Protection
  // ===========================================================================
  Future<void> _confirmAndToggleStatus(UserModel user, bool newStatus) async {
    final auth = context.read<AuthProvider>();

    // Super Admin cannot be deactivated
    if (user.role == UserRole.superAdmin && !newStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Super Admin खाते निष्क्रिय करता येत नाही (Super Admin cannot be deactivated).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Check financial transactions before deactivating
    bool hasFinancialRecords = false;
    if (!newStatus) {
      hasFinancialRecords = await ApiService.hasFinancialTransactions(user.id);
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              newStatus
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              color: newStatus ? Colors.green : Colors.orangeAccent,
            ),
            const SizedBox(width: 10),
            Text(
              newStatus ? 'खाते सक्रिय करा' : 'खाते निष्क्रिय करा',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'आपण खरोखरच "${user.name}" यांचे खाते ${newStatus ? 'सक्रिय' : 'निष्क्रिय'} करू इच्छिता?',
              style: const TextStyle(fontSize: 14),
            ),
            if (hasFinancialRecords) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.security_rounded,
                        size: 20, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'महत्त्वाचे: या युजरशी संबंधित वर्गणी पावत्या व आर्थिक नोंदी कायमस्वरूपी सुरक्षित राहतील. डेटा डिलीट होणार नाही.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('रद्द करा (Cancel)'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus ? AppColors.statusPaid : Colors.redAccent,
            ),
            child: Text(
              newStatus
                  ? 'सक्रिय करा (Activate)'
                  : 'निष्क्रिय करा (Deactivate)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await ApiService.toggleUserStatus(
      userId: user.id,
      isActive: newStatus,
      actorId: auth.currentUser.id,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              res['data']?['message'] ?? 'खाते स्थिती यशस्वीरित्या बदलली.'),
          backgroundColor:
              newStatus ? AppColors.statusPaid : Colors.orangeAccent,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'खाते स्थिती बदलण्यात अडचण आली.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ===========================================================================
  // View User Details Dialog
  // ===========================================================================
  void _showUserDetailsDialog(UserModel user) {
    final org = _organizations.firstWhere(
      (o) => o.id == user.organizationId,
      orElse: () => OrganizationModel(
        id: user.organizationId,
        name: user.organizationId,
        registrationNumber: '',
        contactPerson: '',
        phone: '',
        address: '',
        registrationDate: DateTime(2020),
      ),
    );
    final group = _groups.firstWhere(
      (g) =>
          g.id ==
          (user.selectedGroupId ??
              (user.groupIds.isNotEmpty ? user.groupIds.first : '')),
      orElse: () => const GroupModel(
          id: '',
          organizationId: '',
          name: 'सर्व गट (All Groups)',
          code: '',
          description: ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                user.name.isNotEmpty
                    ? user.name.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.role.nameString,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.phone_rounded, 'मोबाईल नंबर', user.phone),
                _buildDetailRow(Icons.email_rounded, 'ईमेल पत्ता',
                    user.email.isNotEmpty ? user.email : 'उपलब्ध नाही'),
                _buildDetailRow(
                    Icons.location_on_rounded,
                    'पत्ता (Address)',
                    user.address?.isNotEmpty == true
                        ? user.address!
                        : 'नोंदवलेला नाही'),
                _buildDetailRow(
                    Icons.business_rounded, 'संस्था (Organization)', org.name),
                _buildDetailRow(
                    Icons.groups_rounded, 'गट / मंडळ (Group)', group.name),
                _buildDetailRow(
                  Icons.verified_user_rounded,
                  'खाते स्थिती (Account Status)',
                  user.isActive ? 'Active (सक्रिय)' : 'Inactive (निष्क्रिय)',
                  color: user.isActive ? Colors.green : Colors.redAccent,
                ),
                if (user.notes != null && user.notes!.isNotEmpty)
                  _buildDetailRow(Icons.note_alt_rounded,
                      'अंतर्गत नोंदी (Admin Notes)', user.notes!),
                if (user.createdAt != null)
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    'नोंदणी दिनांक (Created At)',
                    '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year} ${user.createdAt!.hour.toString().padLeft(2, '0')}:${user.createdAt!.minute.toString().padLeft(2, '0')}',
                  ),
                if (user.updatedAt != null)
                  _buildDetailRow(
                    Icons.update_rounded,
                    'अद्यतन दिनांक (Updated At)',
                    '${user.updatedAt!.day}/${user.updatedAt!.month}/${user.updatedAt!.year} ${user.updatedAt!.hour.toString().padLeft(2, '0')}:${user.updatedAt!.minute.toString().padLeft(2, '0')}',
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('बंद करा (Close)'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddEditUserDialog(user);
            },
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('माहिती बदला (Edit)'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // User Create / Edit Form Dialog (All 9 required fields; NO family count)
  // ===========================================================================
  void _showAddEditUserDialog([UserModel? existing]) {
    final auth = context.read<AuthProvider>();
    final isEdit = existing != null;

    // Field Controllers
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final passwordCtrl =
        TextEditingController(text: isEdit ? '' : 'Vargani@123');
    bool obscurePassword = true;

    // Organization Selection
    String selectedOrg = existing?.organizationId ??
        (auth.currentUser.isSuperAdmin
            ? (_organizations.isNotEmpty ? _organizations.first.id : 'org_001')
            : auth.currentUser.organizationId);

    // Group Selection
    List<GroupModel> orgGroups =
        _groups.where((g) => g.organizationId == selectedOrg).toList();
    String? selectedGroup = existing != null && existing.groupIds.isNotEmpty
        ? existing.groupIds.first
        : (orgGroups.isNotEmpty ? orgGroups.first.id : null);

    // Dynamic Roles Selection (Placeholder "Role निवडा")
    // Filter out superAdmin for unauthorized admins
    final assignableRoles = _roles.where((r) {
      if (!auth.currentUser.isSuperAdmin &&
          (r.isSuperAdmin || r.code == 'superAdmin')) {
        return false;
      }
      return true;
    }).toList();

    String? selectedRoleCode;
    if (isEdit) {
      selectedRoleCode = existing.role.roleKey;
      // If role matches code in assignableRoles
      if (!assignableRoles.any(
          (r) => r.roleKey == selectedRoleCode || r.code == selectedRoleCode)) {
        selectedRoleCode =
            assignableRoles.isNotEmpty ? assignableRoles.first.roleKey : null;
      }
    }

    // Account Status
    String selectedStatus =
        existing != null ? existing.accountStatus : 'active';

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Re-filter groups whenever organization changes
          final currentOrgGroups =
              _groups.where((g) => g.organizationId == selectedOrg).toList();
          if (selectedGroup != null &&
              !currentOrgGroups.any((g) => g.id == selectedGroup)) {
            selectedGroup =
                currentOrgGroups.isNotEmpty ? currentOrgGroups.first.id : null;
          }

          // Find selected role model for module permissions preview
          RoleModel? currentSelectedRole;
          if (selectedRoleCode != null) {
            try {
              currentSelectedRole = assignableRoles.firstWhere(
                (r) =>
                    r.roleKey == selectedRoleCode || r.code == selectedRoleCode,
              );
            } catch (_) {}
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isEdit
                      ? Icons.manage_accounts_rounded
                      : Icons.person_add_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdit
                        ? 'युजर माहिती संपादन (Edit User)'
                        : 'नवीन युजर तयार करा (Create User)',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error Banner
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.redAccent.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dialogError!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 1. पूर्ण नाव (Full Name) - Mandatory
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          label: MandatoryLabel('पूर्ण नाव (Full Name)'),
                          prefixIcon:
                              Icon(Icons.person_outline_rounded, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'पूर्ण नाव प्रविष्ट करणे आवश्यक आहे (Full Name is required).';
                          }
                          if (v.trim().length < 2) {
                            return 'नाव किमान 2 अक्षरांचे असावे.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 2. मोबाईल नंबर (Mobile Number) - Mandatory Indian Mobile Check
                      TextFormField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          label: MandatoryLabel('मोबाईल नंबर (Mobile Number)'),
                          prefixIcon:
                              Icon(Icons.phone_android_rounded, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'मोबाईल नंबर प्रविष्ट करणे आवश्यक आहे.';
                          }
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          final last10 = digits.length >= 10
                              ? digits.substring(digits.length - 10)
                              : digits;
                          if (last10.length != 10 ||
                              !RegExp(r'^[6-9]\d{9}$').hasMatch(last10)) {
                            return 'कृपया वैध 10-अंकी भारतीय मोबाईल नंबर प्रविष्ट करा (6 ते 9 ने सुरू होणारा).';
                          }

                          // Duplicate mobile check on client side
                          final isDuplicate = _users.any((u) {
                            if (isEdit && u.id == existing.id) return false;
                            final uPhone =
                                u.phone.replaceAll(RegExp(r'\D'), '');
                            final uLast10 = uPhone.length >= 10
                                ? uPhone.substring(uPhone.length - 10)
                                : uPhone;
                            return uLast10 == last10;
                          });

                          if (isDuplicate) {
                            return 'हा मोबाईल नंबर आधीच नोंदणीकृत आहे (Duplicate Mobile).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 3. ईमेल (Email Address) - Optional with validation
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ईमेल पत्ता (Email Address - ऐच्छिक)',
                          prefixIcon:
                              Icon(Icons.mail_outline_rounded, size: 20),
                        ),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                            if (!emailRegex.hasMatch(v.trim())) {
                              return 'कृपया वैध ईमेल पत्ता प्रविष्ट करा.';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 4. पत्ता (Address) - Optional
                      TextFormField(
                        controller: addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'पत्ता (Address - ऐच्छिक)',
                          prefixIcon: Icon(Icons.home_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4b. पासवर्ड (Initial Password) - Only for new users
                      if (!isEdit) ...[
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            label: const MandatoryLabel(
                                'सुरुवातीचा पासवर्ड (Initial Password)'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                              ),
                              onPressed: () => setDialogState(
                                  () => obscurePassword = !obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'कृपया पासवर्ड प्रविष्ट करा.';
                            }
                            if (v.trim().length < 6) {
                              return 'पासवर्ड किमान 6 अक्षरांचा असावा.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 5. Organization Dropdown - Dynamic & Role Scoped
                      DropdownButtonFormField<String>(
                        value: _organizations.any((o) => o.id == selectedOrg)
                            ? selectedOrg
                            : (_organizations.isNotEmpty
                                ? _organizations.first.id
                                : null),
                        decoration: const InputDecoration(
                          label: MandatoryLabel('संस्था (Organization)'),
                          prefixIcon: Icon(Icons.business_rounded, size: 20),
                        ),
                        items: _organizations.map((org) {
                          return DropdownMenuItem(
                            value: org.id,
                            child: Text(
                              org.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: auth.currentUser.isSuperAdmin
                            ? (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedOrg = val;
                                    // Reset group selection on Organization change (Cascade behavior)
                                    final newOrgGroups = _groups
                                        .where((g) => g.organizationId == val)
                                        .toList();
                                    selectedGroup = newOrgGroups.isNotEmpty
                                        ? newOrgGroups.first.id
                                        : null;
                                  });
                                }
                              }
                            : null, // Non-super admins cannot switch organization
                        validator: (v) => v == null || v.isEmpty
                            ? 'संस्था निवडणे आवश्यक आहे.'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // 6. Group Dropdown - Cascade filtering based on Organization
                      DropdownButtonFormField<String>(
                        value: selectedGroup,
                        decoration: const InputDecoration(
                          label: MandatoryLabel('गट / मंडळ (Group)'),
                          prefixIcon: Icon(Icons.groups_rounded, size: 20),
                        ),
                        items: currentOrgGroups.isEmpty
                            ? [
                                const DropdownMenuItem(
                                  value: 'grp_001',
                                  child: Text('मुख्य मंडळ गट (Default Group)'),
                                )
                              ]
                            : currentOrgGroups.map((g) {
                                return DropdownMenuItem(
                                  value: g.id,
                                  child: Text('${g.name} (${g.code})'),
                                );
                              }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedGroup = val);
                          }
                        },
                        validator: (v) => v == null || v.isEmpty
                            ? 'गट निवडणे आवश्यक आहे.'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // 7. Role Dropdown - Dynamic from Supabase DB with "Role निवडा" placeholder
                      DropdownButtonFormField<String>(
                        value: selectedRoleCode,
                        hint: const Text('Role निवडा (Select Role)'),
                        decoration: const InputDecoration(
                          label: MandatoryLabel('भूमिका / Role'),
                          prefixIcon: Icon(Icons.security_rounded, size: 20),
                        ),
                        items: assignableRoles.map((r) {
                          return DropdownMenuItem(
                            value: r.roleKey,
                            child: Text('${r.name} (${r.roleKey})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedRoleCode = val);
                        },
                        validator: (v) => v == null || v.isEmpty
                            ? 'कृपया Role निवडा (Role selection is required).'
                            : null,
                      ),

                      // Read-only Permissions Preview upon Role selection
                      if (currentSelectedRole != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.visibility_rounded,
                                      size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${currentSelectedRole.name} परवानग्या (Permissions Preview):',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentSelectedRole.permissions.isEmpty
                                    ? 'या Role साठी डीफॉल्ट दर्शक परवानग्या लागू आहेत.'
                                    : 'उपलब्ध परवानग्या: ${currentSelectedRole.permissions.take(6).join(", ")}${currentSelectedRole.permissions.length > 6 ? " (+${currentSelectedRole.permissions.length - 6} अधिक)" : ""}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // 8. Account Status Dropdown - Active / Inactive
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          label: MandatoryLabel('खाते स्थिती (Account Status)'),
                          prefixIcon: Icon(Icons.toggle_on_rounded, size: 20),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text('सक्रिय (Active)'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Row(
                              children: [
                                Icon(Icons.cancel_rounded,
                                    color: Colors.redAccent, size: 16),
                                SizedBox(width: 8),
                                Text('निष्क्रिय (Inactive)'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStatus = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // 9. Notes - Optional Admin-Only
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'अंतर्गत नोंदी (Admin Notes - ऐच्छिक)',
                          hintText: 'फक्त अधिकृत Admin ला दिसणारी माहिती',
                          prefixIcon: Icon(Icons.notes_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // Reset Button
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        setDialogState(() {
                          if (isEdit) {
                            nameCtrl.text = existing.name;
                            phoneCtrl.text = existing.phone;
                            emailCtrl.text = existing.email;
                            addressCtrl.text = existing.address ?? '';
                            notesCtrl.text = existing.notes ?? '';
                            selectedRoleCode = existing.role.roleKey;
                            selectedStatus = existing.accountStatus;
                          } else {
                            nameCtrl.clear();
                            phoneCtrl.clear();
                            emailCtrl.clear();
                            addressCtrl.clear();
                            notesCtrl.clear();
                            selectedRoleCode = null;
                            selectedStatus = 'active';
                          }
                          dialogError = null;
                        });
                      },
                child: const Text('पूर्ववत करा (Reset)'),
              ),
              // Cancel Button
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('रद्द करा (Cancel)'),
              ),
              // Save / Submit Button with isSaving Guard
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setDialogState(() {
                          isSaving = true;
                          dialogError = null;
                        });

                        final cleanPhone =
                            phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
                        final last10 = cleanPhone.length >= 10
                            ? cleanPhone.substring(cleanPhone.length - 10)
                            : cleanPhone;
                        final isActiveBool = selectedStatus == 'active';

                        Map<String, dynamic> res;
                        if (isEdit) {
                          res = await ApiService.updateUserByAdmin(
                            userId: existing.id,
                            name: nameCtrl.text.trim(),
                            phone: last10,
                            email: emailCtrl.text.trim(),
                            role: selectedRoleCode!,
                            organizationId: selectedOrg,
                            groupIds: [selectedGroup ?? 'grp_001'],
                            isActive: isActiveBool,
                            address: addressCtrl.text.trim(),
                            notes: notesCtrl.text.trim(),
                            accountStatus: selectedStatus,
                            actorId: auth.currentUser.id,
                          );
                        } else {
                          final newPassword = passwordCtrl.text.trim().isNotEmpty
                              ? passwordCtrl.text.trim()
                              : 'Vargani@123';
                          res = await ApiService.createUserByAdmin(
                            name: nameCtrl.text.trim(),
                            phone: last10,
                            email: emailCtrl.text.trim(),
                            role: selectedRoleCode!,
                            organizationId: selectedOrg,
                            groupIds: [selectedGroup ?? 'grp_001'],
                            isActive: isActiveBool,
                            password: newPassword,
                            address: addressCtrl.text.trim(),
                            notes: notesCtrl.text.trim(),
                            accountStatus: selectedStatus,
                            actorId: auth.currentUser.id,
                          );

                          if (res['success'] == true) {
                            final createdUser = (res['data'] is UserModel)
                                ? res['data'] as UserModel
                                : UserModel(
                                    id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                                    name: nameCtrl.text.trim(),
                                    phone: last10,
                                    email: emailCtrl.text.trim(),
                                    organizationId: selectedOrg,
                                    role: UserModel.parseRole(selectedRoleCode!),
                                    isActive: isActiveBool,
                                    accountStatus: selectedStatus,
                                    groupIds: [selectedGroup ?? 'grp_001'],
                                  );

                            await auth.registerAdminCreatedUser(
                              user: createdUser,
                              password: newPassword,
                            );
                          }
                        }

                        if (!mounted) return;

                        if (res['success'] == true) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit
                                    ? 'युजर माहिती यशस्वीरित्या अद्यतनित केली!'
                                    : 'नवीन युजर यशस्वीरित्या तयार केला! (लॉगिन पासवर्ड सेव्ह झाला)',
                              ),
                              backgroundColor: AppColors.statusPaid,
                            ),
                          );
                          _loadData();
                        } else {
                          setDialogState(() {
                            isSaving = false;
                            dialogError =
                                res['message'] ?? 'प्रक्रियेमध्ये अडचण आली.';
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
                    : Text(
                        isEdit ? 'जतन करा (Save)' : 'तयार करा (Create)',
                        style: const TextStyle(color: Colors.white),
                      ),
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
    final filteredUsers = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('युजर व्यवस्थापन (User Management)'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'रिफ्रेश (Refresh)',
          ),
        ],
      ),
      floatingActionButton: auth.canManageUsers
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditUserDialog(),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('नवीन युजर (Add User)'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search & Filter Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'नाव, मोबाईल किंवा ईमेलने शोधा...',
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon:
                                      const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter Chips / Bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Status Filter Dropdown
                            DropdownButton<String>(
                              value: _selectedStatusFilter,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                    value: 'all',
                                    child: Text('सर्व स्थिती (All)')),
                                DropdownMenuItem(
                                    value: 'active',
                                    child: Text('सक्रिय (Active)')),
                                DropdownMenuItem(
                                    value: 'inactive',
                                    child: Text('निष्क्रिय (Inactive)')),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedStatusFilter = val);
                              },
                            ),
                            const SizedBox(width: 8),

                            // Role Filter Dropdown
                            DropdownButton<String>(
                              value: _selectedRoleFilter,
                              underline: const SizedBox(),
                              items: [
                                const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('सर्व भूमिका (All Roles)')),
                                ..._roles.map((r) => DropdownMenuItem(
                                    value: r.roleKey, child: Text(r.name))),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedRoleFilter = val);
                              },
                            ),

                            if (_organizations.length > 1) ...[
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: _selectedOrgFilter,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(
                                      value: 'all',
                                      child: Text('सर्व संस्था (All Orgs)')),
                                  ..._organizations.map((o) => DropdownMenuItem(
                                      value: o.id, child: Text(o.name))),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedOrgFilter = val);
                                },
                              ),
                            ],

                            if (_groups.length > 1) ...[
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: _selectedGroupFilter,
                                underline: const SizedBox(),
                                items: [
                                  const DropdownMenuItem(
                                      value: 'all',
                                      child: Text('सर्व गट (All Groups)')),
                                  ..._groups.map((g) => DropdownMenuItem(
                                      value: g.id, child: Text(g.name))),
                                ],
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedGroupFilter = val);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // User Count Indicator
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'एकूण युजर्स: ${filteredUsers.length}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // User List
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_rounded,
                                  size: 54,
                                  color: Colors.grey.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text('कोणतेही युजर्स सापडले नाहीत.',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final isSuper = user.role == UserRole.superAdmin;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              color:
                                  isDark ? AppColors.darkCardBg : Colors.white,
                              elevation: 0,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showUserDetailsDialog(user),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // User Avatar
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: user.isActive
                                            ? AppColors.primary
                                                .withValues(alpha: 0.15)
                                            : Colors.redAccent
                                                .withValues(alpha: 0.15),
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name
                                                  .substring(0, 1)
                                                  .toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            color: user.isActive
                                                ? AppColors.primary
                                                : Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // User Information
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    user.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isSuper
                                                        ? Colors.amber
                                                            .withValues(
                                                                alpha: 0.15)
                                                        : AppColors.primary
                                                            .withValues(
                                                                alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    user.role.nameString,
                                                    style: TextStyle(
                                                      color: isSuper
                                                          ? Colors.amber[800]
                                                          : AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${user.phone}${user.email.isNotEmpty ? " • ${user.email}" : ""}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  user.isActive
                                                      ? Icons
                                                          .check_circle_rounded
                                                      : Icons.cancel_rounded,
                                                  size: 13,
                                                  color: user.isActive
                                                      ? Colors.green
                                                      : Colors.redAccent,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  user.isActive
                                                      ? 'Active'
                                                      : 'Inactive',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: user.isActive
                                                        ? Colors.green
                                                        : Colors.redAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Action Buttons
                                      if (!isSuper) ...[
                                        IconButton(
                                          onPressed: () =>
                                              _showAddEditUserDialog(user),
                                          icon: const Icon(Icons.edit_rounded,
                                              size: 18,
                                              color: AppColors.primary),
                                          tooltip: 'संपादन (Edit)',
                                        ),
                                        Switch(
                                          value: user.isActive,
                                          activeColor: Colors.green,
                                          onChanged: (val) =>
                                              _confirmAndToggleStatus(
                                                  user, val),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
