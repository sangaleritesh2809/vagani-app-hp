import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/user_model.dart';
import '../core/models/group_model.dart';
import '../core/models/organization_model.dart';
import '../core/models/role_model.dart';
import '../core/models/user_role_assignment_model.dart';
import '../core/services/api_service.dart';
import '../core/services/mock_data_service.dart';
import '../core/services/supabase_service.dart';
import '../core/services/supabase_auth_service.dart';
import '../core/services/email_otp_service.dart';
import '../core/utils/hash_util.dart';
import '../core/navigation/app_navigator.dart';

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  const AuthResult({
    required this.success,
    this.message = '',
    this.user,
  });
}

class AuthProvider extends ChangeNotifier {
  static const String defaultPhone = '9699342811';

  static const String _prefKeyUsers = 'vargani_registered_users_v3';
  static const String _prefKeyHashes = 'vargani_user_password_hashes_v3';
  static const String _prefKeyActiveUser = 'vargani_active_user_session_v3';
  static const String _prefKeySelectedGroup = 'vargani_selected_group_v3';

  List<UserModel> _backendUsers = [];
  final List<UserModel> _customUsers = [];
  final Map<String, String> _passwordHashes = {};

  UserModel? _currentUser;
  GroupModel? _selectedGroup;
  OrganizationModel? _selectedOrganization;
  bool _needsOrganizationSelection = true;
  List<GroupModel> _authorizedGroups = [];
  List<String> _userPermissions = [];
  List<UserRoleAssignmentModel> _activeAssignments = [];
  bool _isAuthenticated = false;
  bool _needsGroupSelection = false;
  bool _isInitialized = false;

  UserModel get currentUser =>
      _currentUser ??
      (_backendUsers.isNotEmpty
          ? _backendUsers.first
          : (MockDataService.users.isNotEmpty
              ? MockDataService.users.first
              : const UserModel(
                  id: 'usr_guest',
                  name: 'Guest User',
                  phone: '',
                  email: '',
                  organizationId: 'org_001',
                  role: UserRole.citizen,
                )));

  GroupModel? get selectedGroup => _selectedGroup;
  OrganizationModel? get selectedOrganization => _selectedOrganization;
  bool get needsOrganizationSelection => _needsOrganizationSelection;
  List<GroupModel> get authorizedGroups => _authorizedGroups;
  List<OrganizationModel> _cachedOrganizations = [];
  List<OrganizationModel> get availableOrganizations => _cachedOrganizations;
  List<String> get permissions => _userPermissions;
  List<UserRoleAssignmentModel> get activeAssignments => _activeAssignments;

  void selectOrganization(OrganizationModel? org) {
    _selectedOrganization = org;
    _needsOrganizationSelection = false;
    notifyListeners();
  }

  void resetOrganizationSelection() {
    _needsOrganizationSelection = true;
    notifyListeners();
  }

  Future<List<OrganizationModel>> loadOrganizations() async {
    try {
      final list = await SupabaseService.getOrganizations();
      final orgs = list ??
          (kDebugMode
              ? MockDataService.organizations
              : <OrganizationModel>[]);
      _cachedOrganizations = orgs;
      if (_selectedOrganization == null && orgs.isNotEmpty) {
        _selectedOrganization = orgs.last;
      }
      notifyListeners();
      return orgs;
    } catch (_) {
      return _cachedOrganizations;
    }
  }

  /// Automatically resolves routing according to organization count:
  /// - 1 Organization -> Directly selects it and proceeds to Dashboard
  /// - Multiple Organizations -> Requires Organization Selection Screen
  Future<void> checkAndResolveOrganizationRouting() async {
    try {
      final list = await SupabaseService.getOrganizations();
      final orgs = list ??
          (kDebugMode
              ? MockDataService.organizations
              : <OrganizationModel>[]);
      _cachedOrganizations = orgs;
      if (orgs.length <= 1) {
        if (orgs.isNotEmpty) {
          _selectedOrganization = orgs.first;
        }
        _needsOrganizationSelection = false;
      } else {
        if (_selectedOrganization == null && orgs.isNotEmpty) {
          _selectedOrganization = orgs.last;
        }
        _needsOrganizationSelection = isSuperAdmin;
      }
    } catch (_) {
      _needsOrganizationSelection = false;
    }
    _needsGroupSelection = false;
    notifyListeners();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get needsGroupSelection => _needsGroupSelection;
  UserRole get currentRole => currentUser.role;
  bool get isInitialized => _isInitialized;

  bool get isSuperAdmin => currentUser.isSuperAdmin;
  bool get isOrgAdmin => currentUser.isOrgAdmin;
  bool get isGroupAdmin => currentUser.isGroupAdmin;
  bool get isCollector => currentUser.isCollector;
  bool get isViewer => currentUser.isViewer;
  bool get isPublicUser => currentUser.isPublicUser;
  bool get isCitizen => currentUser.isCitizen;

  List<UserModel> get availableUsers => [
        ..._backendUsers,
        ..._customUsers,
        if (_backendUsers.isEmpty && kDebugMode) ...MockDataService.users,
      ];

  AuthProvider() {
    _passwordHashes.addAll({
      '9699342811': HashUtil.hashPassword('Ritesh@123'),
      '9822054321': HashUtil.hashPassword('admin@123'),
      '9822011111': HashUtil.hashPassword('admin@123'),
      '9822022222': HashUtil.hashPassword('treasurer@123'),
      '9822033333': HashUtil.hashPassword('collector@123'),
      '9822044444': HashUtil.hashPassword('viewer@123'),
      '7820803178': HashUtil.hashPassword('Rushi@123'),
    });
    initStorage();
  }

  /// Initialize local storage, load live users and restore session
  Future<void> initStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Restore active user session immediately (< 2ms)
      final activeUserRaw = prefs.getString(_prefKeyActiveUser);
      if (activeUserRaw != null && activeUserRaw.isNotEmpty) {
        final decoded = jsonDecode(activeUserRaw);
        if (decoded is Map<String, dynamic>) {
          final restored = UserModel.fromJson(decoded);
          if (restored.isActive) {
            _currentUser = restored;
            _isAuthenticated = true;

            // Restore selected group
            final groupRaw = prefs.getString(_prefKeySelectedGroup);
            if (groupRaw != null && groupRaw.isNotEmpty) {
              final gDecoded = jsonDecode(groupRaw);
              if (gDecoded is Map<String, dynamic>) {
                _selectedGroup = GroupModel.fromJson(gDecoded);
                _needsGroupSelection = false;
              }
            } else {
              _needsGroupSelection = restored.role != UserRole.citizen;
            }

            _userPermissions = List<String>.from(restored.permissions);
          }
        }
      }

      // 2. Load custom registered users
      final usersRaw = prefs.getString(_prefKeyUsers);
      if (usersRaw != null && usersRaw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(usersRaw);
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final u = UserModel.fromJson(item);
            if (!_customUsers.any((existing) => existing.id == u.id)) {
              _customUsers.add(u);
            }
          }
        }
      }

      // 3. Load password hashes
      final hashesRaw = prefs.getString(_prefKeyHashes);
      if (hashesRaw != null && hashesRaw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(hashesRaw);
        decoded.forEach((key, value) {
          _passwordHashes[key] = value.toString();
        });
      }
      // Guarantee primary Super Admin (9699342811) password cannot be modified by cached state
      _passwordHashes['9699342811'] = HashUtil.hashPassword('Ritesh@123');

      // 4. Load groups for restored session
      if (_isAuthenticated && _currentUser != null) {
        await loadAuthorizedGroups();
      }
    } catch (e) {
      debugPrint('Error loading persistent auth storage: $e');
    }

    _isInitialized = true;
    notifyListeners();

    // 5. Background sync for backend users without blocking local session boot
    reloadUsers().ignore();
  }

  Future<void> reloadUsers() async {
    try {
      final backendUsers = await ApiService.fetchUsers();
      if (backendUsers != null && backendUsers.isNotEmpty) {
        _backendUsers = backendUsers;
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson =
          jsonEncode(_customUsers.map((u) => u.toJson()).toList());
      await prefs.setString(_prefKeyUsers, usersJson);

      final hashesJson = jsonEncode(_passwordHashes);
      await prefs.setString(_prefKeyHashes, hashesJson);

      if (_isAuthenticated && _currentUser != null) {
        await prefs.setString(
            _prefKeyActiveUser, jsonEncode(_currentUser!.toJson()));
        if (_selectedGroup != null) {
          await prefs.setString(
              _prefKeySelectedGroup, jsonEncode(_selectedGroup!.toJson()));
        } else {
          await prefs.remove(_prefKeySelectedGroup);
        }
      } else {
        await prefs.remove(_prefKeyActiveUser);
        await prefs.remove(_prefKeySelectedGroup);
      }
    } catch (e) {
      debugPrint('Error writing persistent auth storage: $e');
    }
  }

  static String cleanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  Future<bool> isPhoneRegistered(String phone) async {
    final clean = cleanPhone(phone);
    if (clean.length != 10) return false;

    try {
      final backendExists = await ApiService.checkPhoneExists(clean);
      if (backendExists == true) return true;
    } catch (_) {}

    return availableUsers.any((u) => cleanPhone(u.phone) == clean);
  }

  /// Load groups authorized for the current user
  Future<void> loadAuthorizedGroups() async {
    try {
      final allGroups = await ApiService.fetchGroups(
        organizationId: currentUser.organizationId,
      );

      final groupsList = allGroups ??
          [
            const GroupModel(
              id: 'grp_001',
              organizationId: 'org_001',
              name: 'Shivaji Chowk Mandal Group',
              code: 'GRP-SC-01',
              description:
                  'Main Pandal & Shivaji Chowk collection jurisdiction',
            ),
            const GroupModel(
              id: 'grp_002',
              organizationId: 'org_001',
              name: 'Maruti Mandir Parisar Group',
              code: 'GRP-MM-02',
              description: 'Maruti Mandir and Gaothan inner lanes',
            ),
            const GroupModel(
              id: 'grp_003',
              organizationId: 'org_001',
              name: 'Station Road Committee',
              code: 'GRP-SR-03',
              description: 'Station Road and Market line shopkeepers',
            ),
          ];

      // Super Admin and Org Admin can access all groups in the organization.
      // Regular users access only assigned groups.
      if (currentUser.role == UserRole.superAdmin ||
          currentUser.role == UserRole.orgAdmin) {
        _authorizedGroups = groupsList;
      } else {
        _authorizedGroups = groupsList
            .where((g) => currentUser.groupIds.contains(g.id))
            .toList();
        if (_authorizedGroups.isEmpty && groupsList.isNotEmpty) {
          _authorizedGroups = [groupsList.first];
        }
      }

      if (_selectedGroup != null) {
        _needsGroupSelection = false;
      } else if (currentUser.selectedGroupId != null &&
          _authorizedGroups.any((g) => g.id == currentUser.selectedGroupId)) {
        _selectedGroup = _authorizedGroups
            .firstWhere((g) => g.id == currentUser.selectedGroupId);
        _needsGroupSelection = false;
      } else if (_authorizedGroups.length == 1) {
        _selectedGroup = _authorizedGroups.first;
        _needsGroupSelection = false;
      } else {
        _needsGroupSelection =
            currentUser.role != UserRole.citizen && !currentUser.isSuperAdmin;
      }
    } catch (e) {
      debugPrint('Error loading authorized groups: $e');
    }
    notifyListeners();
  }

  /// Select a group after authentication
  Future<Map<String, dynamic>> selectGroup(GroupModel group) async {
    // 1. Try backend validation first
    final res = await ApiService.selectGroup(
      userId: currentUser.id,
      groupId: group.id,
    );

    if (res['success'] == true) {
      _selectedGroup = group;
      _needsGroupSelection = false;

      if (res['data']?['permissions'] is List) {
        _userPermissions = (res['data']['permissions'] as List)
            .map((e) => e.toString())
            .toList();
      }

      _currentUser = currentUser.copyWith(
        selectedGroupId: group.id,
        selectedGroupName: group.name,
        permissions: _userPermissions,
      );

      await _saveToStorage();
      notifyListeners();
      return {
        'success': true,
        'message': res['data']?['message'] ?? 'Group selected successfully.'
      };
    }

    // 2. Local fallback authorization check if backend is unreachable
    if (res['message'] == 'Offline or connection error') {
      final isAuthorized = currentUser.role == UserRole.superAdmin ||
          currentUser.role == UserRole.orgAdmin ||
          currentUser.groupIds.contains(group.id);

      if (isAuthorized) {
        _selectedGroup = group;
        _needsGroupSelection = false;
        _currentUser = currentUser.copyWith(
          selectedGroupId: group.id,
          selectedGroupName: group.name,
        );
        await _saveToStorage();
        notifyListeners();
        return {'success': true, 'message': 'Group selected successfully.'};
      }
    }

    return {
      'success': false,
      'message':
          res['message'] ?? 'You are not authorized to access this group.',
    };
  }

  /// Switch active group from header / profile
  void switchGroup(GroupModel group) {
    selectGroup(group);
  }

  /// Register user
  Future<AuthResult> registerUser({
    String? name,
    String? firstName,
    String? lastName,
    required String phone,
    required String password,
    UserRole role = UserRole.citizen,
    String? email,
  }) async {
    final clean = cleanPhone(phone);
    final fName = firstName ?? (name != null ? name.split(' ').first : '');
    final lName = lastName ??
        (name != null && name.split(' ').length > 1
            ? name.split(' ').sublist(1).join(' ')
            : 'Patil');
    final fullName = '${fName.trim()} ${lName.trim()}'.trim();

    if (fName.trim().length < 2) {
      return const AuthResult(
        success: false,
        message: 'Please enter first name (minimum 2 characters).',
      );
    }
    if (clean.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return const AuthResult(
        success: false,
        message: 'Please enter a valid 10-digit mobile number.',
      );
    }
    if (password.length < 6) {
      return const AuthResult(
        success: false,
        message: 'Password must be at least 6 characters.',
      );
    }

    // Rule 1: Super Admin role cannot be self-assigned
    if (role == UserRole.superAdmin) {
      return const AuthResult(
        success: false,
        message: 'Super Admin role cannot be self-assigned.',
      );
    }

    final alreadyRegistered = await isPhoneRegistered(clean);
    if (alreadyRegistered) {
      return const AuthResult(
        success: false,
        message: 'This mobile number is already registered. Please log in.',
      );
    }

    final hashedPassword = HashUtil.hashPassword(password);
    final newUser = UserModel(
      id: const Uuid().v4(),
      name: fullName,
      phone: clean,
      email: email?.trim().isNotEmpty == true ? email!.trim() : '',
      organizationId: 'org_001',
      role: role,
      isActive: true,
      groupIds: const ['grp_001'],
    );

    _customUsers.add(newUser);
    _passwordHashes[clean] = hashedPassword;
    _currentUser = newUser;
    _isAuthenticated = true;
    _needsGroupSelection = role != UserRole.citizen;

    await loadAuthorizedGroups();
    await _saveToStorage();

    // Sync to backend API
    try {
      final apiRes = await ApiService.registerUser(
        firstName: fName.trim(),
        lastName: lName.trim(),
        phone: clean,
        passwordHash: hashedPassword,
        role: role.name,
        email: newUser.email,
      );

      if (apiRes['success'] == true && apiRes['data']?['user'] != null) {
        final backendUser = UserModel.fromJson(apiRes['data']['user']);
        _currentUser = backendUser;
      }
    } catch (_) {}

    notifyListeners();
    return AuthResult(
      success: true,
      message: 'Welcome, $fullName! Registration successful.',
      user: _currentUser,
    );
  }

  /// Login with mobile number and password
  /// Register an admin-created user so they can immediately log in
  Future<void> registerAdminCreatedUser({
    required UserModel user,
    required String password,
  }) async {
    final clean = cleanPhone(user.phone);
    final hash = HashUtil.hashPassword(password);
    _customUsers
        .removeWhere((u) => u.id == user.id || cleanPhone(u.phone) == clean);
    _customUsers.add(user);
    if (clean.length == 10) {
      _passwordHashes[clean] = hash;
    }
    if (user.email.trim().isNotEmpty) {
      _passwordHashes[user.email.trim().toLowerCase()] = hash;
    }
    await _saveToStorage();
    notifyListeners();
  }

  /// Update an admin-modified user so local storage and lookup reflect changes immediately
  Future<void> updateAdminModifiedUser(UserModel user) async {
    _customUsers.removeWhere((u) => u.id == user.id);
    _customUsers.add(user);
    if (user.phone.isNotEmpty) {
      final clean = cleanPhone(user.phone);
      if (clean.length == 10 && _passwordHashes[clean] != null) {
        if (user.email.trim().isNotEmpty) {
          _passwordHashes[user.email.trim().toLowerCase()] = _passwordHashes[clean]!;
        }
      }
    }
    await _saveToStorage();
    notifyListeners();
  }

  /// Update current user profile details & avatar
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;
    final clean = phone != null ? cleanPhone(phone) : _currentUser!.phone;
    final updated = _currentUser!.copyWith(
      name: name ?? _currentUser!.name,
      phone: clean,
      email: email ?? _currentUser!.email,
      address: address ?? _currentUser!.address,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
    );
    _currentUser = updated;
    _customUsers.removeWhere((u) => u.id == updated.id);
    _customUsers.add(updated);
    await _saveToStorage();
    notifyListeners();

    try {
      await SupabaseService.updateUser(updated);
      final c = SupabaseService.client;
      if (c != null && SupabaseService.isInitialized) {
        await c.from('profiles').update({
          if (name != null) 'full_name': name,
          if (phone != null) 'phone': clean,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', updated.id);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating user profile in Supabase: $e');
      return true;
    }
  }

  /// Login with mobile number or email and password
  Future<AuthResult> loginWithPassword(String identifier, String password) async {
    final rawInput = identifier.trim();
    final isEmail = rawInput.contains('@');
    final clean = cleanPhone(rawInput);

    if (password.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Please enter password.',
      );
    }

    if (!isEmail && clean.length != 10) {
      return const AuthResult(
        success: false,
        message: 'Please enter a valid 10-digit mobile number or email address.',
      );
    }

    // 1. Primary Super Admin login check (phone 9699342811 or ritesh email)
    if (clean == '9699342811' || rawInput.toLowerCase() == 'ritesh.sangale@vargani.app') {
      final isRiteshMatch = password == 'Ritesh@123' || password == 'vargani@123';
      if (!isRiteshMatch) {
        final storedHash = _passwordHashes['9699342811'];
        if (storedHash == null || !HashUtil.verifyPassword(password, storedHash)) {
          return const AuthResult(
            success: false,
            message: 'Incorrect password! Please try again.',
          );
        }
      }

      final superAdminUser = availableUsers.firstWhere(
        (u) => cleanPhone(u.phone) == '9699342811',
        orElse: () => const UserModel(
          id: 'usr_ritesh',
          name: 'Ritesh Sangale (Super Admin)',
          phone: '9699342811',
          email: 'ritesh.sangale@vargani.app',
          organizationId: 'platform',
          role: UserRole.superAdmin,
          permissions: ['*'],
          isActive: true,
          accountStatus: 'active',
        ),
      );

      _currentUser = superAdminUser;
      _isAuthenticated = true;
      _needsGroupSelection = false;
      await checkAndResolveOrganizationRouting();
      await _saveToStorage();
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'Welcome, ${superAdminUser.name}! Super Admin login successful.',
        user: superAdminUser,
      );
    }

    // 2. Authenticate with backend API if available
    if (!isEmail) {
      try {
        final backendRes = await ApiService.loginUser(
          phone: clean,
          password: password,
          passwordHash: HashUtil.hashPassword(password),
          loginType: 'password',
        );

        if (backendRes['success'] == true && backendRes['data']?['user'] != null) {
          final uData = backendRes['data']['user'];
          final user = UserModel.fromJson(uData);

          if (!user.isActive) {
            return const AuthResult(
              success: false,
              message: 'Your account is inactive. Please contact administrator.',
            );
          }

          _customUsers.removeWhere((u) => cleanPhone(u.phone) == clean);
          _customUsers.add(user);
          _passwordHashes[clean] = HashUtil.hashPassword(password);
          _currentUser = user;
          _isAuthenticated = true;
          _needsGroupSelection = user.role != UserRole.citizen && !user.isSuperAdmin;

          await checkAndResolveOrganizationRouting();
          await loadAuthorizedGroups();
          await _saveToStorage();
          notifyListeners();

          return AuthResult(
            success: true,
            message: 'Welcome, ${user.name}! Login successful.',
            user: user,
          );
        }
      } catch (_) {}
    }

    // 3. Supabase Auth password authentication fallback
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        String? targetEmail = isEmail ? rawInput : null;
        if (targetEmail == null) {
          final lookup = await SupabaseAuthService.lookupEmailByPhone(clean);
          if (lookup['success'] == true && lookup['email'] != null) {
            targetEmail = lookup['email'] as String;
          }
        }

        if (targetEmail != null && targetEmail.isNotEmpty) {
          final authRes = await SupabaseAuthService.signInWithPassword(
            email: targetEmail,
            password: password,
          );
          if (authRes != null && authRes.user != null) {
            final profile =
                await SupabaseAuthService.fetchUserProfile(authRes.user!.id);
            final user = profile ??
                availableUsers.firstWhere(
                  (u) => (isEmail
                      ? u.email.toLowerCase() == rawInput.toLowerCase()
                      : cleanPhone(u.phone) == clean),
                  orElse: () => UserModel(
                    id: authRes.user!.id,
                    name: authRes.user!.userMetadata?['name']?.toString() ??
                        'User',
                    phone: clean,
                    email: targetEmail!,
                    organizationId: 'org_001',
                    role: UserRole.citizen,
                    isActive: true,
                  ),
                );

            if (!user.isActive) {
              return const AuthResult(
                success: false,
                message: 'Your account is inactive. Please contact administrator.',
              );
            }

            _currentUser = user;
            _isAuthenticated = true;
            _needsGroupSelection =
                user.role != UserRole.citizen && !user.isSuperAdmin;
            if (clean.length == 10) {
              _passwordHashes[clean] = HashUtil.hashPassword(password);
            }
            _passwordHashes[targetEmail.toLowerCase()] =
                HashUtil.hashPassword(password);

            await checkAndResolveOrganizationRouting();
            await loadAuthorizedGroups();
            await _saveToStorage();
            notifyListeners();

            return AuthResult(
              success: true,
              message: 'Welcome, ${user.name}! Login successful.',
              user: user,
            );
          }
        }
      } catch (e) {
        debugPrint('Supabase signInWithPassword fallback note: $e');
      }
    }

    // 4. Local / Mock / Admin-created user password verification
    UserModel? matchedUser = availableUsers.where((u) {
      if (isEmail) {
        return u.email.trim().toLowerCase() == rawInput.toLowerCase();
      } else {
        return cleanPhone(u.phone) == clean;
      }
    }).firstOrNull;

    String? dbPasswordHash;

    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final query = SupabaseService.client!.from('users').select();
        final response = isEmail
            ? await query.eq('email', rawInput.toLowerCase()).maybeSingle()
            : await query.eq('phone', clean).maybeSingle();
        if (response != null) {
          matchedUser = UserModel.fromJson(Map<String, dynamic>.from(response));
          dbPasswordHash = response['password_hash'] as String?;
          _customUsers.removeWhere((u) => u.id == matchedUser!.id || cleanPhone(u.phone) == clean);
          _customUsers.add(matchedUser);
        }
      } catch (e) {
        debugPrint('Supabase direct users table lookup error: $e');
      }

      // Check profiles table if still no dbPasswordHash
      if (dbPasswordHash == null || dbPasswordHash.isEmpty) {
        try {
          final pQuery = SupabaseService.client!.from('profiles').select();
          final pRes = isEmail
              ? await pQuery.eq('email', rawInput.toLowerCase()).maybeSingle()
              : await pQuery.eq('phone', clean).maybeSingle();
          if (pRes != null) {
            dbPasswordHash = pRes['password_hash'] as String?;
            if (matchedUser == null) {
              matchedUser = UserModel.fromJson(Map<String, dynamic>.from(pRes));
              _customUsers.add(matchedUser);
            }
          }
        } catch (_) {}
      }
    }

    final lookupKey = isEmail ? rawInput.toLowerCase() : clean;
    final storedHash = _passwordHashes[lookupKey] ??
        (matchedUser != null
            ? (_passwordHashes[cleanPhone(matchedUser.phone)] ?? matchedUser.passwordHash)
            : null) ??
        dbPasswordHash;

    bool isPasswordValid = false;
    if (storedHash != null && storedHash.isNotEmpty) {
      isPasswordValid = HashUtil.verifyPassword(password, storedHash);
      if (isPasswordValid) {
        _passwordHashes[clean] = storedHash;
        if (matchedUser != null && matchedUser.email.isNotEmpty) {
          _passwordHashes[matchedUser.email.toLowerCase()] = storedHash;
        }
      }
    }
    // Check fallback for plaintext if previously saved unhashed
    if (!isPasswordValid && storedHash != null && storedHash == password) {
      isPasswordValid = true;
    }
    // Also allow default initial passwords for created users / mock testing
    if (!isPasswordValid && matchedUser != null) {
      if (password == 'Vargani@123' ||
          password == 'vargani@123' ||
          password == 'admin@123' ||
          password == 'treasurer@123' ||
          password == 'collector@123' ||
          password == 'viewer@123') {
        isPasswordValid = true;
      }
    }

    if (isPasswordValid) {
      final user = matchedUser ??
          UserModel(
            id: const Uuid().v4(),
            name: 'User ($clean)',
            phone: clean,
            email: isEmail ? rawInput : '',
            organizationId: 'org_001',
            role: UserRole.citizen,
            isActive: true,
          );

      if (!user.isActive) {
        return const AuthResult(
          success: false,
          message: 'Your account is inactive. Please contact administrator.',
        );
      }

      _currentUser = user;
      _isAuthenticated = true;
      _needsGroupSelection =
          user.role != UserRole.citizen && !user.isSuperAdmin;
      if (clean.length == 10) {
        _passwordHashes[clean] = HashUtil.hashPassword(password);
      }
      if (user.email.isNotEmpty) {
        _passwordHashes[user.email.toLowerCase()] =
            HashUtil.hashPassword(password);
      }

      await checkAndResolveOrganizationRouting();
      await loadAuthorizedGroups();
      await _saveToStorage();
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'Welcome, ${user.name}! Login successful.',
        user: user,
      );
    }

    if (matchedUser != null) {
      return const AuthResult(
        success: false,
        message: 'Incorrect password! Please try again.',
      );
    }

    return const AuthResult(
      success: false,
      message: 'This mobile number or email is not registered.',
    );
  }

  /// Send real 6-digit OTP for login via Supabase Auth
  /// Supports both Phone (resolving to verified email) and Direct Email.
  Future<Map<String, dynamic>> sendLoginOtp(
      {String? phone, String? email}) async {
    if (phone != null && phone.trim().isNotEmpty) {
      final clean = cleanPhone(phone);
      if (clean.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
        return {
          'success': false,
          'message': 'Please enter a valid 10-digit mobile number.',
        };
      }

      // Check live Supabase
      if (SupabaseService.isInitialized && SupabaseService.client != null) {
        final res = await SupabaseAuthService.sendPhoneOtp(phone: clean);
        return res;
      }

      // Fallback for offline / demo environments
      final matched =
          availableUsers.where((u) => cleanPhone(u.phone) == clean).firstOrNull;
      if (matched == null) {
        return {
          'success': false,
          'message':
              'No account found with this mobile number. Please register first.',
        };
      }
      if (!matched.isActive) {
        return {
          'success': false,
          'message': 'Your account is inactive. Please contact administrator.',
        };
      }

      final masked = SupabaseAuthService.maskEmail(matched.email);
      return {
        'success': true,
        'email': matched.email,
        'maskedEmail': masked,
        'name': matched.name,
        'message': 'OTP sent to $masked.',
      };
    } else if (email != null && email.trim().isNotEmpty) {
      final cleanEmail = email.trim();
      if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(cleanEmail)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address.',
        };
      }

      // Check whether user account exists in availableUsers or Supabase
      UserModel? matched = availableUsers
          .where((u) => u.email.trim().toLowerCase() == cleanEmail.toLowerCase())
          .firstOrNull;

      if (matched == null &&
          SupabaseService.isInitialized &&
          SupabaseService.client != null) {
        try {
          final res = await SupabaseService.client!
              .from('users')
              .select()
              .ilike('email', cleanEmail)
              .maybeSingle();
          if (res != null) {
            matched = UserModel.fromJson(Map<String, dynamic>.from(res));
            _customUsers.removeWhere((u) => u.id == matched!.id);
            _customUsers.add(matched);
          }
        } catch (_) {}
      }

      if (matched == null) {
        return {
          'success': false,
          'message':
              'No registered account found with this email. Please contact administrator.',
        };
      }

      if (!matched.isActive) {
        return {
          'success': false,
          'message': 'Your account is inactive. Please contact administrator.',
        };
      }

      return await SupabaseAuthService.sendEmailOtp(
        email: cleanEmail,
        name: matched.name,
        phone: matched.phone,
        purpose: 'Login Verification',
      );
    }

    return {
      'success': false,
      'message': 'Please enter mobile number or email address.',
    };
  }

  /// Verify 6-digit OTP using Supabase Auth & EmailJS
  Future<AuthResult> verifySupabaseOtp({
    required String email,
    required String otp,
    OtpType type = OtpType.email,
  }) async {
    final cleanEmail = email.trim();
    final cleanOtp = otp.trim();

    if (cleanOtp.length != 6) {
      return const AuthResult(
        success: false,
        message: 'Please enter a valid 6-digit OTP.',
      );
    }

    // 1. Check if an EmailJS OTP was dispatched for this email
    final hadPendingEmailOtp = EmailOtpService.hasPendingOtp(cleanEmail);
    final emailCheck = await EmailOtpService.verifyOtpSecure(
      identifier: cleanEmail,
      enteredOtp: cleanOtp,
    );

    if (emailCheck['success'] == true) {
      UserModel? profile;
      if (SupabaseService.isInitialized && SupabaseService.client != null) {
        try {
          final res = await SupabaseService.client!
              .from('users')
              .select()
              .ilike('email', cleanEmail)
              .maybeSingle();
          if (res != null) {
            profile = UserModel.fromJson(Map<String, dynamic>.from(res));
          }
        } catch (_) {}
      }

      profile ??= availableUsers.firstWhere(
        (u) =>
            u.email.toLowerCase() == cleanEmail.toLowerCase() ||
            cleanPhone(u.phone) == cleanPhone(cleanEmail),
        orElse: () => UserModel(
          id: const Uuid().v4(),
          name: cleanEmail.split('@').first,
          phone: '',
          email: cleanEmail,
          organizationId: 'org_001',
          role: UserRole.citizen,
          isActive: true,
        ),
      );

      if (!profile.isActive) {
        return const AuthResult(
          success: false,
          message: 'Your account is inactive. Please contact administrator.',
        );
      }

      _currentUser = profile;
      _isAuthenticated = true;
      _needsGroupSelection = profile.role != UserRole.citizen;
      await loadAuthorizedGroups();
      await _saveToStorage();
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'OTP verified successfully! Welcome, ${profile.name}.',
        user: profile,
      );
    } else if (hadPendingEmailOtp) {
      // Security: When an EmailJS OTP was requested, strictly reject invalid or expired OTPs
      return AuthResult(
        success: false,
        message: emailCheck['message']?.toString() ??
            'Invalid or expired OTP! Please try again.',
      );
    }

    // 2. Live Supabase Auth verification
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final authRes = await SupabaseAuthService.verifyOtp(
          email: cleanEmail,
          token: cleanOtp,
          type: type,
        );

        final sbUser = authRes.user;
        if (sbUser != null) {
          // Fetch user profile from public.users table
          UserModel? profile =
              await SupabaseAuthService.fetchUserProfile(sbUser.id);

          if (profile == null) {
            // Check metadata from signup
            final meta = sbUser.userMetadata ?? {};
            profile = UserModel(
              id: sbUser.id,
              name: meta['name']?.toString() ??
                  sbUser.email?.split('@').first ??
                  'User',
              phone: meta['phone']?.toString() ?? '',
              email: sbUser.email ?? cleanEmail,
              organizationId: 'org_001',
              role: UserRole.values.firstWhere(
                (r) => r.name == meta['role']?.toString(),
                orElse: () => UserRole.citizen,
              ),
              isActive: true,
              groupIds: const ['grp_001'],
            );
            await SupabaseAuthService.upsertUserProfile(profile);
          }

          if (!profile.isActive) {
            await SupabaseAuthService.signOut();
            return const AuthResult(
              success: false,
              message:
                  'Your account is inactive. Please contact administrator.',
            );
          }

          _currentUser = profile;
          _isAuthenticated = true;
          _needsGroupSelection = false;
          await checkAndResolveOrganizationRouting();
          await loadAuthorizedGroups();
          await _saveToStorage();
          notifyListeners();

          return AuthResult(
            success: true,
            message: 'OTP verified successfully! Welcome, ${profile.name}.',
            user: profile,
          );
        }
      } on AuthException catch (e) {
        debugPrint('Supabase verifyOTP error: ${e.message}');
        String msg = 'Invalid or expired OTP. Please try again.';
        if (e.message.toLowerCase().contains('expired')) {
          msg = 'This OTP has expired. Please request a new OTP.';
        }
        return AuthResult(success: false, message: msg);
      } catch (e) {
        debugPrint('Supabase verifyOTP generic error: $e');
        return AuthResult(
            success: false, message: 'Error during OTP verification: $e');
      }
    }

    return const AuthResult(
      success: false,
      message: 'Invalid or expired OTP. Please try again.',
    );
  }

  /// Convenience method for Phone & OTP login
  Future<AuthResult> loginWithOtp(String phone, String otp) async {
    final clean = cleanPhone(phone);
    final cleanOtp = otp.trim();

    if (clean.length != 10) {
      return const AuthResult(
        success: false,
        message: 'Please enter a valid 10-digit mobile number.',
      );
    }
    if (cleanOtp.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Please enter OTP.',
      );
    }

    // Rule 5: Reject inactive accounts immediately
    final matchedUser =
        availableUsers.where((u) => cleanPhone(u.phone) == clean).firstOrNull;
    if (matchedUser != null && !matchedUser.isActive) {
      return const AuthResult(
        success: false,
        message:
            'Your account is currently inactive. Please contact the administrator.',
      );
    }

    // 0. Verify with EmailOtpService if OTP was sent via email service
    if (matchedUser != null) {
      final emailCheck = await EmailOtpService.verifyOtpSecure(
        identifier: matchedUser.email,
        enteredOtp: cleanOtp,
      );
      if (emailCheck['success'] == true) {
        _currentUser = matchedUser;
        _isAuthenticated = true;
        _needsGroupSelection = false;
        await checkAndResolveOrganizationRouting();
        await loadAuthorizedGroups();
        await _saveToStorage();
        notifyListeners();
        return AuthResult(
          success: true,
          message: 'OTP verified successfully! Welcome, ${matchedUser.name}.',
          user: matchedUser,
        );
      }
    }

    // 1. Try Supabase verification if live client is active
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final lookup = await SupabaseAuthService.lookupEmailByPhone(clean);
        if (lookup['success'] == true && lookup['email'] != null) {
          final res = await verifySupabaseOtp(
            email: lookup['email'] as String,
            otp: cleanOtp,
            type: OtpType.email,
          );
          if (res.success) return res;
        }
      } catch (e) {
        debugPrint('Supabase loginWithOtp error: $e');
      }
    }

    // 2. Try Backend API
    try {
      final backendRes = await ApiService.loginUser(
        phone: clean,
        otp: cleanOtp,
        loginType: 'otp',
      );
      if (backendRes['success'] == true &&
          backendRes['data']?['user'] != null) {
        final uData = backendRes['data']['user'];
        final user = UserModel.fromJson(uData);
        if (!user.isActive) {
          return const AuthResult(
            success: false,
            message: 'Your account is inactive. Please contact administrator.',
          );
        }
        _currentUser = user;
        _isAuthenticated = true;
        _needsGroupSelection = user.role != UserRole.citizen;
        await loadAuthorizedGroups();
        await _saveToStorage();
        notifyListeners();
        return AuthResult(
            success: true,
            message: 'OTP verified successfully! Logged in.',
            user: user);
      }
    } catch (_) {}

    return const AuthResult(
      success: false,
      message: 'Incorrect OTP! Please try again.',
    );
  }

  /// Register user with Supabase Auth
  /// Validates all fields, prevents duplicate phone/email, initiates Supabase Auth OTP verification.
  Future<AuthResult> registerWithSupabase({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    UserRole role = UserRole.citizen,
  }) async {
    final cleanName = name.trim();
    final clean = cleanPhone(phone);
    final cleanEmail = email.trim();

    // 1. Validations
    if (cleanName.length < 2) {
      return const AuthResult(
        success: false,
        message: 'Please enter full name (minimum 2 characters).',
      );
    }
    if (clean.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return const AuthResult(
        success: false,
        message: 'Please enter a valid 10-digit mobile number.',
      );
    }
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(cleanEmail)) {
      return const AuthResult(
        success: false,
        message: 'Please enter a valid email address.',
      );
    }
    if (password.length < 8 || password.length > 17) {
      return const AuthResult(
        success: false,
        message: 'Password must be between 8 and 17 characters.',
      );
    }
    if (password != confirmPassword) {
      return const AuthResult(
        success: false,
        message: 'Passwords do not match. Please try again.',
      );
    }
    if (role == UserRole.superAdmin) {
      return const AuthResult(
        success: false,
        message: 'Super Admin role cannot be self-assigned.',
      );
    }

    // 2. Prevent duplicate accounts
    final phoneExists = await isPhoneRegistered(clean);
    if (phoneExists) {
      return const AuthResult(
        success: false,
        message: 'This mobile number is already registered. Please log in.',
      );
    }

    // 3. Register with Supabase Auth
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final authRes = await SupabaseAuthService.signUpWithEmail(
          email: cleanEmail,
          password: password,
          name: cleanName,
          phone: clean,
          role: role,
        );

        if (authRes.user != null) {
          return AuthResult(
            success: true,
            message: '6-digit verification OTP sent to $cleanEmail.',
          );
        }
      } on AuthException catch (e) {
        debugPrint('Supabase signUp error: ${e.message}');
        if (e.message.toLowerCase().contains('already registered') ||
            e.message.toLowerCase().contains('unique')) {
          return const AuthResult(
            success: false,
            message: 'This email address is already registered. Please log in.',
          );
        }
        return AuthResult(
            success: false, message: 'Registration failed: ${e.message}');
      } catch (e) {
        return AuthResult(success: false, message: 'Registration failed: $e');
      }
    }

    // 4. Fallback local registration if offline / mock
    return registerUser(
      name: cleanName,
      phone: clean,
      password: password,
      role: role,
      email: cleanEmail,
    );
  }

  /// Verify registration OTP and activate user account
  Future<AuthResult> verifyRegistrationOtp({
    required String email,
    required String otp,
    required String name,
    required String phone,
    required String password,
    UserRole role = UserRole.citizen,
  }) async {
    final cleanEmail = email.trim();
    final clean = cleanPhone(phone);
    final cleanOtp = otp.trim();

    if (cleanOtp.length != 6) {
      return const AuthResult(
        success: false,
        message: 'Please enter a valid 6-digit OTP.',
      );
    }
    // 1. Check EmailJS OTP store (delivered directly to inbox)
    final emailCheck =
        EmailOtpService.verifyOtp(identifier: cleanEmail, enteredOtp: cleanOtp);
    if (emailCheck['success'] == true) {
      final newUser = UserModel(
        id: const Uuid().v4(),
        name: name.trim(),
        phone: clean,
        email: cleanEmail,
        organizationId: 'org_001',
        role: role,
        isActive: true,
        groupIds: const ['grp_001'],
      );

      if (SupabaseService.isInitialized && SupabaseService.client != null) {
        await SupabaseAuthService.upsertUserProfile(newUser);
      }

      _customUsers.add(newUser);
      _passwordHashes[clean] = HashUtil.hashPassword(password);
      _currentUser = newUser;
      _isAuthenticated = true;
      _needsGroupSelection = role != UserRole.citizen;

      await loadAuthorizedGroups();
      await _saveToStorage();
      notifyListeners();

      return AuthResult(
        success: true,
        message:
            'Congratulations ${name.trim()}! Your account has been created successfully.',
        user: newUser,
      );
    }

    // 2. Live Supabase Auth signup verification
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final authRes = await SupabaseAuthService.verifyOtp(
          email: cleanEmail,
          token: cleanOtp,
          type: OtpType.signup,
        );

        final sbUser = authRes.user;
        if (sbUser != null) {
          final newUser = UserModel(
            id: sbUser.id,
            name: name.trim(),
            phone: clean,
            email: cleanEmail,
            organizationId: 'org_001',
            role: role,
            isActive: true,
            groupIds: const ['grp_001'],
          );

          await SupabaseAuthService.upsertUserProfile(newUser);

          _customUsers.add(newUser);
          _passwordHashes[clean] = HashUtil.hashPassword(password);
          _currentUser = newUser;
          _isAuthenticated = true;
          _needsGroupSelection = role != UserRole.citizen;

          await loadAuthorizedGroups();
          await _saveToStorage();
          notifyListeners();

          return AuthResult(
            success: true,
            message:
                'Congratulations ${name.trim()}! Your account has been created successfully.',
            user: newUser,
          );
        }
      } on AuthException catch (e) {
        debugPrint('verifyRegistrationOtp error: ${e.message}');
        return AuthResult(
          success: false,
          message: 'Invalid or expired OTP. Please check again: ${e.message}',
        );
      } catch (e) {
        return AuthResult(
          success: false,
          message: 'Verification failed: $e',
        );
      }
    }

    // 2. Offline / local fallback
    return registerUser(
      name: name,
      phone: clean,
      password: password,
      role: role,
      email: cleanEmail,
    );
  }

  /// Resend 6-digit OTP for either login or registration
  Future<Map<String, dynamic>> resendOtp({
    required String email,
    String? phone,
    String? name,
    required bool isRegistration,
  }) async {
    return await SupabaseAuthService.resendOtp(
      email: email,
      phone: phone,
      name: name,
      isRegistration: isRegistration,
    );
  }

  bool resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) {
    final clean = cleanPhone(phone);
    // Security: Permanent Super Admin credentials (9699342811) cannot be changed or reset by anyone
    if (clean == '9699342811') {
      debugPrint(
          'Security warning: Permanent Super Admin (9699342811) credentials cannot be changed.');
      return false;
    }

    final otpCheck =
        EmailOtpService.verifyOtp(identifier: clean, enteredOtp: otp.trim());
    if (otpCheck['success'] == true) {
      if (newPassword.length >= 6) {
        _passwordHashes[clean] = HashUtil.hashPassword(newPassword);
        _saveToStorage().ignore();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void continueAsGuest() {
    final citizenUser = availableUsers.firstWhere(
      (u) => u.role == UserRole.citizen,
      orElse: () => const UserModel(
        id: 'usr_guest_citizen',
        name: 'Guest Citizen',
        phone: '',
        email: 'guest@vargani.app',
        organizationId: 'org_001',
        role: UserRole.citizen,
      ),
    );
    _currentUser = citizenUser;
    _isAuthenticated = true;
    _needsGroupSelection = false;
    notifyListeners();
  }

  Future<AuthResult> simulateCitizenOtpLogin(String phone, String otp) {
    return loginWithOtp(phone, otp);
  }

  void switchUser(UserModel user) {
    _customUsers.removeWhere((u) =>
        u.id == user.id || cleanPhone(u.phone) == cleanPhone(user.phone));
    _customUsers.add(user);
    _currentUser = user;
    _isAuthenticated = true;
    _needsGroupSelection =
        user.role != UserRole.citizen && _selectedGroup == null;
    loadAuthorizedGroups().ignore();
    _saveToStorage().ignore();
    notifyListeners();
  }

  void addUser(UserModel user) {
    _customUsers.removeWhere((u) =>
        u.id == user.id || cleanPhone(u.phone) == cleanPhone(user.phone));
    _customUsers.add(user);
    notifyListeners();
  }

  void switchRole(UserRole role) {
    final matchedUser = availableUsers.firstWhere(
      (u) => u.role == role,
      orElse: () => currentUser,
    );
    _currentUser = matchedUser;
    _isAuthenticated = true;
    _needsGroupSelection = role != UserRole.citizen && _selectedGroup == null;
    loadAuthorizedGroups().ignore();
    _saveToStorage().ignore();
    notifyListeners();
  }

  void logout() {
    SupabaseAuthService.signOut().ignore();
    _isAuthenticated = false;
    _needsGroupSelection = false;
    _needsOrganizationSelection = true;
    _selectedGroup = null;
    _selectedOrganization = null;
    _currentUser = null;
    _saveToStorage().ignore();
    notifyListeners();
    AppNavigator.navigateToLogin();
  }

  // ==========================================
  // DYNAMIC RBAC PERMISSION SYSTEM
  // ==========================================

  /// Refresh user's effective permissions based on active role assignments and context
  Future<void> refreshPermissions() async {
    if (!_isAuthenticated || _currentUser == null) return;
    try {
      final assignments = await ApiService.fetchUserRoleAssignments(
        userId: currentUser.id,
      );
      if (assignments != null && assignments.isNotEmpty) {
        _activeAssignments = assignments;
      }

      final allRoles = await ApiService.fetchRoles();
      final resolvedPerms = <String>{};

      if (isSuperAdmin) {
        resolvedPerms.add('*');
      } else {
        // Add base permissions
        resolvedPerms.addAll(_currentUser!.permissions);

        // Resolve context-aware permissions
        final currentOrgId =
            _selectedOrganization?.id ?? currentUser.organizationId;
        final currentGrpId = _selectedGroup?.id;

        for (final asgn in _activeAssignments) {
          final matchesOrg = asgn.organizationId == null ||
              asgn.organizationId == currentOrgId;
          final matchesGrp =
              asgn.groupId == null || asgn.groupId == currentGrpId;

          if (matchesOrg && matchesGrp) {
            final role = allRoles?.firstWhere(
              (r) =>
                  r.id == asgn.roleId ||
                  r.roleKey == asgn.roleKey ||
                  r.code == asgn.roleKey,
              orElse: () => const RoleModel(id: '', code: '', name: ''),
            );
            if (role != null && role.isActive) {
              resolvedPerms.addAll(role.permissions);
            }
          }
        }
      }

      if (resolvedPerms.isNotEmpty) {
        _userPermissions = resolvedPerms.toList();
        _currentUser = _currentUser!.copyWith(
          permissions: _userPermissions,
          roleAssignments: _activeAssignments,
        );
      }
    } catch (e) {
      debugPrint('Error refreshing permissions: $e');
    }
    notifyListeners();
  }

  /// Context-aware action check: e.g. auth.can('payment_verification', 'verify')
  bool can(String moduleKey, String action,
      {String? groupId, String? organizationId}) {
    if (isSuperAdmin) return true;
    if (currentUser.isInactive || currentUser.isSuspended) return false;
    if (_userPermissions.contains('*')) return true;

    final targetKey = '$moduleKey.$action';
    if (_userPermissions.contains(targetKey)) return true;

    return hasPermission(targetKey,
        groupId: groupId, organizationId: organizationId);
  }

  bool hasPermission(String permCode,
      {String? groupId, String? organizationId}) {
    if (isSuperAdmin) return true;
    if (currentUser.isInactive || currentUser.isSuspended) return false;
    if (_userPermissions.contains('*')) return true;
    if (_userPermissions.contains(permCode)) return true;

    // Normalization between module conventions
    final normalized = permCode
        .replaceAll('collections.', 'collection.')
        .replaceAll('expenses.', 'expense.');
    if (_userPermissions.contains(normalized)) return true;
    final pluralized = permCode
        .replaceAll('collection.', 'collections.')
        .replaceAll('expense.', 'expenses.');
    if (_userPermissions.contains(pluralized)) return true;

    // Default System Role fallbacks
    switch (currentUser.role) {
      case UserRole.superAdmin:
        return true;
      case UserRole.orgAdmin:
        return permCode != 'organizations.manage'; // SuperAdmin only
      case UserRole.groupAdmin:
        return [
          'dashboard.view',
          'groups.view',
          'group_members.view',
          'group_members.create',
          'group_members.edit',
          'join_requests.view',
          'join_requests.approve',
          'campaigns.view',
          'collections.view',
          'collections.create',
          'collections.edit',
          'collections.export',
          'collection.view',
          'collection.create',
          'collection.update',
          'payment_verification.view',
          'payment_verification.verify',
          'receipts.view',
          'receipts.create',
          'receipts.export',
          'receipt.view',
          'receipt.create',
          'expenses.view',
          'expenses.create',
          'expenses.approve',
          'expense.view',
          'expense.create',
          'expense.approve',
          'expense_approval.view',
          'expense_approval.approve',
          'collection_reports.view',
          'collection_reports.export',
          'pending_dues.view',
          'pending_dues.export',
          'complaints.view',
          'complaints.create',
          'complaints.approve',
          'complaint.view',
          'complaint.resolve',
          'group_settings.view',
          'group_settings.edit',
          'households.view',
          'households.create',
          'handovers.view',
          'handovers.confirm',
          'reports.view',
        ].contains(permCode);
      case UserRole.treasurer:
        return [
          'dashboard.view',
          'dashboard.export',
          'collections.view',
          'collections.export',
          'collection.view',
          'payment_verification.view',
          'payment_verification.verify',
          'payment_verification.export',
          'receipts.view',
          'receipts.export',
          'receipt.view',
          'expenses.view',
          'expenses.create',
          'expenses.edit',
          'expenses.approve',
          'expenses.export',
          'expense.view',
          'expense.create',
          'expense.approve',
          'expense_approval.view',
          'expense_approval.approve',
          'expense_approval.export',
          'collection_reports.view',
          'collection_reports.export',
          'expense_reports.view',
          'expense_reports.export',
          'pending_dues.view',
          'pending_dues.export',
          'complaints.view',
          'complaint.view',
          'audit_logs.view',
          'households.view',
          'handovers.view',
          'handovers.confirm',
          'reports.view',
        ].contains(permCode);
      case UserRole.collector:
        return [
          'dashboard.view',
          'collections.view',
          'collections.create',
          'collection.view',
          'collection.create',
          'receipts.view',
          'receipts.create',
          'receipt.view',
          'receipt.create',
          'pending_dues.view',
          'complaints.view',
          'complaints.create',
          'complaint.view',
          'households.view',
          'households.create',
          'handovers.view',
          'handovers.create',
          'reports.view',
        ].contains(permCode);
      case UserRole.viewer:
        return [
          'dashboard.view',
          'collections.view',
          'collection.view',
          'receipts.view',
          'receipt.view',
          'expenses.view',
          'expense.view',
          'collection_reports.view',
          'expense_reports.view',
          'reports.view',
          'households.view',
        ].contains(permCode);
      case UserRole.publicUser:
      case UserRole.citizen:
        return [
          'dashboard.view',
          'receipts.view',
          'receipt.view',
          'complaints.view',
          'complaints.create',
          'complaint.view',
          'reports.view',
          'households.view',
        ].contains(permCode);
      case UserRole.custom:
        return false;
    }
  }

  // Convenient capability getters
  bool get canManageOrganizations => isSuperAdmin;
  bool get canManageRoles =>
      can('roles', 'view') ||
      can('roles', 'edit') ||
      hasPermission('roles.manage');
  bool get canCreateRoles => can('roles', 'create');
  bool get canManageUsers =>
      can('users', 'edit') ||
      can('users', 'create') ||
      hasPermission('users.manage');
  bool get canViewUsers => can('users', 'view') || hasPermission('users.view');
  bool get canManageCampaigns =>
      can('campaigns', 'create') ||
      can('campaigns', 'edit') ||
      hasPermission('campaigns.manage');
  bool get canCollectVargani =>
      can('collections', 'create') || hasPermission('collections.create');
  bool get canVerifyPayments => can('payment_verification', 'verify');
  bool get canConfirmHandover => hasPermission('handovers.confirm');
  bool get canApproveExpenses =>
      can('expense_approval', 'approve') || hasPermission('expenses.approve');
  bool get canExportReports =>
      can('collection_reports', 'export') || can('expense_reports', 'export');
  bool get canEscalateToSuperAdmin =>
      currentUser.role == UserRole.citizen || isSuperAdmin;
}
