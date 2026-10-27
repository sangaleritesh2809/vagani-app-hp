import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/group_model.dart';
import '../../../core/models/organization_model.dart';
import '../../../core/models/join_request_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../main_navigation_shell.dart';
import '../auth/login_screen.dart';

class GroupSearchScreen extends StatefulWidget {
  const GroupSearchScreen({super.key});

  @override
  State<GroupSearchScreen> createState() => _GroupSearchScreenState();
}

class _GroupSearchScreenState extends State<GroupSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<GroupModel> _allGroups = [];
  List<OrganizationModel> _organizations = [];
  List<JoinRequestModel> _myRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    // 1. Fetch groups & organizations
    List<GroupModel>? groups = await SupabaseService.getGroups();
    if (groups == null || groups.isEmpty) {
      groups = await ApiService.fetchGroups();
    }

    List<OrganizationModel>? orgs = await SupabaseService.getOrganizations();
    if (orgs == null || orgs.isEmpty) {
      final singleOrg = await ApiService.fetchOrganization();
      if (singleOrg != null) orgs = [singleOrg];
    }

    // 2. Fetch user's join requests
    List<JoinRequestModel>? requests =
        await SupabaseService.getJoinRequests(userId: auth.currentUser.id);
    requests ??= [];

    if (mounted) {
      setState(() {
        _allGroups = groups ?? [];
        _organizations = orgs ?? [];
        _myRequests = requests ?? [];
        _isLoading = false;
      });
    }
  }

  String _getOrgName(String orgId) {
    final matched = _organizations.where((o) => o.id == orgId).firstOrNull;
    return matched?.name ?? 'General Organization';
  }

  List<GroupModel> get _filteredGroups {
    if (_searchQuery.trim().isEmpty) return _allGroups;
    final q = _searchQuery.toLowerCase();
    return _allGroups.where((g) {
      final orgName = _getOrgName(g.organizationId).toLowerCase();
      return g.name.toLowerCase().contains(q) ||
          g.code.toLowerCase().contains(q) ||
          g.description.toLowerCase().contains(q) ||
          g.location.toLowerCase().contains(q) ||
          orgName.contains(q);
    }).toList();
  }

  void _showJoinRequestDialog(GroupModel group) {
    final auth = context.read<AuthProvider>();
    final msgCtrl = TextEditingController();
    bool isSubmitting = false;

    // Check if already requested
    final existing = _myRequests
        .where((r) => r.groupId == group.id && r.isPending)
        .firstOrNull;
    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your join request is already pending for this group.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.group_add_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Join Group',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('Organization: ${_getOrgName(group.organizationId)}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('Group Code: ${group.code}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                      if (group.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Location: ${group.location}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Message for Admins (Optional):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. I am a resident of this area and want to contribute to the collection drive.',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final ok = await SupabaseService.submitJoinRequest(
                          groupId: group.id,
                          userId: auth.currentUser.id,
                          message: msgCtrl.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Your join request has been sent to the group administrators!'),
                                backgroundColor: AppColors.statusPaid,
                              ),
                            );
                            _loadData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to submit request. Please try again.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send Request'),
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
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.travel_explore_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Find & Join Groups',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(auth.currentUser.name,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.search_rounded, size: 18),
              text: 'Public Groups (${_allGroups.length})',
            ),
            Tab(
              icon: const Icon(Icons.mark_email_unread_rounded, size: 18),
              text: 'My Requests (${_myRequests.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupSearchTab(isDark, auth),
                _buildMyRequestsTab(isDark, auth),
              ],
            ),
    );
  }

  Widget _buildGroupSearchTab(bool isDark, AuthProvider auth) {
    final groups = _filteredGroups;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText:
                    'Search group by name, code, location or organization...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor:
                    isDark ? AppColors.darkBackground : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Informational Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Click "Join" to request membership to a group in your area. Once approved by admins, you will be able to view collections and receipts.',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          // Group List
          Expanded(
            child: groups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No groups available.'
                              : 'No matching groups found.',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final orgName = _getOrgName(group.organizationId);

                      // Check if user is already a member
                      final isMember =
                          auth.currentUser.groupIds.contains(group.id);

                      // Check if has pending request
                      final req = _myRequests
                          .where((r) => r.groupId == group.id)
                          .firstOrNull;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.groups_rounded,
                                        color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          orgName,
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                group.code,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            if (group.location.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              Icon(Icons.location_on_outlined,
                                                  size: 12,
                                                  color: Colors.grey.shade600),
                                              const SizedBox(width: 2),
                                              Text(group.location,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors
                                                          .grey.shade600)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (group.description.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  group.description,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Suggested Contribution:',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey)),
                                      Text(
                                        '₹${group.suggestedAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  if (isMember) ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.statusPaid,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: () async {
                                        await auth.selectGroup(group);
                                        if (context.mounted) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const MainNavigationShell()),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 16),
                                      label: const Text('Open (Member)'),
                                    ),
                                  ] else if (req != null && req.isPending) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.hourglass_top_rounded,
                                              color: Colors.orange, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'Request Pending',
                                            style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: () =>
                                          _showJoinRequestDialog(group),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 16),
                                      label: const Text('Join Group'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
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

  Widget _buildMyRequestsTab(bool isDark, AuthProvider auth) {
    if (_myRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'No pending requests.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Find Groups & Send Request'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final req = _myRequests[index];
          final gName = req.groupName ?? 'Group';
          final statusColor = req.isApproved
              ? AppColors.statusPaid
              : (req.isPending ? Colors.orange : Colors.redAccent);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          gName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          req.requestStatus.toUpperCase(),
                          style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  if (req.organizationName != null) ...[
                    const SizedBox(height: 2),
                    Text('Organization: ${req.organizationName}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  if (req.message.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Message: "${req.message}"',
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${req.createdAt.day}/${req.createdAt.month}/${req.createdAt.year}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (req.isApproved) ...[
                    const Divider(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusPaid,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final matchedGroup = _allGroups
                              .where((g) => g.id == req.groupId)
                              .firstOrNull;
                          if (matchedGroup != null) {
                            await auth.selectGroup(matchedGroup);
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const MainNavigationShell()),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Open Group Dashboard'),
                      ),
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
