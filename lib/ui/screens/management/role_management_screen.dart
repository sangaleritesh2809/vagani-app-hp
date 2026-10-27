import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/rbac_modules.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/organization_model.dart';
import '../../../core/models/role_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/user_role_assignment_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/mandatory_label.dart';
import '../../widgets/module_permission_matrix_widget.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen>
    with SingleTickerProviderStateMixin {
  List<RoleModel> _roles = [];
  List<UserRoleAssignmentModel> _assignments = [];
  List<UserModel> _users = [];
  List<GroupModel> _groups = [];
  List<OrganizationModel> _organizations = [];
  bool _isLoading = true;
  String _searchFilter = '';
  String _selectedFilterTab =
      'All'; // 'All', 'System', 'Custom', 'Active', 'Inactive'

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final roles = await ApiService.fetchRoles();
    final assigns = await ApiService.fetchUserRoleAssignments();
    final users = await ApiService.fetchUsers();
    final groups = await ApiService.fetchGroups();
    final orgs = await SupabaseService.getOrganizations();

    if (mounted) {
      setState(() {
        _roles = roles ?? [];
        _assignments = assigns ?? [];
        _users = users ?? [];
        _groups = groups ?? [];
        _organizations = orgs ?? [];
        _isLoading = false;
      });
    }
  }

  int _getUserCountForRole(RoleModel role) {
    return _assignments
        .where((a) =>
            a.roleId == role.id ||
            a.roleKey == role.roleKey ||
            a.roleKey == role.code)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredRoles = _roles.where((r) {
      // Search filter
      final matchesSearch = _searchFilter.isEmpty ||
          r.name.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          r.code.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchFilter.toLowerCase());

      if (!matchesSearch) return false;

      // Tab filter
      switch (_selectedFilterTab) {
        case 'System':
          return r.isSystemRole;
        case 'Custom':
          return !r.isSystemRole;
        case 'Active':
          return r.isActive;
        case 'Inactive':
          return !r.isActive;
        case 'All':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role & Permission Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_ind_rounded),
            tooltip: 'View User Role Assignments',
            onPressed: _showAssignmentsModal,
          ),
          IconButton(
            icon: const Icon(Icons.history_edu_rounded),
            tooltip: 'Role Change Audit History',
            onPressed: _showAuditHistoryModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadAllData,
          ),
        ],
      ),
      floatingActionButton: auth.canCreateRoles
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditRoleDialog(),
              icon: const Icon(Icons.security_rounded),
              label: const Text('Create Role'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Banner explaining Dynamic RBAC
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security_rounded,
                                color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Dynamic RBAC & Module Control',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create custom roles (e.g. Cash Verifier, Auditor, Event Lead), select exact module actions, and assign them globally, per organization, or per group.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildInfoChip(Icons.shield_outlined,
                                '${_roles.length} Total Roles'),
                            _buildInfoChip(Icons.widgets_outlined,
                                '${RbacModuleRegistry.allModules.length} Modules'),
                            _buildInfoChip(Icons.key_outlined,
                                '${RbacModuleRegistry.totalPermissionsCount} Granular Actions'),
                            _buildInfoChip(Icons.people_outline,
                                '${_assignments.length} Active Assignments'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search and Filter Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search roles by name or code...',
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchFilter = val.trim()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'System',
                        'Custom',
                        'Active',
                        'Inactive'
                      ].map((tab) {
                        final isSel = _selectedFilterTab == tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tab),
                            selected: isSel,
                            onSelected: (val) =>
                                setState(() => _selectedFilterTab = tab),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role Cards List
                  if (filteredRoles.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No roles found matching criteria.',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredRoles
                        .map((role) => _buildRoleCard(role, auth, isDark)),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildRoleCard(RoleModel role, AuthProvider auth, bool isDark) {
    final userCount = _getUserCountForRole(role);
    final isSuper = role.isSuperAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: role.isActive
              ? (role.isSystemRole
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2))
              : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Role Name, Scope Pill, Active Status Switch
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSuper
                        ? Colors.amber.withValues(alpha: 0.15)
                        : (role.isSystemRole
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.purple.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSuper
                        ? Icons.stars_rounded
                        : (role.isSystemRole
                            ? Icons.admin_panel_settings_rounded
                            : Icons.shield_rounded),
                    color: isSuper
                        ? Colors.amber
                        : (role.isSystemRole
                            ? AppColors.primary
                            : Colors.purple),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              role.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: role.isActive
                                  ? AppColors.statusPaid.withValues(alpha: 0.12)
                                  : Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              role.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: role.isActive
                                    ? AppColors.statusPaid
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Code: ${role.code} • Scope: ${role.scopeDescription}',
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (role.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                role.description,
                style: const TextStyle(fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Metadata Row: Permissions count, Users count
            Row(
              children: [
                Icon(Icons.vpn_key_rounded,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  isSuper
                      ? 'Full Wildcard (*)'
                      : '${role.permissions.length} Permissions',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person_rounded,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '$userCount Assigned Users',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),

                // Action Buttons
                TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('View Matrix',
                      style: TextStyle(fontSize: 11.5)),
                  onPressed: () => _showPermissionMatrixModal(role),
                ),
                if (!role.isSuperAdmin && auth.canManageRoles) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 19, color: AppColors.primary),
                    tooltip: 'Edit Role & Permissions',
                    onPressed: () => _showAddEditRoleDialog(role),
                  ),
                  IconButton(
                    icon: Icon(
                      role.isActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      size: 26,
                      color: role.isActive ? AppColors.statusPaid : Colors.grey,
                    ),
                    tooltip:
                        role.isActive ? 'Deactivate Role' : 'Activate Role',
                    onPressed: () => _toggleRoleStatus(role),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 19, color: Colors.redAccent),
                    tooltip: 'Delete Role',
                    onPressed: () => _confirmDeleteRole(role),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE / EDIT ROLE DIALOG WITH FULL PERMISSION MATRIX
  // ---------------------------------------------------------------------------
  void _showAddEditRoleDialog([RoleModel? existing]) {
    final auth = context.read<AuthProvider>();
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String selectedScope = existing?.scopeType ?? 'organization';
    String? selectedOrgId = existing?.organizationId ??
        (_organizations.isNotEmpty ? _organizations.first.id : 'org_001');
    String? selectedGroupId = existing?.groupId;
    bool isActive = existing?.isActive ?? true;

    final Set<String> selectedPermissions =
        Set<String>.from(existing?.permissions ?? []);
    final isSuper = existing?.isSuperAdmin ?? false;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880, maxHeight: 720),
              child: Column(
                children: [
                  // Dialog Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2))),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            isEdit
                                ? Icons.edit_rounded
                                : Icons.add_moderator_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          isEdit
                              ? 'Edit Role: ${existing.name}'
                              : 'Create New Custom Role',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Dialog Body Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (dialogError != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(dialogError!,
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12.5)),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Row 1: Role Name & Role Code
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: nameCtrl,
                                    decoration: const InputDecoration(
                                      label: MandatoryLabel('Role Name'),
                                      hintText:
                                          'e.g. Cash Verifier, Event Lead, Auditor',
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Role name is required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: codeCtrl,
                                    enabled: !isEdit,
                                    decoration: InputDecoration(
                                      label: const MandatoryLabel(
                                          'Unique Role Identifier / Code'),
                                      hintText: 'e.g. CASH_VERIFIER',
                                      helperText: isEdit
                                          ? 'Role code cannot be altered after creation'
                                          : null,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Code is required';
                                      if (v.trim().toUpperCase() ==
                                              'SUPER_ADMIN' ||
                                          v.trim() == 'superAdmin') {
                                        return 'Super Admin privilege cannot be created or self-assigned';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Row 2: Scope Selector & Context Dropdowns
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedScope,
                                    decoration: const InputDecoration(
                                        labelText: 'Role Scope'),
                                    items: [
                                      if (auth.isSuperAdmin)
                                        const DropdownMenuItem(
                                            value: 'system',
                                            child:
                                                Text('System Wide (Global)')),
                                      const DropdownMenuItem(
                                          value: 'organization',
                                          child: Text('Organization Level')),
                                      const DropdownMenuItem(
                                          value: 'group',
                                          child: Text('Group / Ward Specific')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null)
                                        setDialogState(
                                            () => selectedScope = val);
                                    },
                                  ),
                                ),
                                if (selectedScope == 'group') ...[
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedGroupId ??
                                          (_groups.isNotEmpty
                                              ? _groups.first.id
                                              : null),
                                      decoration: const InputDecoration(
                                          labelText: 'Assigned Group'),
                                      items: _groups.map((g) {
                                        return DropdownMenuItem(
                                            value: g.id,
                                            child: Text(g.name,
                                                overflow:
                                                    TextOverflow.ellipsis));
                                      }).toList(),
                                      onChanged: (val) => setDialogState(
                                          () => selectedGroupId = val),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Row 3: Description & Active Status
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: descCtrl,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Description',
                                      hintText:
                                          'Describe responsibilities, jurisdiction, and authorization level',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: SwitchListTile(
                                    dense: true,
                                    title: const Text('Active',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    subtitle: Text(
                                        isActive
                                            ? 'Role enabled'
                                            : 'Deactivated',
                                        style: const TextStyle(fontSize: 11)),
                                    value: isActive,
                                    onChanged: (val) =>
                                        setDialogState(() => isActive = val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Module Permission Matrix
                            const Text(
                              'Module-Wise Permission Matrix (Rows = Modules, Columns = Actions)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Configure exact actions for each module. Users assigned to this role will strictly only be able to perform checked actions.',
                              style:
                                  TextStyle(fontSize: 11.5, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),

                            ModulePermissionMatrixWidget(
                              selectedPermissions: selectedPermissions,
                              isSuperAdminRole: isSuper,
                              onPermissionsChanged: (updated) {
                                setDialogState(() {
                                  selectedPermissions.clear();
                                  selectedPermissions.addAll(updated);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Dialog Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.2))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_rounded, size: 18),
                          label: Text(isEdit ? 'Update Role' : 'Save Role'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: isSaving || isSuper
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setDialogState(() {
                                    isSaving = true;
                                    dialogError = null;
                                  });

                                  final roleModel = RoleModel(
                                    id: existing?.id ??
                                        'rol_${DateTime.now().millisecondsSinceEpoch}',
                                    code: codeCtrl.text.trim().toUpperCase(),
                                    name: nameCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    scopeType: selectedScope,
                                    organizationId: selectedOrgId,
                                    groupId: selectedGroupId,
                                    isSystem: existing?.isSystemRole ?? false,
                                    isSystemRole:
                                        existing?.isSystemRole ?? false,
                                    isActive: isActive,
                                    permissions: selectedPermissions.toList(),
                                    createdBy: auth.currentUser.id,
                                    createdAt:
                                        existing?.createdAt ?? DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );

                                  bool ok = false;
                                  if (isEdit) {
                                    ok = await SupabaseService.updateRole(
                                        roleModel,
                                        actorId: auth.currentUser.id);
                                  } else {
                                    ok = await SupabaseService.insertRole(
                                        roleModel,
                                        actorId: auth.currentUser.id);
                                  }

                                  if (!mounted) return;
                                  if (ok) {
                                    await auth.refreshPermissions();
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isEdit
                                            ? 'Role updated successfully!'
                                            : 'Role created and saved successfully!'),
                                        backgroundColor: AppColors.statusPaid,
                                      ),
                                    );
                                    _loadAllData();
                                  } else {
                                    setDialogState(() {
                                      isSaving = false;
                                      dialogError =
                                          'Failed to save role. Please check connection and permissions.';
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOGGLE ROLE ACTIVE / INACTIVE STATUS
  // ---------------------------------------------------------------------------
  Future<void> _toggleRoleStatus(RoleModel role) async {
    final auth = context.read<AuthProvider>();
    final newStatus = !role.isActive;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus ? 'Activate Role?' : 'Deactivate Role?'),
        content: Text(
          newStatus
              ? 'Users assigned to "${role.name}" will regain access to its granted permissions.'
              : 'Warning: Users assigned to "${role.name}" will immediately lose all permissions granted by this role.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus ? AppColors.statusPaid : Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(newStatus ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.toggleRoleActive(
        roleId: role.id,
        isActive: newStatus,
        actorId: auth.currentUser.id,
      );

      if (!mounted) return;
      if (res['success'] == true) {
        await auth.refreshPermissions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(res['message'] ?? 'Role status updated successfully.'),
            backgroundColor:
                newStatus ? AppColors.statusPaid : Colors.orangeAccent,
          ),
        );
        _loadAllData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to update role status.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SAFE DELETE ROLE WITH IN-USE PROTECTION
  // ---------------------------------------------------------------------------
  Future<void> _confirmDeleteRole(RoleModel role) async {
    final auth = context.read<AuthProvider>();
    final userCount = _getUserCountForRole(role);

    // Rule: Prevent deletion of roles in use
    if (userCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Role Cannot Be Deleted'),
            ],
          ),
          content: Text(
            'The role "${role.name}" cannot be deleted because it is currently assigned to $userCount user(s).\n\nPlease revoke or migrate all assigned users in the User Role Assignments module before deleting this role.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showAssignmentsModal(roleFilter: role.roleKey);
              },
              child: const Text('View Assigned Users'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role?'),
        content: Text(
            'Are you sure you want to permanently delete the custom role "${role.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Role'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.deleteRole(
          roleId: role.id, actorId: auth.currentUser.id);
      if (!mounted) return;
      if (res['success'] == true) {
        await auth.refreshPermissions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Role deleted successfully.'),
              backgroundColor: AppColors.statusPaid),
        );
        _loadAllData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res['message'] ?? 'Failed to delete role.'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PERMISSION MATRIX READ-ONLY MODAL
  // ---------------------------------------------------------------------------
  void _showPermissionMatrixModal(RoleModel role) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 680),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Permission Matrix: ${role.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ModulePermissionMatrixWidget(
                    selectedPermissions: Set.from(role.permissions),
                    isReadOnly: true,
                    isSuperAdminRole: role.isSuperAdmin,
                    onPermissionsChanged: (_) {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // USER ROLE ASSIGNMENTS MODAL & DIALOG
  // ---------------------------------------------------------------------------
  void _showAssignmentsModal({String? roleFilter}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final list = _assignments.where((a) {
            if (roleFilter != null && roleFilter.isNotEmpty) {
              return a.roleKey == roleFilter || a.roleId == roleFilter;
            }
            return true;
          }).toList();

          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        roleFilter != null
                            ? 'Users Assigned to $roleFilter'
                            : 'User Role Assignments (${list.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Assign Role'),
                        onPressed: () {
                          _showAssignRoleDialog();
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text('No user assignments found.',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (ctx, i) {
                            final asgn = list[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                                child: Text(asgn.userName.isNotEmpty
                                    ? asgn.userName[0].toUpperCase()
                                    : 'U'),
                              ),
                              title: Text(asgn.userName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              subtitle: Text(
                                '${asgn.roleName} • Scope: ${asgn.scopeDescription}\nPhone: ${asgn.userPhone}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    color: Colors.redAccent),
                                tooltip: 'Revoke Role Assignment',
                                onPressed: () async {
                                  final ok = await ApiService.revokeUserRole(
                                      assignmentId: asgn.id);
                                  if (ok['success'] == true) {
                                    setModalState(() {
                                      _assignments
                                          .removeWhere((a) => a.id == asgn.id);
                                    });
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Role assignment revoked.')),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAssignRoleDialog() {
    final auth = context.read<AuthProvider>();
    String? selectedUserId = _users.isNotEmpty ? _users.first.id : null;
    String? selectedRoleId = _roles.isNotEmpty ? _roles.first.id : null;
    String? selectedGroupId = _groups.isNotEmpty ? _groups.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Assign Role to User'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedUserId,
                    decoration: const InputDecoration(labelText: 'Select User'),
                    items: _users
                        .map((u) => DropdownMenuItem(
                            value: u.id, child: Text('${u.name} (${u.phone})')))
                        .toList(),
                    onChanged: (val) => setDlgState(() => selectedUserId = val),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedRoleId,
                    decoration: const InputDecoration(labelText: 'Select Role'),
                    items: _roles
                        .map((r) => DropdownMenuItem(
                            value: r.id, child: Text('${r.name} (${r.code})')))
                        .toList(),
                    onChanged: (val) => setDlgState(() => selectedRoleId = val),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedGroupId,
                    decoration: const InputDecoration(
                        labelText: 'Group Scope (Optional)'),
                    items: [
                      const DropdownMenuItem(
                          value: null,
                          child: Text('Global / Organization Wide')),
                      ..._groups.map((g) =>
                          DropdownMenuItem(value: g.id, child: Text(g.name))),
                    ],
                    onChanged: (val) =>
                        setDlgState(() => selectedGroupId = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  if (selectedUserId == null || selectedRoleId == null) return;
                  final res = await ApiService.assignUserRole(
                    userId: selectedUserId!,
                    roleId: selectedRoleId!,
                    groupId: selectedGroupId,
                    assignedBy: auth.currentUser.id,
                  );

                  if (!mounted) return;
                  if (res['success'] == true) {
                    await auth.refreshPermissions();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Role assigned successfully!'),
                          backgroundColor: AppColors.statusPaid),
                    );
                    _loadAllData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(res['message'] ?? 'Failed to assign role.'),
                          backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: const Text('Assign Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ROLE AUDIT HISTORY MODAL
  // ---------------------------------------------------------------------------
  Future<void> _showAuditHistoryModal() async {
    final logs = await SupabaseService.getAuditLogs();
    final roleLogs = (logs ?? [])
        .where((l) =>
            l.entityType == 'Role' ||
            l.entityType == 'UserRole' ||
            l.action.contains('ROLE'))
        .toList();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 550),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu_rounded,
                        color: AppColors.primary),
                    const SizedBox(width: 10),
                    const Text('Role Change Audit History',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: roleLogs.isEmpty
                    ? const Center(
                        child: Text('No role change logs found.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: roleLogs.length,
                        itemBuilder: (ctx, i) {
                          final log = roleLogs[i];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_outlined,
                                  size: 16, color: AppColors.primary),
                            ),
                            title: Text(log.action,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(
                              'Target: ${log.entityId} • By: ${log.performedByName}\n${log.details}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
