import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/services/mock_data_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel _currentUser = MockDataService.users[1]; // Defaults to Sachin Kadam (Org Admin)
  bool _isAuthenticated = true;

  UserModel get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole get currentRole => _currentUser.role;

  List<UserModel> get availableUsers => MockDataService.users;

  void switchUser(UserModel user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void switchRole(UserRole role) {
    final matchedUser = MockDataService.users.firstWhere(
      (u) => u.role == role,
      orElse: () => _currentUser,
    );
    _currentUser = matchedUser;
    _isAuthenticated = true;
    notifyListeners();
  }

  bool simulateCitizenOtpLogin(String phone, String otp) {
    if (otp == '123456' || otp.isNotEmpty) {
      final citizenUser = MockDataService.users.firstWhere(
        (u) => u.role == UserRole.citizen,
      );
      _currentUser = citizenUser.copyWith(phone: phone);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    // Return to public citizen view
    switchRole(UserRole.citizen);
  }

  // Permission Checks
  bool get canManageCampaigns =>
      _currentUser.role == UserRole.orgAdmin || _currentUser.role == UserRole.superAdmin;

  bool get canCollectVargani =>
      _currentUser.role == UserRole.collector || _currentUser.role == UserRole.orgAdmin;

  bool get canConfirmHandover =>
      _currentUser.role == UserRole.treasurer || _currentUser.role == UserRole.orgAdmin;

  bool get canApproveExpenses =>
      _currentUser.role == UserRole.treasurer || _currentUser.role == UserRole.orgAdmin;

  bool get canEscalateToSuperAdmin =>
      _currentUser.role == UserRole.citizen || _currentUser.role == UserRole.orgAdmin;

  bool get isCitizen => _currentUser.role == UserRole.citizen;
  bool get isSuperAdmin => _currentUser.role == UserRole.superAdmin;
}
