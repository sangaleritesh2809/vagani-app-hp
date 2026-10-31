import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/organization_model.dart';
import '../models/campaign_model.dart';
import '../models/household_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';
import '../models/cash_handover_model.dart';
import '../models/expense_model.dart';
import '../models/complaint_model.dart';
import '../models/audit_log_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/role_model.dart';
import '../models/user_role_assignment_model.dart';
import 'supabase_service.dart';
import 'mock_data_service.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_config.dart';
import '../utils/hash_util.dart';

class BackendUnavailableException implements Exception {
  final String message;
  const BackendUnavailableException([
    this.message =
        'Unable to connect to server. Please check your internet connection or try again later. (Backend Unreachable)',
  ]);

  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Allow fallback when backend is offline
  static bool get allowMockFallback => true;

  static T _resolveFallback<T>(T mockValue, String entityName) {
    if (allowMockFallback) {
      return mockValue;
    }
    throw BackendUnavailableException(
      'Unable to connect to server ($entityName). Please check your internet connection.',
    );
  }

  static bool? _cachedBackendOnline;
  static DateTime? _lastHealthCheck;

  // 1. Check if FastAPI backend is online (cached for 15s with 400ms timeout)
  static Future<bool> isBackendOnline() async {
    final now = DateTime.now();
    if (_cachedBackendOnline != null && _lastHealthCheck != null) {
      if (now.difference(_lastHealthCheck!) < const Duration(seconds: 15)) {
        return _cachedBackendOnline!;
      }
    }
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(milliseconds: 400));
      _cachedBackendOnline = (response.statusCode == 200);
    } catch (_) {
      _cachedBackendOnline = false;
    }
    _lastHealthCheck = now;
    return _cachedBackendOnline!;
  }

  // 2. Fetch Organization
  static Future<OrganizationModel?> fetchOrganization() async {
    final supaOrgs = await SupabaseService.getOrganizations();
    if (supaOrgs != null && supaOrgs.isNotEmpty) {
      return supaOrgs.first;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.organization, 'Organization');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/organization'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data != null && data is Map<String, dynamic>) {
          return OrganizationModel.fromJson(data);
        }
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.organization, 'Organization');
  }

  // 2b. Fetch Users
  static Future<List<UserModel>?> fetchUsers() async {
    final supaUsers = await SupabaseService.getUsers();
    if (supaUsers != null && supaUsers.isNotEmpty) {
      return supaUsers;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.users, 'Users');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/users'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.users, 'Users');
  }

  // 3. Fetch Campaigns
  static Future<List<CampaignModel>?> fetchCampaigns() async {
    final supaCamps = await SupabaseService.getCampaigns();
    if (supaCamps != null && supaCamps.isNotEmpty) {
      return supaCamps;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.campaigns, 'Campaigns');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/campaigns'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) => CampaignModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.campaigns, 'Campaigns');
  }

  // 4. Update Campaign Rate
  static Future<bool> updateCampaignRate({
    required String campaignId,
    required double newRate,
    required String performedByName,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/campaigns/$campaignId/rate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'new_rate': newRate,
              'performed_by_name': performedByName,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 5. Fetch Households
  static Future<List<HouseholdModel>?> fetchHouseholds(
      String campaignId) async {
    final supaHouseholds = await SupabaseService.getHouseholds(campaignId);
    if (supaHouseholds != null) {
      return supaHouseholds;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(
          MockDataService.getInitialHouseholds(), 'Households');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/households?campaign_id=$campaignId'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map(
                (item) => HouseholdModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(
        MockDataService.getInitialHouseholds(), 'Households');
  }

  // 6. Register Household
  static Future<HouseholdModel?> registerHousehold({
    required String campaignId,
    required String headOfFamilyName,
    required String mobileNumber,
    required String villageArea,
    required int familyMemberCount,
    String? organizationId,
  }) async {
    final c = SupabaseService.client;
    if (c != null) {
      try {
        final Map<String, dynamic> insertData = {
          'campaign_id': campaignId,
          'organization_id':
              organizationId ?? '3609220e-4897-49c9-a2b0-a7e0eb4fc159',
          'head_of_family_name': headOfFamilyName,
          'mobile_number': mobileNumber,
          'village_area': villageArea,
          'family_member_count': familyMemberCount,
          'per_person_rate_snapshot': 100.0,
          'amount_received': 0.0,
        };
        final res =
            await c.from('households').insert(insertData).select().single();
        return HouseholdModel.fromJson(Map<String, dynamic>.from(res));
      } catch (e) {
        // Fallback to HTTP
      }
    }
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/households'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'campaign_id': campaignId,
              'head_of_family_name': headOfFamilyName,
              'mobile_number': mobileNumber,
              'village_area': villageArea,
              'family_member_count': familyMemberCount,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return HouseholdModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // 7. Fetch Collections / Payments
  static Future<List<PaymentModel>?> fetchCollections(String campaignId) async {
    final supaCols = await SupabaseService.getCollections(campaignId);
    if (supaCols != null) {
      return supaCols;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(
          MockDataService.getInitialPayments(), 'Collections');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/collections?campaign_id=$campaignId'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) => PaymentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(
        MockDataService.getInitialPayments(), 'Collections');
  }

  // 8. Record Payment & Issue Receipt
  static Future<ReceiptModel?> recordPayment({
    required String householdId,
    required String campaignId,
    required double amount,
    required String paymentType,
    String? referenceId,
    required String collectedByName,
    required String receivedByName,
    String remarks = '',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/collections'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'household_id': householdId,
              'campaign_id': campaignId,
              'amount': amount,
              'payment_type': paymentType,
              'reference_id': referenceId,
              'collected_by_name': collectedByName,
              'received_by_name': receivedByName,
              'remarks': remarks,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ReceiptModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // 9. Fetch Receipts
  static Future<List<ReceiptModel>?> fetchReceipts(String campaignId) async {
    final supaReceipts = await SupabaseService.getReceipts(campaignId);
    if (supaReceipts != null) {
      return supaReceipts;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.getInitialReceipts(), 'Receipts');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/receipts?campaign_id=$campaignId'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) => ReceiptModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.getInitialReceipts(), 'Receipts');
  }

  // 10. Cancel Receipt
  static Future<bool> cancelReceipt({
    required String receiptId,
    required String reason,
    required String cancelledByName,
  }) async {
    final supaSuccess =
        await SupabaseService.cancelReceipt(receiptId, reason, cancelledByName);
    if (supaSuccess) return true;
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/receipts/cancel'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'receipt_id': receiptId,
              'reason': reason,
              'cancelled_by_name': cancelledByName,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 11. Fetch Handovers
  static Future<List<CashHandoverModel>?> fetchHandovers(
      String campaignId) async {
    if (!await isBackendOnline()) {
      return _resolveFallback(
          MockDataService.getInitialHandovers(), 'Handovers');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/handovers?campaign_id=$campaignId'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) =>
                CashHandoverModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.getInitialHandovers(), 'Handovers');
  }

  // 12. Submit Handover
  static Future<CashHandoverModel?> submitHandover({
    required String campaignId,
    required String handoverFromName,
    required String handoverToName,
    required double amount,
    String remarks = '',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/handovers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'campaign_id': campaignId,
              'handover_from_name': handoverFromName,
              'handover_to_name': handoverToName,
              'amount': amount,
              'remarks': remarks,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return CashHandoverModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // 13. Process Handover (Confirm or Reject)
  static Future<bool> processHandover({
    required String handoverId,
    required bool approve,
    required String confirmedByName,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/handovers/process'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'handover_id': handoverId,
              'approve': approve,
              'confirmed_by_name': confirmedByName,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 14. Fetch Expenses
  static Future<List<ExpenseModel>?> fetchExpenses(String campaignId) async {
    final supaExpenses = await SupabaseService.getExpenses(campaignId);
    if (supaExpenses != null) {
      return supaExpenses;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.getInitialExpenses(), 'Expenses');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/expenses?campaign_id=$campaignId'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.getInitialExpenses(), 'Expenses');
  }

  // 15. Add Expense
  static Future<ExpenseModel?> addExpense({
    required String campaignId,
    required String category,
    required String title,
    required String description,
    required double amount,
    required String vendorPayee,
    required String paymentMode,
    required String billNumber,
    required bool hasProof,
    required String enteredByName,
    bool isPublicVisible = true,
    String? organizationId,
  }) async {
    final c = SupabaseService.client;
    if (c != null) {
      try {
        final Map<String, dynamic> insertData = {
          'campaign_id': campaignId,
          'organization_id':
              organizationId ?? '3609220e-4897-49c9-a2b0-a7e0eb4fc159',
          'category': category,
          'title': title,
          'description': description,
          'amount': amount,
          'vendor_payee': vendorPayee,
          'payment_mode': paymentMode,
          'bill_number': billNumber,
          'has_proof': hasProof,
          'entered_by_name': enteredByName,
          'is_public_visible': isPublicVisible,
          'approval_status': 'approved',
          'payment_status': 'paid',
        };
        final res =
            await c.from('expenses').insert(insertData).select().single();
        return ExpenseModel.fromJson(Map<String, dynamic>.from(res));
      } catch (e) {
        // Fallback to HTTP
      }
    }
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/expenses'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'campaign_id': campaignId,
              'category': category,
              'title': title,
              'description': description,
              'amount': amount,
              'vendor_payee': vendorPayee,
              'payment_mode': paymentMode,
              'bill_number': billNumber,
              'has_proof': hasProof,
              'entered_by_name': enteredByName,
              'is_public_visible': isPublicVisible,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ExpenseModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // 16. Approve / Reject Expense
  static Future<bool> approveExpense({
    required String expenseId,
    required String status,
    required String performedByName,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/expenses/approve'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'expense_id': expenseId,
              'status': status,
              'performed_by_name': performedByName,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 17. Fetch Complaints
  static Future<List<ComplaintModel>?> fetchComplaints(
      String campaignId) async {
    final supaComplaints = await SupabaseService.getComplaints(campaignId);
    if (supaComplaints != null) {
      return supaComplaints;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(
          MockDataService.getInitialComplaints(), 'Complaints');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/complaints?campaign_id=$campaignId'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map(
                (item) => ComplaintModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(
        MockDataService.getInitialComplaints(), 'Complaints');
  }

  // 18. Submit Complaint
  static Future<ComplaintModel?> submitComplaint({
    required String campaignId,
    required String type,
    required String title,
    required String description,
    required String submittedByName,
    required String submittedByPhone,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/complaints'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'campaign_id': campaignId,
              'type': type,
              'title': title,
              'description': description,
              'submitted_by_name': submittedByName,
              'submitted_by_phone': submittedByPhone,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ComplaintModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // 19. Respond to Complaint
  static Future<bool> respondComplaint({
    required String complaintId,
    required String response,
    required String status,
    required String performedByName,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/complaints/respond'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'complaint_id': complaintId,
              'response': response,
              'status': status,
              'performed_by_name': performedByName,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 20. Fetch Audit Logs
  static Future<List<AuditLogModel>?> fetchAuditLogs() async {
    final supaLogs = await SupabaseService.getAuditLogs();
    if (supaLogs != null && supaLogs.isNotEmpty) {
      return supaLogs;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(
          MockDataService.getInitialAuditLogs(), 'Audit Logs');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/audit-logs'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) => AuditLogModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(
        MockDataService.getInitialAuditLogs(), 'Audit Logs');
  }

  // 21. Fetch Financial Transparency Summary
  static Future<Map<String, dynamic>?> fetchFinancialSummary(
      String campaignId) async {
    try {
      final res = await http.get(
          Uri.parse('$baseUrl/transparency/summary?campaign_id=$campaignId'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  // 22. Check if phone number is already registered
  static Future<bool?> checkPhoneExists(String phone) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/auth/check-phone?phone=$phone'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['exists'] == true;
      }
    } catch (_) {}
    return null;
  }

  // 23. Register user on backend
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String phone,
    String? password,
    String? passwordHash,
    String role = 'citizen',
    String? email,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'first_name': firstName,
              'last_name': lastName,
              'phone': phone,
              'password': password,
              'password_hash': passwordHash,
              'role': role,
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        final detail =
            data['detail'] ?? 'Registration failed. Please try again.';
        return {'success': false, 'message': detail.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'offline'};
    }
  }

  // 24. Login user on backend
  static Future<Map<String, dynamic>> loginUser({
    required String phone,
    String? password,
    String? passwordHash,
    String? otp,
    String loginType = 'password',
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phone,
              'password': password,
              'password_hash': passwordHash,
              'otp': otp,
              'login_type': loginType,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        final detail = data['detail'] ?? 'Login failed. Please try again.';
        return {'success': false, 'message': detail.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': 'offline'};
    }
  }

  // 25. Fetch all organizations (Super Admin & multi-tenancy)
  static Future<List<OrganizationModel>?> fetchOrganizations() async {
    final supaOrgs = await SupabaseService.getOrganizations();
    if (supaOrgs != null && supaOrgs.isNotEmpty) {
      return supaOrgs;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.organizations, 'Organizations');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/organizations'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) =>
                OrganizationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.organizations, 'Organizations');
  }

  // 26. Create Organization (Super Admin only)
  static Future<Map<String, dynamic>> createOrganization({
    required String name,
    required String contactPerson,
    required String phone,
    required String address,
    String? registrationNumber,
    String? village,
    String? taluka,
    String? district,
    String? state,
    String? actorId,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/organizations${actorId != null ? '?actor_id=$actorId' : ''}');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'contact_person': contactPerson,
              'phone': phone,
              'address': address,
              'registration_number': registrationNumber,
              'village': village,
              'taluka': taluka,
              'district': district,
              'state': state,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': OrganizationModel.fromJson(data)};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to create organization.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // 27. Update Organization
  static Future<Map<String, dynamic>> updateOrganization({
    required String orgId,
    String? name,
    String? contactPerson,
    String? phone,
    String? address,
    String? status,
    String? actorId,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/organizations/$orgId${actorId != null ? '?actor_id=$actorId' : ''}');
      final res = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (name != null) 'name': name,
              if (contactPerson != null) 'contact_person': contactPerson,
              if (phone != null) 'phone': phone,
              if (address != null) 'address': address,
              if (status != null) 'status': status,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': OrganizationModel.fromJson(data)};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to update organization.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // 28. Fetch Groups
  static Future<List<GroupModel>?> fetchGroups({String? organizationId}) async {
    final supaGrps =
        await SupabaseService.getGroups(organizationId: organizationId);
    if (supaGrps != null && supaGrps.isNotEmpty) {
      return supaGrps;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.groups, 'Groups');
    }
    try {
      final url = organizationId != null
          ? '$baseUrl/groups?organization_id=$organizationId'
          : '$baseUrl/groups';
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) => GroupModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.groups, 'Groups');
  }

  // 29. Create Group
  static Future<Map<String, dynamic>> createGroup({
    required String organizationId,
    required String name,
    String? code,
    String? description,
    String? actorId,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/groups${actorId != null ? '?actor_id=$actorId' : ''}');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'organization_id': organizationId,
              'name': name,
              'code': code,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': GroupModel.fromJson(data)};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to create group.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // 30. Select Group (Auth Flow Validation)
  static Future<Map<String, dynamic>> selectGroup({
    required String userId,
    required String groupId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/select-group'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'group_id': groupId,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Access denied to this group.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Offline or connection error'};
    }
  }

  // 31. Fetch Roles
  static Future<List<RoleModel>?> fetchRoles({String? organizationId}) async {
    final supaRoles =
        await SupabaseService.getRoles(organizationId: organizationId);
    if (supaRoles != null && supaRoles.isNotEmpty) {
      return supaRoles;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.roles, 'Roles');
    }
    try {
      final url = organizationId != null
          ? '$baseUrl/roles?organization_id=$organizationId'
          : '$baseUrl/roles';
      final res =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) => RoleModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.roles, 'Roles');
  }

  // 32. Create Role
  static Future<Map<String, dynamic>> createRole({
    required String code,
    required String name,
    required List<String> permissions,
    String? organizationId,
    String? description,
    String? actorId,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/roles${actorId != null ? '?actor_id=$actorId' : ''}');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'name': name,
              'permissions': permissions,
              'organization_id': organizationId,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': RoleModel.fromJson(data)};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to create role.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // 33. Update Role & Permissions
  static Future<Map<String, dynamic>> updateRole({
    required String roleId,
    String? name,
    List<String>? permissions,
    String? description,
    String? actorId,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/roles/$roleId${actorId != null ? '?actor_id=$actorId' : ''}');
      final res = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (name != null) 'name': name,
              if (permissions != null) 'permissions': permissions,
              if (description != null) 'description': description,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'data': RoleModel.fromJson(data)};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Failed to update role.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // 33b. Toggle Role Active Status
  static Future<Map<String, dynamic>> toggleRoleActive({
    required String roleId,
    required bool isActive,
    String? actorId,
  }) async {
    final supaSuccess = await SupabaseService.toggleRoleActive(roleId, isActive,
        actorId: actorId);
    if (supaSuccess) {
      return {
        'success': true,
        'message':
            'Role status updated to ${isActive ? 'Active' : 'Inactive'}.',
      };
    }
    return {'success': false, 'message': 'Failed to update role status.'};
  }

  // 33c. Delete Role
  static Future<Map<String, dynamic>> deleteRole({
    required String roleId,
    String? actorId,
  }) async {
    final supaSuccess =
        await SupabaseService.deleteRole(roleId, actorId: actorId);
    if (supaSuccess) {
      return {'success': true, 'message': 'Role deleted successfully.'};
    }
    return {
      'success': false,
      'message':
          'Cannot delete role because it is in use by assigned users or is a protected system role.',
    };
  }

  // 33d. Fetch User Role Assignments
  static Future<List<UserRoleAssignmentModel>?> fetchUserRoleAssignments({
    String? organizationId,
    String? groupId,
    String? userId,
  }) async {
    return await SupabaseService.getAllUserRoleAssignments(
      organizationId: organizationId,
      groupId: groupId,
      userId: userId,
    );
  }

  // 33e. Assign Role to User
  static Future<Map<String, dynamic>> assignUserRole({
    required String userId,
    required String roleId,
    String? organizationId,
    String? groupId,
    String? assignedBy,
  }) async {
    final success = await SupabaseService.assignUserRole(
      userId: userId,
      roleId: roleId,
      organizationId: organizationId,
      groupId: groupId,
      assignedBy: assignedBy,
    );
    if (success) {
      return {
        'success': true,
        'message': 'Role assigned to user successfully.'
      };
    }
    return {'success': false, 'message': 'Failed to assign role to user.'};
  }

  // 33f. Revoke Role from User
  static Future<Map<String, dynamic>> revokeUserRole({
    required String assignmentId,
    String? actorId,
  }) async {
    final success =
        await SupabaseService.revokeUserRole(assignmentId, actorId: actorId);
    if (success) {
      return {'success': true, 'message': 'Role revoked successfully.'};
    }
    return {'success': false, 'message': 'Failed to revoke role.'};
  }

  // 34. Fetch Permissions
  static Future<List<PermissionModel>?> fetchPermissions() async {
    final supaPerms = await SupabaseService.getPermissions();
    if (supaPerms != null && supaPerms.isNotEmpty) {
      return supaPerms;
    }
    if (!await isBackendOnline()) {
      return _resolveFallback(MockDataService.permissions, 'Permissions');
    }
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/permissions'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list
            .map((item) =>
                PermissionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return _resolveFallback(MockDataService.permissions, 'Permissions');
  }

  // 35. Create User by Admin
  // 35. Create User by Admin
  static Future<Map<String, dynamic>> createUserByAdmin({
    String? firstName,
    String? lastName,
    String? name,
    required String phone,
    required String role,
    required String organizationId,
    List<String>? groupIds,
    bool isActive = true,
    String? email,
    String? password,
    String? address,
    String? notes,
    String? accountStatus,
    String? actorId,
  }) async {
    final fullName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : '${firstName ?? ''} ${lastName ?? ''}'.trim();

    // 1. Mobile Format Validation
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final last10 = cleanPhone.length >= 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;
    if (last10.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(last10)) {
      return {
        'success': false,
        'message': 'Please enter a valid 10-digit Indian mobile number.'
      };
    }

    // 2. Duplicate Mobile Check
    final allUsers = await fetchUsers();
    final isDup = allUsers?.any((u) {
          final uClean = u.phone.replaceAll(RegExp(r'\D'), '');
          final uLast10 = uClean.length >= 10
              ? uClean.substring(uClean.length - 10)
              : uClean;
          return uLast10 == last10;
        }) ??
        false;

    if (isDup) {
      return {
        'success': false,
        'message':
            'A user with this mobile number already exists (Duplicate Mobile Number).'
      };
    }

    // 3. Resolve Role
    UserRole parsedRole = UserRole.citizen;
    for (final r in UserRole.values) {
      if (r.name.toLowerCase() == role.toLowerCase() ||
          r.roleKey.toLowerCase() == role.toLowerCase() ||
          r.localizedKey.toLowerCase() == role.toLowerCase()) {
        parsedRole = r;
        break;
      }
    }

    final passHash = (password != null && password.trim().isNotEmpty)
        ? HashUtil.hashPassword(password.trim())
        : null;

    final newUser = UserModel(
      id: const Uuid().v4(),
      name: fullName,
      phone: last10,
      email: email ?? '',
      organizationId: organizationId,
      role: parsedRole,
      customRoleName: parsedRole == UserRole.custom ? role : null,
      isActive: isActive,
      accountStatus: accountStatus ?? (isActive ? 'active' : 'inactive'),
      groupIds: groupIds ?? ['grp_001'],
      selectedGroupId:
          groupIds != null && groupIds.isNotEmpty ? groupIds.first : 'grp_001',
      address: address,
      notes: notes,
      passwordHash: passHash,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 4. Try Backend API first if online
    if (await isBackendOnline()) {
      try {
        final uri = Uri.parse(
            '$baseUrl/users${actorId != null ? '?actor_id=$actorId' : ''}');
        final res = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'name': fullName,
                'first_name': firstName ?? fullName.split(' ').first,
                'last_name': lastName ??
                    (fullName.split(' ').length > 1
                        ? fullName.split(' ').sublist(1).join(' ')
                        : ''),
                'phone': last10,
                'role': role,
                'organization_id': organizationId,
                'group_ids': groupIds ?? ['grp_001'],
                'is_active': isActive,
                'email': email,
                'password': password ?? '',
                'address': address,
                'notes': notes,
                'account_status':
                    accountStatus ?? (isActive ? 'active' : 'inactive'),
              }),
            )
            .timeout(const Duration(seconds: 4));

        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          final createdUser = UserModel.fromJson(data);
          MockDataService.addUser(createdUser);
          return {'success': true, 'data': createdUser};
        } else {
          return {
            'success': false,
            'message': data['detail'] ?? 'Failed to create user.'
          };
        }
      } catch (_) {}
    }

    // 5. Direct Supabase / Mock fallback
    final ok = await SupabaseService.insertUser(newUser,
        actorId: actorId, passwordHash: passHash);
    if (ok) {
      return {'success': true, 'data': newUser};
    }
    return {'success': false, 'message': 'Failed to create user in database.'};
  }

  // 36. Update User by Admin
  static Future<Map<String, dynamic>> updateUserByAdmin({
    required String userId,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? organizationId,
    List<String>? groupIds,
    bool? isActive,
    String? address,
    String? notes,
    String? accountStatus,
    String? actorId,
  }) async {
    // Check duplicate phone if phone is updated
    if (phone != null && phone.trim().isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final last10 = cleanPhone.length >= 10
          ? cleanPhone.substring(cleanPhone.length - 10)
          : cleanPhone;
      final allUsers = await fetchUsers();
      final isDup = allUsers?.any((u) {
            if (u.id == userId) return false;
            final uClean = u.phone.replaceAll(RegExp(r'\D'), '');
            final uLast10 = uClean.length >= 10
                ? uClean.substring(uClean.length - 10)
                : uClean;
            return uLast10 == last10;
          }) ??
          false;

      if (isDup) {
        return {
          'success': false,
          'message': 'Another user already exists with this mobile number.'
        };
      }
    }

    if (await isBackendOnline()) {
      try {
        final uri = Uri.parse(
            '$baseUrl/users/$userId${actorId != null ? '?actor_id=$actorId' : ''}');
        final res = await http
            .put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                if (name != null) 'name': name,
                if (phone != null) 'phone': phone,
                if (email != null) 'email': email,
                if (role != null) 'role': role,
                if (organizationId != null) 'organization_id': organizationId,
                if (groupIds != null) 'group_ids': groupIds,
                if (isActive != null) 'is_active': isActive,
                if (address != null) 'address': address,
                if (notes != null) 'notes': notes,
                if (accountStatus != null) 'account_status': accountStatus,
              }),
            )
            .timeout(const Duration(seconds: 4));

        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          final updatedUser = UserModel.fromJson(data);
          MockDataService.addUser(updatedUser);
          return {'success': true, 'data': updatedUser};
        } else {
          return {
            'success': false,
            'message': data['detail'] ?? 'Failed to update user.'
          };
        }
      } catch (_) {}
    }

    // Direct Supabase / Mock update
    final allUsers = await fetchUsers();
    final existing = allUsers?.firstWhere(
      (u) => u.id == userId,
      orElse: () => UserModel(
        id: userId,
        name: name ?? '',
        phone: phone ?? '',
        email: email ?? '',
        organizationId: organizationId ?? 'org_001',
        role: UserRole.citizen,
      ),
    );

    UserRole updatedRole = existing?.role ?? UserRole.citizen;
    if (role != null) {
      for (final r in UserRole.values) {
        if (r.name.toLowerCase() == role.toLowerCase() ||
            r.roleKey.toLowerCase() == role.toLowerCase() ||
            r.localizedKey.toLowerCase() == role.toLowerCase()) {
          updatedRole = r;
          break;
        }
      }
    }

    final updated = existing!.copyWith(
      name: name ?? existing.name,
      phone: phone ?? existing.phone,
      email: email ?? existing.email,
      role: updatedRole,
      organizationId: organizationId ?? existing.organizationId,
      groupIds: groupIds ?? existing.groupIds,
      selectedGroupId: groupIds != null && groupIds.isNotEmpty
          ? groupIds.first
          : existing.selectedGroupId,
      isActive: isActive ?? existing.isActive,
      accountStatus: accountStatus ??
          (isActive != null
              ? (isActive ? 'active' : 'inactive')
              : existing.accountStatus),
      address: address ?? existing.address,
      notes: notes ?? existing.notes,
      updatedAt: DateTime.now(),
    );

    await SupabaseService.updateUser(updated, actorId: actorId);
    return {'success': true, 'data': updated};
  }

  // 37. Toggle User Status (Active / Inactive)
  static Future<Map<String, dynamic>> toggleUserStatus({
    required String userId,
    required bool isActive,
    String? actorId,
  }) async {
    if (await isBackendOnline()) {
      try {
        final uri = Uri.parse(
            '$baseUrl/users/$userId/status${actorId != null ? '?actor_id=$actorId' : ''}');
        final res = await http
            .put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'is_active': isActive}),
            )
            .timeout(const Duration(seconds: 4));

        final data = jsonDecode(res.body);
        if (res.statusCode == 200) {
          return {'success': true, 'data': data};
        } else {
          return {
            'success': false,
            'message': data['detail'] ?? 'Failed to change status.'
          };
        }
      } catch (_) {}
    }

    final newStatus = isActive ? 'active' : 'inactive';
    await SupabaseService.updateProfileStatus(userId, newStatus);
    final allUsers = await fetchUsers();
    final user = allUsers?.firstWhere((u) => u.id == userId,
        orElse: () => MockDataService.users.first);
    if (user != null) {
      final updated =
          user.copyWith(isActive: isActive, accountStatus: newStatus);
      MockDataService.addUser(updated);
    }
    return {
      'success': true,
      'data': {'message': 'Account status updated to $newStatus.'}
    };
  }

  // 37b. Has Financial Transactions Check
  static Future<bool> hasFinancialTransactions(String userId) async {
    return await SupabaseService.hasFinancialTransactions(userId);
  }

  // 38. Fetch Database-Backed User Profile
  static Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/user/profile?user_id=$userId'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }
}
