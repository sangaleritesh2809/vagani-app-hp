import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/household_model.dart';
import '../../../core/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state_widget.dart';
import 'household_form_dialog.dart';
import '../collections/new_collection_dialog.dart';

class HouseholdListScreen extends StatelessWidget {
  const HouseholdListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<VarganiDataProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              border: Border(
                  bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => data.setHouseholdSearch(val),
                    decoration: InputDecoration(
                      hintText: 'Search family head, area, phone...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: data.householdSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => data.setHouseholdSearch(''),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildFilterButton(context, data, isDark),
              ],
            ),
          ),

          // Household List
          Expanded(
            child: data.households.isEmpty
                ? const EmptyStateWidget(
                    title: 'No households found',
                    subtitle:
                        'No households match your current search or filter. Try a different query or add a new family.',
                    imageAsset: 'assets/images/not_found.png',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.households.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final h = data.households[index];
                      return _buildHouseholdCard(
                        context,
                        household: h,
                        currencyFormat: currencyFormat,
                        auth: auth,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: auth.currentRole != UserRole.citizen
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const HouseholdFormDialog(),
                );
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Family'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    VarganiDataProvider data,
    bool isDark,
  ) {
    final bool hasActiveFilter =
        data.selectedStatusFilter != null || data.selectedAreaFilter != 'All';

    return PopupMenuButton<String>(
      tooltip: 'Filter Households',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? AppColors.darkCardBg : Colors.white,
      onSelected: (value) {
        if (value == 'status_all') {
          data.setStatusFilter(null);
        } else if (value == 'status_pending') {
          data.setStatusFilter(PaymentStatus.pending);
        } else if (value == 'status_partiallyPaid') {
          data.setStatusFilter(PaymentStatus.partiallyPaid);
        } else if (value == 'status_paid') {
          data.setStatusFilter(PaymentStatus.paid);
        } else if (value == 'clear_all') {
          data.setStatusFilter(null);
          data.setAreaFilter('All');
        } else if (value.startsWith('area_')) {
          final area = value.replaceFirst('area_', '');
          data.setAreaFilter(area);
        }
      },
      itemBuilder: (context) {
        return [
          // Header: Status Filter
          const PopupMenuItem<String>(
            enabled: false,
            height: 30,
            child: Text(
              'PAYMENT STATUS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildPopupFilterItem(
            value: 'status_all',
            label: 'All Households',
            isSelected: data.selectedStatusFilter == null,
            icon: Icons.all_inclusive_rounded,
            color: AppColors.primary,
          ),
          _buildPopupFilterItem(
            value: 'status_pending',
            label: 'Pending',
            isSelected: data.selectedStatusFilter == PaymentStatus.pending,
            icon: Icons.pending_actions_rounded,
            color: AppColors.statusPending,
          ),
          _buildPopupFilterItem(
            value: 'status_partiallyPaid',
            label: 'Partially Paid',
            isSelected: data.selectedStatusFilter == PaymentStatus.partiallyPaid,
            icon: Icons.timelapse_rounded,
            color: AppColors.statusPartiallyPaid,
          ),
          _buildPopupFilterItem(
            value: 'status_paid',
            label: 'Paid',
            isSelected: data.selectedStatusFilter == PaymentStatus.paid,
            icon: Icons.check_circle_rounded,
            color: AppColors.statusPaid,
          ),

          // Header: Area Filter
          if (data.availableAreas.length > 1) ...[
            const PopupMenuDivider(height: 10),
            const PopupMenuItem<String>(
              enabled: false,
              height: 30,
              child: Text(
                'AREA / REGION',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...data.availableAreas.map((area) {
              final isSel = data.selectedAreaFilter == area;
              return _buildPopupFilterItem(
                value: 'area_$area',
                label: area == 'All' ? 'All Areas' : area,
                isSelected: isSel,
                icon: area == 'All'
                    ? Icons.select_all_rounded
                    : Icons.location_on_outlined,
                color: Colors.indigo,
              );
            }),
          ],

          if (hasActiveFilter) ...[
            const PopupMenuDivider(height: 10),
            const PopupMenuItem<String>(
              value: 'clear_all',
              height: 34,
              child: Row(
                children: [
                  Icon(Icons.clear_all_rounded, color: Colors.redAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Clear Filters',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ];
      },
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: hasActiveFilter
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasActiveFilter
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
            width: hasActiveFilter ? 1.5 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              color: hasActiveFilter ? AppColors.primary : Colors.grey.shade700,
              size: 20,
            ),
            if (hasActiveFilter)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupFilterItem({
    required String value,
    required String label,
    required bool isSelected,
    required IconData icon,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : null,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_rounded, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildHouseholdCard(
    BuildContext context, {
    required HouseholdModel household,
    required NumberFormat currencyFormat,
    required AuthProvider auth,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  household.headOfFamilyName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge.fromPaymentStatus(household.paymentStatus),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  household.villageArea,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                // Mask phone for public/citizen privacy (SRS 9 & 15)
                auth.currentRole == UserRole.citizen
                    ? '••••••${household.mobileNumber.substring(household.mobileNumber.length - 4)}'
                    : household.mobileNumber,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 20),

          // Numbers Breakdown Grid (SRS 5.3 & Appendix A)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expected Total',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(household.expectedTotalVargani),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${household.familyMemberCount} × ₹${household.perPersonRateSnapshot.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Received',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(household.amountReceived),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.statusPaid,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Remaining',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(household.remainingAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: household.remainingAmount > 0
                            ? AppColors.statusPending
                            : AppColors.statusPaid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (auth.currentRole != UserRole.citizen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (household.paymentStatus == PaymentStatus.pending) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => HouseholdFormDialog(
                              householdToEdit: household),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _confirmDeleteHousehold(context, household),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Tooltip(
                        message: 'Delete Household',
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 15),
                    label: const Text(
                      'Collect',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            NewCollectionDialog(preselectedHousehold: household),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 1,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDeleteHousehold(
      BuildContext context, HouseholdModel household) async {
    final auth = context.read<AuthProvider>();
    final data = context.read<VarganiDataProvider>();

    if (household.amountReceived > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cannot Delete',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Cannot delete "${household.headOfFamilyName}" because collections of ₹${household.amountReceived.toStringAsFixed(0)} have already been recorded.\n\nTo preserve accounting compliance, please cancel or refund receipts first.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete Household?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${household.headOfFamilyName}" (${household.villageArea})? This action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_rounded, size: 16),
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await data.deleteHousehold(
        id: household.id,
        currentUser: auth.currentUser!,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Household "${household.headOfFamilyName}" deleted successfully.'
                  : 'Failed to delete household.',
            ),
            backgroundColor: success ? Colors.redAccent : Colors.orange,
          ),
        );
      }
    }
  }
}
