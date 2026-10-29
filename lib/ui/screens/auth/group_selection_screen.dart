import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_model.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vargani_data_provider.dart';
import 'login_screen.dart';

class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({super.key});

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  String? _selectedId;
  bool _isLoading = false;
  String? _errorMessage;

  // Mobile number search
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  UserModel? _searchedUser;
  bool _noUserFound = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      auth.loadAuthorizedGroups().then((_) {
        if (mounted && auth.authorizedGroups.isNotEmpty) {
          setState(() {
            _selectedId =
                auth.selectedGroup?.id ?? auth.authorizedGroups.first.id;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Search Logic ──────────────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchedUser = null;
        _noUserFound = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _noUserFound = false;
      _searchedUser = null;
    });

    final auth = context.read<AuthProvider>();
    final allGroups = auth.authorizedGroups;
    final allUsers = auth.availableUsers;

    // --- Phone number digits typed → find linked user & their groups ---
    if (digits.length >= 4) {
      UserModel? matchedUser;
      // Prefer exact match, then startsWith
      for (final u in allUsers) {
        final cleanU = AuthProvider.cleanPhone(u.phone);
        if (cleanU == digits) {
          matchedUser = u;
          break;
        }
      }
      if (matchedUser == null) {
        for (final u in allUsers) {
          final cleanU = AuthProvider.cleanPhone(u.phone);
          if (cleanU.startsWith(digits)) {
            matchedUser = u;
            break;
          }
        }
      }

      if (matchedUser != null) {
        List<Map<String, dynamic>> userGroups;
        if (matchedUser.role == UserRole.superAdmin ||
            matchedUser.role == UserRole.orgAdmin) {
          userGroups = allGroups.map(_groupToMap).toList();
        } else {
          userGroups = allGroups
              .where((g) => matchedUser!.groupIds.contains(g.id))
              .map(_groupToMap)
              .toList();
          if (userGroups.isEmpty && allGroups.isNotEmpty) {
            userGroups = [_groupToMap(allGroups.first)];
          }
        }
        setState(() {
          _searchedUser = matchedUser;
          _searchResults = userGroups;
          _noUserFound = false;
        });
      } else {
        setState(() {
          _searchedUser = null;
          _searchResults = [];
          _noUserFound = digits.length >= 7;
        });
      }
      return;
    }

    // --- Text search → filter by group name or code ---
    final query = value.trim().toLowerCase();
    final matched = allGroups
        .where((g) {
          return g.name.toLowerCase().contains(query) ||
              g.code.toLowerCase().contains(query) ||
              g.description.toLowerCase().contains(query);
        })
        .map(_groupToMap)
        .toList();

    setState(() {
      _searchResults = matched;
      _searchedUser = null;
      _noUserFound = false;
    });
  }

  Map<String, dynamic> _groupToMap(g) => {
        'id': g.id as String,
        'name': g.name as String,
        'code': g.code as String,
        'description': g.description as String,
      };

  // ── Select Group & Navigate to Dashboard ─────────────────────────────────
  Future<void> _selectGroupAndGo(String groupId, AuthProvider auth) async {
    final targetGroup = auth.authorizedGroups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => auth.authorizedGroups.first,
    );
    setState(() => _isLoading = true);
    final result = await auth.selectGroup(targetGroup);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      context.read<VarganiDataProvider>().initDataFromBackend();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Opening dashboard...'),
          backgroundColor: AppColors.statusPaid,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        AppNavigator.navigateToHome(auth);
      }
    } else {
      setState(
          () => _errorMessage = result['message'] ?? 'Group selection failed.');
    }
  }

  Future<void> _handleConfirmSelection(AuthProvider auth) async {
    if (_selectedId == null) {
      setState(() => _errorMessage = 'Please select a group to proceed.');
      return;
    }
    final targetGroup = auth.authorizedGroups.firstWhere(
      (g) => g.id == _selectedId,
      orElse: () => auth.authorizedGroups.first,
    );
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await auth.selectGroup(targetGroup);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      context.read<VarganiDataProvider>().initDataFromBackend();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ??
              'Group selected successfully! Opening dashboard...'),
          backgroundColor: AppColors.statusPaid,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        AppNavigator.navigateToHome(auth);
      }
    } else {
      setState(
          () => _errorMessage = result['message'] ?? 'Group selection failed.');
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = auth.authorizedGroups;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Select Group',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF111827),
                    const Color(0xFF1F2937),
                    const Color(0xFF0F172A)
                  ]
                : [
                    const Color(0xFFFFF7ED),
                    const Color(0xFFFFFBEB),
                    const Color(0xFFF1F5F9)
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ───────────────────────────────────────────
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.groups_rounded,
                            size: 38, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select Group / Committee',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select Authorized Group / Ward Jurisdiction',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),

                    // ── Current User Banner ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            child: Text(
                              auth.currentUser.name.isNotEmpty
                                  ? auth.currentUser.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.currentUser.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${auth.currentUser.phone} • ${auth.currentUser.email}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              auth.currentRole.nameString,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Mobile Number Search Bar ──────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBg : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isSearching
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          width: _isSearching ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText:
                              'Search groups/organizations by mobile number...',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon:
                                      const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),

                    // ── Search Results ────────────────────────────────────
                    if (_isSearching) ...[
                      const SizedBox(height: 10),

                      // User Found Banner (green)
                      if (_searchedUser != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    Colors.green.withValues(alpha: 0.2),
                                child: Text(
                                  _searchedUser!.name.isNotEmpty
                                      ? _searchedUser!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _searchedUser!.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.green),
                                    ),
                                    Text(
                                      '📱 ${_searchedUser!.phone}  •  ${_searchedUser!.role.nameString}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                    ),
                                    if (_searchedUser!.email.isNotEmpty)
                                      Text(
                                        '✉️ ${_searchedUser!.email}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600]),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.green, size: 20),
                            ],
                          ),
                        ),

                      // User Not Found Banner (orange)
                      if (_noUserFound && _searchedUser == null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.person_search_rounded,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This mobile number is not registered.\nPlease select an available group below.',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Groups linked to searched user
                      if (_searchResults.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardBg : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children:
                                _searchResults.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final result = entry.value;
                              final isLast = idx == _searchResults.length - 1;
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () => _selectGroupAndGo(
                                        result['id'] as String, auth),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppColors.primaryGradient,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                                Icons.groups_rounded,
                                                color: Colors.white,
                                                size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  result['name'] as String,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  result['description']
                                                      as String,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.green
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              result['code'] as String,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: AppColors.primary),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      color: isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],

                    const SizedBox(height: 20),

                    // ── All Authorized Groups (Section Title) ─────────────
                    Row(
                      children: [
                        const Icon(Icons.security_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Available Authorized Groups (${groups.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Groups List ───────────────────────────────────────
                    if (groups.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBg : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.lock_person_rounded,
                                size: 40, color: Colors.orangeAccent),
                            SizedBox(height: 10),
                            Text('No group assigned',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text(
                              'Please contact your organization administrator to gain group access.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final g = groups[index];
                          final isSelected = g.id == _selectedId;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() {
                                _selectedId = g.id;
                                _errorMessage = null;
                              }),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(
                                          alpha: isDark ? 0.2 : 0.08)
                                      : (isDark
                                          ? AppColors.darkCardBg
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  g.name,
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    fontSize: 15,
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  g.code,
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.green),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            g.description,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // ── Confirm Button ────────────────────────────────────
                    ElevatedButton(
                      onPressed: _isLoading || groups.isEmpty
                          ? null
                          : () => _handleConfirmSelection(auth),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Proceed to Dashboard',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),

                    const SizedBox(height: 14),

                    // ── Logout ────────────────────────────────────────────
                    TextButton.icon(
                      onPressed: () {
                        auth.logout();
                        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded,
                          size: 16, color: Colors.redAccent),
                      label: const Text(
                        'Log Out (Switch Account)',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
