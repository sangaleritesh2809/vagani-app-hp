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
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => data.setHouseholdSearch(val),
                  decoration: const InputDecoration(
                    hintText: 'Search by family head, area, or phone...',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Area & Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status filters
                      _buildFilterChip(
                        context,
                        label: 'All',
                        isSelected: true, // or match logic
                        onTap: () => data.setStatusFilter(null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Pending',
                        isSelected: false,
                        color: AppColors.statusPending,
                        onTap: () =>
                            data.setStatusFilter(PaymentStatus.pending),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Partially Paid',
                        isSelected: false,
                        color: AppColors.statusPartiallyPaid,
                        onTap: () =>
                            data.setStatusFilter(PaymentStatus.partiallyPaid),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        label: 'Paid',
                        isSelected: false,
                        color: AppColors.statusPaid,
                        onTap: () => data.setStatusFilter(PaymentStatus.paid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Household List
          Expanded(
            child: data.households.isEmpty
                ? EmptyStateWidget(
                    title: 'No households found',
                    subtitle:
                        'No households match your current search or filter. Try a different query or add a new family.',
                    imageAsset: 'assets/images/not_found.png',
                    actionText: 'Register Household',
                    onAction: () {
                      showDialog(
                        context: context,
                        builder: (_) => const HouseholdFormDialog(),
                      );
                    },
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

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: (color ?? AppColors.primary).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.primary,
          ),
        ),
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
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        household.headOfFamilyName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (household.paymentStatus == PaymentStatus.pending &&
                        auth.currentRole != UserRole.citizen) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => HouseholdFormDialog(
                                householdToEdit: household),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Expected Total',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Received',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Remaining',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
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
              if (auth.currentRole != UserRole.citizen)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (household.paymentStatus == PaymentStatus.pending) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 13),
                        label: const Text('Edit',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              NewCollectionDialog(preselectedHousehold: household),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Collect', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
