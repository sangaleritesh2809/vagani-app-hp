import 'package:flutter/material.dart';

/// Available actions in the dynamic RBAC system
enum RbacAction {
  view,
  create,
  edit,
  delete,
  approve,
  verify,
  export,
  settings,
}

extension RbacActionExt on RbacAction {
  String get key {
    switch (this) {
      case RbacAction.view:
        return 'view';
      case RbacAction.create:
        return 'create';
      case RbacAction.edit:
        return 'edit';
      case RbacAction.delete:
        return 'delete';
      case RbacAction.approve:
        return 'approve';
      case RbacAction.verify:
        return 'verify';
      case RbacAction.export:
        return 'export';
      case RbacAction.settings:
        return 'settings';
    }
  }

  String get displayName {
    switch (this) {
      case RbacAction.view:
        return 'View / Read';
      case RbacAction.create:
        return 'Create';
      case RbacAction.edit:
        return 'Edit / Update';
      case RbacAction.delete:
        return 'Delete';
      case RbacAction.approve:
        return 'Approve / Reject';
      case RbacAction.verify:
        return 'Verify';
      case RbacAction.export:
        return 'Export / Download';
      case RbacAction.settings:
        return 'Manage Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case RbacAction.view:
        return Icons.visibility_outlined;
      case RbacAction.create:
        return Icons.add_circle_outline;
      case RbacAction.edit:
        return Icons.edit_outlined;
      case RbacAction.delete:
        return Icons.delete_outline;
      case RbacAction.approve:
        return Icons.check_circle_outline;
      case RbacAction.verify:
        return Icons.verified_outlined;
      case RbacAction.export:
        return Icons.download_outlined;
      case RbacAction.settings:
        return Icons.settings_outlined;
    }
  }
}

/// Definition for a registered module in Vargani Pro
class ModuleDefinition {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final String category; // 'Core', 'Finance', 'Governance', 'Operations', 'Settings'
  final List<RbacAction> applicableActions;

  const ModuleDefinition({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.applicableActions,
  });

  bool supportsAction(RbacAction action) => applicableActions.contains(action);

  String permissionKey(RbacAction action) => '$key.${action.key}';
}

/// Registry of all 22 required modules for Dynamic RBAC
class RbacModuleRegistry {
  static const List<ModuleDefinition> allModules = [
    // 1. Dashboard
    ModuleDefinition(
      key: 'dashboard',
      name: 'Dashboard',
      description: 'System overview, statistics, and live performance metrics',
      icon: Icons.dashboard_rounded,
      category: 'Core',
      applicableActions: [RbacAction.view, RbacAction.export],
    ),
    // 2. Organization Management
    ModuleDefinition(
      key: 'organizations',
      name: 'Organization Management',
      description: 'Manage mandals, trusts, registration details and branches',
      icon: Icons.apartment_rounded,
      category: 'Governance',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.delete,
        RbacAction.settings,
      ],
    ),
    // 3. Group Management
    ModuleDefinition(
      key: 'groups',
      name: 'Group Management',
      description: 'Wards, areas, and sub-group committees',
      icon: Icons.hub_rounded,
      category: 'Governance',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.delete,
        RbacAction.settings,
      ],
    ),
    // 4. User Management
    ModuleDefinition(
      key: 'users',
      name: 'User Management',
      description: 'Staff directory, account activation, locking and profile edits',
      icon: Icons.people_alt_rounded,
      category: 'Governance',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.delete,
        RbacAction.export,
      ],
    ),
    // 5. Role & Permission Management
    ModuleDefinition(
      key: 'roles',
      name: 'Role & Permission Management',
      description: 'Create custom roles, edit permissions, activate/deactivate roles',
      icon: Icons.shield_rounded,
      category: 'Governance',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.delete,
      ],
    ),
    // 6. Group Members
    ModuleDefinition(
      key: 'group_members',
      name: 'Group Members',
      description: 'Membership rosters and group assignment mapping',
      icon: Icons.groups_rounded,
      category: 'Governance',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.delete,
        RbacAction.export,
      ],
    ),
    // 7. Join Requests
    ModuleDefinition(
      key: 'join_requests',
      name: 'Join Requests',
      description: 'Review and approve/reject citizen and member join applications',
      icon: Icons.group_add_rounded,
      category: 'Operations',
      applicableActions: [
        RbacAction.view,
        RbacAction.approve,
        RbacAction.delete,
      ],
    ),
    // 8. Collection Campaigns
    ModuleDefinition(
      key: 'campaigns',
      name: 'Collection Campaigns',
      description: 'Create and configure Ganeshotsav, Shivjayanti festivals and drives',
      icon: Icons.celebration_rounded,
      category: 'Operations',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.delete,
        RbacAction.settings,
      ],
    ),
    // 9. Contribution Settings
    ModuleDefinition(
      key: 'contribution_settings',
      name: 'Contribution Settings',
      description: 'Per-head rates, fixed rates, and suggested donation amounts',
      icon: Icons.price_change_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.edit,
        RbacAction.settings,
      ],
    ),
    // 10. Collection / Payment Entry
    ModuleDefinition(
      key: 'collections',
      name: 'Collection / Payment Entry',
      description: 'Record household vargani, cash, UPI, and bank transfers',
      icon: Icons.payments_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.export,
      ],
    ),
    // 11. Payment Verification
    ModuleDefinition(
      key: 'payment_verification',
      name: 'Payment Verification',
      description: 'Verify online bank transfers, UPI transactions, and cash deposits',
      icon: Icons.verified_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.verify,
        RbacAction.export,
      ],
    ),
    // 12. Receipt Generation
    ModuleDefinition(
      key: 'receipts',
      name: 'Receipt Generation',
      description: 'Issue official digital receipts and manage cancellations',
      icon: Icons.receipt_long_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.delete, // Cancel receipt
        RbacAction.export,
      ],
    ),
    // 13. Expense Management
    ModuleDefinition(
      key: 'expenses',
      name: 'Expense Management',
      description: 'Record expense vouchers, bills, payee information, and proofs',
      icon: Icons.shopping_bag_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.delete,
        RbacAction.export,
      ],
    ),
    // 14. Expense Approval
    ModuleDefinition(
      key: 'expense_approval',
      name: 'Expense Approval',
      description: 'Audit and approve/reject expense vouchers and fund releases',
      icon: Icons.task_alt_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.approve,
        RbacAction.export,
      ],
    ),
    // 15. Collection Reports
    ModuleDefinition(
      key: 'collection_reports',
      name: 'Collection Reports',
      description: 'Comprehensive collection summaries, daily ledgers, and breakdowns',
      icon: Icons.bar_chart_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.export,
      ],
    ),
    // 16. Expense Reports
    ModuleDefinition(
      key: 'expense_reports',
      name: 'Expense Reports',
      description: 'Category-wise spending analysis, vendor statements, and balance sheets',
      icon: Icons.pie_chart_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.export,
      ],
    ),
    // 17. Pending Dues
    ModuleDefinition(
      key: 'pending_dues',
      name: 'Pending Dues',
      description: 'Track outstanding contributions, partial payments, and follow-ups',
      icon: Icons.pending_actions_rounded,
      category: 'Finance',
      applicableActions: [
        RbacAction.view,
        RbacAction.export,
      ],
    ),
    // 18. Complaints
    ModuleDefinition(
      key: 'complaints',
      name: 'Complaints',
      description: 'Public grievance portal, dispute tracking, and official resolutions',
      icon: Icons.report_problem_rounded,
      category: 'Operations',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.edit,
        RbacAction.approve, // resolve
      ],
    ),
    // 19. Notifications
    ModuleDefinition(
      key: 'notifications',
      name: 'Notifications',
      description: 'Send festival alerts, payment SMS, and WhatsApp receipts',
      icon: Icons.notifications_active_rounded,
      category: 'Operations',
      applicableActions: [
        RbacAction.view,
        RbacAction.create,
        RbacAction.settings,
      ],
    ),
    // 20. Audit Logs
    ModuleDefinition(
      key: 'audit_logs',
      name: 'Audit Logs',
      description: 'Tamper-evident trail of all user actions, security and financial logs',
      icon: Icons.history_edu_rounded,
      category: 'Governance',
      applicableActions: [
        RbacAction.view,
        RbacAction.export,
      ],
    ),
    // 21. Organization Settings
    ModuleDefinition(
      key: 'organization_settings',
      name: 'Organization Settings',
      description: 'Bank QR codes, UPI IDs, address, and letterhead configurations',
      icon: Icons.tune_rounded,
      category: 'Settings',
      applicableActions: [
        RbacAction.view,
        RbacAction.edit,
        RbacAction.settings,
      ],
    ),
    // 22. Group Settings
    ModuleDefinition(
      key: 'group_settings',
      name: 'Group Settings',
      description: 'Local ward rules, collection agent jurisdiction, and thresholds',
      icon: Icons.settings_suggest_rounded,
      category: 'Settings',
      applicableActions: [
        RbacAction.view,
        RbacAction.edit,
        RbacAction.settings,
      ],
    ),
  ];

  static ModuleDefinition? findByKey(String key) {
    try {
      return allModules.firstWhere((m) => m.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Total count of granular permissions across all modules
  static int get totalPermissionsCount {
    int total = 0;
    for (final m in allModules) {
      total += m.applicableActions.length;
    }
    return total;
  }

  /// List of all possible permission keys (e.g. ['dashboard.view', 'collections.create', ...])
  static List<String> get allPermissionKeys {
    final list = <String>[];
    for (final m in allModules) {
      for (final a in m.applicableActions) {
        list.add(m.permissionKey(a));
      }
    }
    return list;
  }
}
