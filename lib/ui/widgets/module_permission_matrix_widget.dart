import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/rbac_modules.dart';

class ModulePermissionMatrixWidget extends StatefulWidget {
  final Set<String> selectedPermissions;
  final ValueChanged<Set<String>> onPermissionsChanged;
  final bool isReadOnly;
  final bool isSuperAdminRole;

  const ModulePermissionMatrixWidget({
    super.key,
    required this.selectedPermissions,
    required this.onPermissionsChanged,
    this.isReadOnly = false,
    this.isSuperAdminRole = false,
  });

  @override
  State<ModulePermissionMatrixWidget> createState() =>
      _ModulePermissionMatrixWidgetState();
}

class _ModulePermissionMatrixWidgetState
    extends State<ModulePermissionMatrixWidget> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Core',
    'Finance',
    'Governance',
    'Operations',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isSuperAdminRole) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Super Admin Privilege Level (*)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The Super Admin role permanently retains wildcard access (*) across all current and future modules. Permissions cannot be modified.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Filter modules based on search and category
    final filteredModules = RbacModuleRegistry.allModules.where((m) {
      final matchesCat =
          _selectedCategory == 'All' || m.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final totalApplicableCount = RbacModuleRegistry.totalPermissionsCount;
    final currentSelectedCount =
        widget.selectedPermissions.where((p) => p != '*').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar: Search, Category Chips, Select All / Clear All
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search modules or permissions...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$currentSelectedCount / $totalApplicableCount Granted',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Categories & Quick Actions Bar
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        selected: isSel,
                        visualDensity: VisualDensity.compact,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (!widget.isReadOnly) ...[
              TextButton.icon(
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Select All', style: TextStyle(fontSize: 12)),
                onPressed: _selectAll,
              ),
              TextButton.icon(
                icon: const Icon(Icons.remove_done_rounded,
                    size: 16, color: Colors.grey),
                label: const Text('Clear All',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                onPressed: _clearAll,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Permission Matrix Table View
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark ? AppColors.darkBackground : Colors.grey.shade100,
                ),
                headingRowHeight: 46,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                columnSpacing: 16,
                horizontalMargin: 12,
                columns: [
                  DataColumn(
                    label: Text(
                      'Module (${RbacModuleRegistry.allModules.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  if (!widget.isReadOnly)
                    const DataColumn(
                      label: Text(
                        'Toggle Row',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ...RbacAction.values.map((action) => DataColumn(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(action.icon,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              action.name.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      )),
                ],
                rows: filteredModules.map((m) {
                  final allModulePerms = m.applicableActions
                      .map((a) => m.permissionKey(a))
                      .toSet();
                  final moduleSelectedCount = allModulePerms
                      .where((p) => _isPermChecked(widget.selectedPermissions, p))
                      .length;
                  final isModuleFullySelected =
                      widget.selectedPermissions.contains('*') ||
                      (moduleSelectedCount == allModulePerms.length &&
                          allModulePerms.isNotEmpty);

                  return DataRow(
                    cells: [
                      // 1. Module Name & Description
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(m.icon,
                                  size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  m.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5),
                                ),
                                Text(
                                  m.key,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 2. Row Toggle Button (Module-level Select All)
                      if (!widget.isReadOnly)
                        DataCell(
                          IconButton(
                            icon: Icon(
                              isModuleFullySelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: isModuleFullySelected
                                  ? AppColors.statusPaid
                                  : Colors.grey,
                            ),
                            tooltip: isModuleFullySelected
                                ? 'Deselect entire module'
                                : 'Select all actions for ${m.name}',
                            onPressed: () =>
                                _toggleModule(m, !isModuleFullySelected),
                          ),
                        ),
                      // 3. Action Checkboxes
                      ...RbacAction.values.map((action) {
                        final isSupported = m.supportsAction(action);
                        if (!isSupported) {
                          return const DataCell(
                            Center(
                              child: Text(
                                '—',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        final permKey = m.permissionKey(action);
                        final isChecked =
                            _isPermChecked(widget.selectedPermissions, permKey);

                        return DataCell(
                          Center(
                            child: Checkbox(
                              value: isChecked,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              activeColor: AppColors.primary,
                              onChanged: widget.isReadOnly
                                  ? null
                                  : (val) {
                                      final updated = Set<String>.from(
                                          widget.selectedPermissions);
                                      if (val == true) {
                                        _addPermWithAliases(updated, permKey);
                                      } else {
                                        _removePermWithAliases(updated, permKey);
                                      }
                                      widget.onPermissionsChanged(updated);
                                    },
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _selectAll() {
    final allKeys = RbacModuleRegistry.allPermissionKeys.toSet();
    widget.onPermissionsChanged(allKeys);
  }

  void _clearAll() {
    widget.onPermissionsChanged(<String>{});
  }

  void _toggleModule(ModuleDefinition module, bool selectAll) {
    final updated = Set<String>.from(widget.selectedPermissions);
    for (final action in module.applicableActions) {
      final key = module.permissionKey(action);
      if (selectAll) {
        _addPermWithAliases(updated, key);
      } else {
        _removePermWithAliases(updated, key);
      }
    }
    widget.onPermissionsChanged(updated);
  }

  bool _isPermChecked(Set<String> perms, String key) {
    if (perms.contains('*') || perms.contains(key)) return true;
    final singular = key
        .replaceAll('collections.', 'collection.')
        .replaceAll('expenses.', 'expense.')
        .replaceAll('receipts.', 'receipt.')
        .replaceAll('complaints.', 'complaint.')
        .replaceAll('campaigns.', 'campaign.')
        .replaceAll('organizations.', 'organization.')
        .replaceAll('groups.', 'group.')
        .replaceAll('users.', 'user.')
        .replaceAll('roles.', 'role.');
    if (perms.contains(singular)) return true;
    final plural = key
        .replaceAll('collection.', 'collections.')
        .replaceAll('expense.', 'expenses.')
        .replaceAll('receipt.', 'receipts.')
        .replaceAll('complaint.', 'complaints.')
        .replaceAll('campaign.', 'campaigns.')
        .replaceAll('organization.', 'organizations.')
        .replaceAll('group.', 'groups.')
        .replaceAll('user.', 'users.')
        .replaceAll('role.', 'roles.');
    if (perms.contains(plural)) return true;
    return false;
  }

  void _addPermWithAliases(Set<String> target, String key) {
    target.add(key);
    final s = key
        .replaceAll('collections.', 'collection.')
        .replaceAll('expenses.', 'expense.')
        .replaceAll('receipts.', 'receipt.')
        .replaceAll('complaints.', 'complaint.')
        .replaceAll('campaigns.', 'campaign.');
    final p = key
        .replaceAll('collection.', 'collections.')
        .replaceAll('expense.', 'expenses.')
        .replaceAll('receipt.', 'receipts.')
        .replaceAll('complaint.', 'complaints.')
        .replaceAll('campaign.', 'campaigns.');
    target.add(s);
    target.add(p);
  }

  void _removePermWithAliases(Set<String> target, String key) {
    target.remove('*');
    target.remove(key);
    final s = key
        .replaceAll('collections.', 'collection.')
        .replaceAll('expenses.', 'expense.')
        .replaceAll('receipts.', 'receipt.')
        .replaceAll('complaints.', 'complaint.')
        .replaceAll('campaigns.', 'campaign.');
    final p = key
        .replaceAll('collection.', 'collections.')
        .replaceAll('expense.', 'expenses.')
        .replaceAll('receipt.', 'receipts.')
        .replaceAll('complaint.', 'complaints.')
        .replaceAll('campaign.', 'campaigns.');
    target.remove(s);
    target.remove(p);
  }
}
