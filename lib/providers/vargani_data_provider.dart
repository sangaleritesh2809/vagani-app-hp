import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/models/organization_model.dart';
import '../core/models/campaign_model.dart';
import '../core/models/household_model.dart';
import '../core/models/payment_model.dart';
import '../core/models/receipt_model.dart';
import '../core/models/cash_handover_model.dart';
import '../core/models/expense_model.dart';
import '../core/models/complaint_model.dart';
import '../core/models/audit_log_model.dart';
import '../core/models/user_model.dart';
import '../core/services/api_service.dart';
import '../core/services/mock_data_service.dart';

class VarganiDataProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  OrganizationModel _organization = MockDataService.organization;
  List<CampaignModel> _campaigns =
      kDebugMode ? List.from(MockDataService.campaigns) : <CampaignModel>[];
  late String _selectedCampaignId;

  List<HouseholdModel> _households = kDebugMode
      ? List.from(MockDataService.getInitialHouseholds())
      : <HouseholdModel>[];
  List<PaymentModel> _payments = kDebugMode
      ? List.from(MockDataService.getInitialPayments())
      : <PaymentModel>[];
  List<ReceiptModel> _receipts = kDebugMode
      ? List.from(MockDataService.getInitialReceipts())
      : <ReceiptModel>[];
  List<CashHandoverModel> _handovers = kDebugMode
      ? List.from(MockDataService.getInitialHandovers())
      : <CashHandoverModel>[];
  List<ExpenseModel> _expenses = kDebugMode
      ? List.from(MockDataService.getInitialExpenses())
      : <ExpenseModel>[];
  List<ComplaintModel> _complaints = kDebugMode
      ? List.from(MockDataService.getInitialComplaints())
      : <ComplaintModel>[];
  List<AuditLogModel> _auditLogs = kDebugMode
      ? List.from(MockDataService.getInitialAuditLogs())
      : <AuditLogModel>[];

  bool _isLoading = false;
  String? _errorMessage;

  // Search & Filters
  String _householdSearchQuery = '';
  String _selectedAreaFilter = 'All';
  PaymentStatus? _selectedStatusFilter;

  VarganiDataProvider() {
    _selectedCampaignId = _campaigns.isNotEmpty ? _campaigns.first.id : '';
    // Load live data from backend immediately
    initDataFromBackend();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  OrganizationModel get organization => _organization;
  List<CampaignModel> get campaigns => _campaigns;
  String get selectedCampaignId => _selectedCampaignId;

  CampaignModel get currentCampaign =>
      _campaigns.firstWhere((c) => c.id == _selectedCampaignId,
          orElse: () => _campaigns.isNotEmpty
              ? _campaigns.first
              : CampaignModel(
                  id: '',
                  organizationId: _organization.id,
                  name: 'Vargani Campaign',
                  varganiType: VarganiType.ganeshotsav,
                  description: '',
                  startDate: DateTime.now(),
                  endDate: DateTime.now().add(const Duration(days: 30)),
                  targetAmount: 0,
                  perPersonRate: 100,
                  rateEffectiveDate: DateTime.now(),
                ));

  void selectCampaign(String id) {
    _selectedCampaignId = id;
    notifyListeners();
    refreshCampaignData(id);
  }

  /// Initial fetch from backend API
  Future<void> initDataFromBackend() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch organization
      final org = await ApiService.fetchOrganization();
      if (org != null) {
        _organization = org;
      }

      // 2. Fetch campaigns
      final camps = await ApiService.fetchCampaigns();
      if (camps != null && camps.isNotEmpty) {
        _campaigns = camps;
        if (!_campaigns.any((c) => c.id == _selectedCampaignId)) {
          _selectedCampaignId = _campaigns.first.id;
        }
      }

      // 3. Fetch data for current campaign
      await refreshCampaignData(_selectedCampaignId);
    } catch (e) {
      _errorMessage =
          'Unable to connect to server. Please check your internet connection or try again later. (Server Unreachable)';
      debugPrint('Notice: Backend sync error ($e). Retaining local state.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all campaign-specific collections and expenses from backend API
  Future<void> refreshCampaignData(String campaignId) async {
    try {
      final results = await Future.wait([
        ApiService.fetchHouseholds(campaignId),
        ApiService.fetchCollections(campaignId),
        ApiService.fetchReceipts(campaignId),
        ApiService.fetchHandovers(campaignId),
        ApiService.fetchExpenses(campaignId),
        ApiService.fetchComplaints(campaignId),
        ApiService.fetchAuditLogs(),
      ]);

      if (results[0] != null) {
        _households = results[0] as List<HouseholdModel>;
      }
      if (results[1] != null) {
        _payments = results[1] as List<PaymentModel>;
      }
      if (results[2] != null) {
        _receipts = results[2] as List<ReceiptModel>;
      }
      if (results[3] != null) {
        _handovers = results[3] as List<CashHandoverModel>;
      }
      if (results[4] != null) {
        _expenses = results[4] as List<ExpenseModel>;
      }
      if (results[5] != null) {
        _complaints = results[5] as List<ComplaintModel>;
      }
      if (results[6] != null) {
        _auditLogs = results[6] as List<AuditLogModel>;
      }
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Unable to connect to server. Please check your internet connection or try again later. (Server Unreachable)';
      debugPrint('Notice: Campaign refresh error ($e)');
      notifyListeners();
    }
  }

  // Filtered Households
  List<HouseholdModel> get households {
    return _households.where((h) {
      if (h.campaignId != _selectedCampaignId) return false;
      if (_selectedAreaFilter != 'All' &&
          !h.villageArea
              .toLowerCase()
              .contains(_selectedAreaFilter.toLowerCase())) {
        return false;
      }
      if (_selectedStatusFilter != null &&
          h.paymentStatus != _selectedStatusFilter) {
        return false;
      }
      if (_householdSearchQuery.isNotEmpty) {
        final query = _householdSearchQuery.toLowerCase();
        final matchesName = h.headOfFamilyName.toLowerCase().contains(query);
        final matchesArea = h.villageArea.toLowerCase().contains(query);
        final matchesPhone = h.mobileNumber.contains(query);
        return matchesName || matchesArea || matchesPhone;
      }
      return true;
    }).toList();
  }

  List<String> get availableAreas {
    final areas = _households
        .where((h) => h.campaignId == _selectedCampaignId)
        .map((h) => h.villageArea.split(',').first.trim())
        .toSet()
        .toList();
    areas.sort();
    return ['All', ...areas];
  }

  void setHouseholdSearch(String query) {
    _householdSearchQuery = query;
    notifyListeners();
  }

  void setAreaFilter(String area) {
    _selectedAreaFilter = area;
    notifyListeners();
  }

  void setStatusFilter(PaymentStatus? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  // Filtered lists for current campaign
  List<PaymentModel> get payments =>
      _payments.where((p) => p.campaignId == _selectedCampaignId).toList();

  List<ReceiptModel> get receipts =>
      _receipts.where((r) => r.campaignId == _selectedCampaignId).toList();

  List<CashHandoverModel> get handovers =>
      _handovers.where((h) => h.campaignId == _selectedCampaignId).toList();

  List<ExpenseModel> get expenses =>
      _expenses.where((e) => e.campaignId == _selectedCampaignId).toList();

  List<ComplaintModel> get complaints =>
      _complaints.where((c) => c.campaignId == _selectedCampaignId).toList();

  List<AuditLogModel> get auditLogs => _auditLogs;

  // Key Financial Metric Calculations (SRS 5, 8, 9, 11)
  double get totalExpectedVargani {
    return _households
        .where((h) => h.campaignId == _selectedCampaignId)
        .fold(0.0, (sum, h) => sum + h.expectedTotalVargani);
  }

  double get totalVerifiedReceived {
    return _payments
        .where((p) =>
            p.campaignId == _selectedCampaignId &&
            p.verificationStatus == VerificationStatus.verified)
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double get totalRemainingDue {
    final diff = totalExpectedVargani - totalVerifiedReceived;
    return diff > 0 ? diff : 0.0;
  }

  double get totalApprovedExpenses {
    return _expenses
        .where((e) =>
            e.campaignId == _selectedCampaignId &&
            e.approvalStatus == ExpenseApprovalStatus.approved)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get totalActualPaidExpenses {
    return _expenses
        .where((e) =>
            e.campaignId == _selectedCampaignId &&
            e.approvalStatus == ExpenseApprovalStatus.approved &&
            e.paymentStatus == ExpensePaymentStatus.paid)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get availableNetBalance {
    return totalVerifiedReceived - totalActualPaidExpenses;
  }

  // Payment Breakdown
  Map<PaymentType, double> get paymentBreakdown {
    final map = {
      PaymentType.cash: 0.0,
      PaymentType.upi: 0.0,
      PaymentType.bankTransfer: 0.0,
      PaymentType.other: 0.0,
    };
    for (var p in payments) {
      if (p.verificationStatus == VerificationStatus.verified) {
        map[p.paymentType] = (map[p.paymentType] ?? 0.0) + p.amount;
      }
    }
    return map;
  }

  // Person-wise Cash Balance Calculation (SRS 6.3)
  double getPersonCashBalance(String userId) {
    final totalCashCollected = _payments
        .where((p) =>
            p.campaignId == _selectedCampaignId &&
            p.collectedById == userId &&
            p.paymentType == PaymentType.cash &&
            p.verificationStatus == VerificationStatus.verified)
        .fold(0.0, (sum, p) => sum + p.amount);

    final totalConfirmedHandoversGiven = _handovers
        .where((h) =>
            h.campaignId == _selectedCampaignId &&
            h.handoverFromId == userId &&
            h.status == HandoverStatus.confirmed)
        .fold(0.0, (sum, h) => sum + h.amount);

    final balance = totalCashCollected - totalConfirmedHandoversGiven;
    return balance > 0 ? balance : 0.0;
  }

  // Treasurer Total Cash in Hand
  double getTreasurerCashInHand(String treasurerId) {
    final confirmedHandoversReceived = _handovers
        .where((h) =>
            h.campaignId == _selectedCampaignId &&
            h.handoverToId == treasurerId &&
            h.status == HandoverStatus.confirmed)
        .fold(0.0, (sum, h) => sum + h.amount);

    final directCashCollected = _payments
        .where((p) =>
            p.campaignId == _selectedCampaignId &&
            p.collectedById == treasurerId &&
            p.paymentType == PaymentType.cash &&
            p.verificationStatus == VerificationStatus.verified)
        .fold(0.0, (sum, p) => sum + p.amount);

    final cashExpensesPaid = _expenses
        .where((e) =>
            e.campaignId == _selectedCampaignId &&
            e.approvalStatus == ExpenseApprovalStatus.approved &&
            e.paymentStatus == ExpensePaymentStatus.paid &&
            e.paymentMode.toLowerCase().contains('cash'))
        .fold(0.0, (sum, e) => sum + e.amount);

    return (confirmedHandoversReceived + directCashCollected) -
        cashExpensesPaid;
  }

  // ACTIONS (With Backend API Integrations)

  // 1. Register Household (Option A - SRS 5.2)
  void registerHousehold({
    required String headOfFamilyName,
    required String mobileNumber,
    required String villageArea,
    required int familyMemberCount,
    required UserModel currentUser,
  }) {
    final newHousehold = HouseholdModel(
      id: 'hh_${_uuid.v4().substring(0, 8)}',
      campaignId: _selectedCampaignId,
      organizationId: _organization.id,
      headOfFamilyName: headOfFamilyName,
      mobileNumber: mobileNumber,
      villageArea: villageArea,
      familyMemberCount: familyMemberCount,
      perPersonRateSnapshot: currentCampaign.perPersonRate,
      amountReceived: 0.0,
      createdAt: DateTime.now(),
    );

    _households.insert(0, newHousehold);

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Household',
        entityId: newHousehold.id,
        action: 'REGISTER_HOUSEHOLD',
        performedById: currentUser.id,
        performedByName: currentUser.name,
        timestamp: DateTime.now(),
        details:
            'Registered ${newHousehold.headOfFamilyName} ($familyMemberCount members @ Rs. ${currentCampaign.perPersonRate})',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.registerHousehold(
      campaignId: _selectedCampaignId,
      headOfFamilyName: headOfFamilyName,
      mobileNumber: mobileNumber,
      villageArea: villageArea,
      familyMemberCount: familyMemberCount,
    ).then((created) {
      if (created != null) {
        final idx = _households.indexWhere((h) => h.id == newHousehold.id);
        if (idx != -1) {
          _households[idx] = created;
          notifyListeners();
        }
      }
    }).ignore();
  }

  // 2. Record Payment & Issue Receipt (SRS 6 & 7)
  ReceiptModel recordPayment({
    required String householdId,
    required double amount,
    required PaymentType paymentType,
    String? referenceId,
    required UserModel currentUser,
    required UserModel receivedByUser,
    String remarks = '',
  }) {
    final householdIndex = _households.indexWhere((h) => h.id == householdId);
    if (householdIndex == -1) throw Exception('Household not found');

    final household = _households[householdIndex];
    final receiptNumber =
        'VRG-${DateTime.now().year}-${(_receipts.length + 1).toString().padLeft(4, '0')}';
    final now = DateTime.now();

    final payment = PaymentModel(
      id: 'pmt_${_uuid.v4().substring(0, 8)}',
      receiptNo: receiptNumber,
      organizationId: _organization.id,
      campaignId: _selectedCampaignId,
      campaignName: currentCampaign.name,
      householdId: household.id,
      householdHeadName: household.headOfFamilyName,
      amount: amount,
      paymentType: paymentType,
      referenceId: referenceId,
      collectedById: currentUser.id,
      collectedByName: currentUser.name,
      receivedById: receivedByUser.id,
      receivedByName: receivedByUser.name,
      verificationStatus: VerificationStatus.verified,
      collectionDateTime: now,
      remarks: remarks,
    );

    final receipt = ReceiptModel(
      id: 'rcp_${_uuid.v4().substring(0, 8)}',
      receiptNo: receiptNumber,
      organizationId: _organization.id,
      campaignId: _selectedCampaignId,
      campaignName: currentCampaign.name,
      householdId: household.id,
      householdHeadName: household.headOfFamilyName,
      familyMemberCount: household.familyMemberCount,
      perPersonRate: household.perPersonRateSnapshot,
      amountReceived: amount,
      paymentType: paymentType,
      referenceId: referenceId,
      collectedByName: currentUser.name,
      receivedByName: receivedByUser.name,
      issuedAt: now,
    );

    // Update household verified received
    _households[householdIndex] = household.copyWith(
      amountReceived: household.amountReceived + amount,
    );

    _payments.insert(0, payment);
    _receipts.insert(0, receipt);

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Payment',
        entityId: payment.id,
        action: 'RECORD_PAYMENT',
        performedById: currentUser.id,
        performedByName: currentUser.name,
        timestamp: now,
        details:
            'Recorded Rs. $amount (${paymentType.displayName}) from ${household.headOfFamilyName}. Receipt: $receiptNumber',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.recordPayment(
      householdId: householdId,
      campaignId: _selectedCampaignId,
      amount: amount,
      paymentType: paymentType.name,
      referenceId: referenceId,
      collectedByName: currentUser.name,
      receivedByName: receivedByUser.name,
      remarks: remarks,
    ).then((createdReceipt) {
      if (createdReceipt != null) {
        final rIdx = _receipts.indexWhere((r) => r.id == receipt.id);
        if (rIdx != -1) {
          _receipts[rIdx] = createdReceipt;
          notifyListeners();
        }
      }
    }).ignore();

    return receipt;
  }

  // 3. Cancel / Reverse Receipt (SRS 7)
  void cancelReceipt({
    required String receiptId,
    required String reason,
    required UserModel currentUser,
  }) {
    final rIndex = _receipts.indexWhere((r) => r.id == receiptId);
    if (rIndex == -1) return;

    final receipt = _receipts[rIndex];
    if (receipt.isCancelled) return;

    final updatedReceipt = receipt.cancel(
      reason: reason,
      cancelledByName: currentUser.name,
      cancelledAt: DateTime.now(),
    );

    _receipts[rIndex] = updatedReceipt;

    // Deduct from household received amount
    final hIndex = _households.indexWhere((h) => h.id == receipt.householdId);
    if (hIndex != -1) {
      final hh = _households[hIndex];
      final newAmt = hh.amountReceived - receipt.amountReceived;
      _households[hIndex] =
          hh.copyWith(amountReceived: newAmt > 0 ? newAmt : 0.0);
    }

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Receipt',
        entityId: receipt.id,
        action: 'CANCEL_RECEIPT',
        performedById: currentUser.id,
        performedByName: currentUser.name,
        timestamp: DateTime.now(),
        details:
            'Cancelled receipt ${receipt.receiptNo} of Rs. ${receipt.amountReceived}. Reason: $reason',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.cancelReceipt(
      receiptId: receiptId,
      reason: reason,
      cancelledByName: currentUser.name,
    ).ignore();
  }

  // 4. Submit Cash Handover (SRS 6.3)
  void submitCashHandover({
    required UserModel fromUser,
    required UserModel toUser,
    required double amount,
    String remarks = '',
  }) {
    final handover = CashHandoverModel(
      id: 'hnd_${_uuid.v4().substring(0, 8)}',
      organizationId: _organization.id,
      campaignId: _selectedCampaignId,
      handoverFromId: fromUser.id,
      handoverFromName: fromUser.name,
      handoverToId: toUser.id,
      handoverToName: toUser.name,
      amount: amount,
      dateTime: DateTime.now(),
      remarks: remarks,
      status: HandoverStatus.pending,
    );

    _handovers.insert(0, handover);

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'CashHandover',
        entityId: handover.id,
        action: 'SUBMIT_HANDOVER',
        performedById: fromUser.id,
        performedByName: fromUser.name,
        timestamp: DateTime.now(),
        details: 'Submitted cash handover of Rs. $amount to ${toUser.name}',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.submitHandover(
      campaignId: _selectedCampaignId,
      handoverFromName: fromUser.name,
      handoverToName: toUser.name,
      amount: amount,
      remarks: remarks,
    ).then((created) {
      if (created != null) {
        final idx = _handovers.indexWhere((h) => h.id == handover.id);
        if (idx != -1) {
          _handovers[idx] = created;
          notifyListeners();
        }
      }
    }).ignore();
  }

  // 5. Confirm or Reject Handover (SRS 6.3)
  void processHandover({
    required String handoverId,
    required bool approve,
    required UserModel confirmedByUser,
  }) {
    final index = _handovers.indexWhere((h) => h.id == handoverId);
    if (index == -1) return;

    final handover = _handovers[index];
    _handovers[index] = handover.copyWith(
      status: approve ? HandoverStatus.confirmed : HandoverStatus.rejected,
      confirmedById: confirmedByUser.id,
      confirmedByName: confirmedByUser.name,
      confirmedAt: DateTime.now(),
    );

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'CashHandover',
        entityId: handover.id,
        action: approve ? 'CONFIRM_HANDOVER' : 'REJECT_HANDOVER',
        performedById: confirmedByUser.id,
        performedByName: confirmedByUser.name,
        timestamp: DateTime.now(),
        details:
            '${approve ? "Confirmed" : "Rejected"} handover of Rs. ${handover.amount} from ${handover.handoverFromName}',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.processHandover(
      handoverId: handoverId,
      approve: approve,
      confirmedByName: confirmedByUser.name,
    ).ignore();
  }

  // 6. Expense Management (SRS 8)
  void addExpense({
    required ExpenseCategory category,
    required String title,
    required String description,
    required double amount,
    required String vendorPayee,
    required String paymentMode,
    required String billNumber,
    required bool hasProof,
    required UserModel currentUser,
    bool isPublicVisible = true,
  }) {
    final expense = ExpenseModel(
      id: 'exp_${_uuid.v4().substring(0, 8)}',
      organizationId: _organization.id,
      campaignId: _selectedCampaignId,
      category: category,
      title: title,
      description: description,
      amount: amount,
      date: DateTime.now(),
      vendorPayee: vendorPayee,
      paymentMode: paymentMode,
      billNumber: billNumber,
      hasProof: hasProof,
      enteredById: currentUser.id,
      enteredByName: currentUser.name,
      approvalStatus: ExpenseApprovalStatus.pending,
      paymentStatus: ExpensePaymentStatus.paid,
      isPublicVisible: isPublicVisible,
    );

    _expenses.insert(0, expense);

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Expense',
        entityId: expense.id,
        action: 'ADD_EXPENSE',
        performedById: currentUser.id,
        performedByName: currentUser.name,
        timestamp: DateTime.now(),
        details:
            'Entered expense "${expense.title}" of Rs. $amount (${category.displayName})',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.addExpense(
      campaignId: _selectedCampaignId,
      category: category.name,
      title: title,
      description: description,
      amount: amount,
      vendorPayee: vendorPayee,
      paymentMode: paymentMode,
      billNumber: billNumber,
      hasProof: hasProof,
      enteredByName: currentUser.name,
      isPublicVisible: isPublicVisible,
    ).then((created) {
      if (created != null) {
        final idx = _expenses.indexWhere((e) => e.id == expense.id);
        if (idx != -1) {
          _expenses[idx] = created;
          notifyListeners();
        }
      }
    }).ignore();
  }

  void updateExpenseApproval({
    required String expenseId,
    required ExpenseApprovalStatus status,
    required UserModel currentUser,
  }) {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;

    final expense = _expenses[index];
    _expenses[index] = expense.copyWith(approvalStatus: status);

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Expense',
        entityId: expense.id,
        action: 'UPDATE_EXPENSE_APPROVAL',
        performedById: currentUser.id,
        performedByName: currentUser.name,
        timestamp: DateTime.now(),
        details:
            'Updated expense "${expense.title}" status to ${status.name.toUpperCase()}',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.approveExpense(
      expenseId: expenseId,
      status: status.name,
      performedByName: currentUser.name,
    ).ignore();
  }

  // 7. Complaint Management (SRS 10)
  void submitComplaint({
    required ComplaintType type,
    required String title,
    required String description,
    required UserModel citizenUser,
    String? relatedRecordId,
  }) {
    final complaint = ComplaintModel(
      id: 'cmp_${_uuid.v4().substring(0, 8)}',
      organizationId: _organization.id,
      campaignId: _selectedCampaignId,
      campaignName: currentCampaign.name,
      relatedRecordId: relatedRecordId,
      type: type,
      title: title,
      description: description,
      submittedById: citizenUser.id,
      submittedByName: citizenUser.name,
      submittedByPhone: citizenUser.phone,
      submittedDate: DateTime.now(),
      status: ComplaintStatus.submitted,
    );

    _complaints.insert(0, complaint);

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Complaint',
        entityId: complaint.id,
        action: 'SUBMIT_COMPLAINT',
        performedById: citizenUser.id,
        performedByName: citizenUser.name,
        timestamp: DateTime.now(),
        details: 'Citizen ${citizenUser.name} submitted complaint: "$title"',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.submitComplaint(
      campaignId: _selectedCampaignId,
      type: type.name,
      title: title,
      description: description,
      submittedByName: citizenUser.name,
      submittedByPhone: citizenUser.phone,
    ).then((created) {
      if (created != null) {
        final idx = _complaints.indexWhere((c) => c.id == complaint.id);
        if (idx != -1) {
          _complaints[idx] = created.copyWith(
            submittedById: citizenUser.id,
            submittedByName: citizenUser.name,
            submittedByPhone: citizenUser.phone,
          );
          notifyListeners();
        }
      }
    }).ignore();
  }

  void respondToComplaint({
    required String complaintId,
    required String response,
    required ComplaintStatus status,
    String? resolutionNotes,
    required UserModel currentUser,
  }) {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index == -1) return;

    final complaint = _complaints[index];
    _complaints[index] = complaint.copyWith(
      adminResponse: response,
      status: status,
      resolutionNotes: resolutionNotes,
      resolvedDate: status == ComplaintStatus.resolved ? DateTime.now() : null,
    );

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Complaint',
        entityId: complaint.id,
        action: 'RESPOND_COMPLAINT',
        performedById: currentUser.id,
        performedByName: currentUser.name,
        timestamp: DateTime.now(),
        details:
            'Admin response added to complaint "${complaint.title}". Status: ${status.name}',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.respondComplaint(
      complaintId: complaintId,
      response: response,
      status: status.name,
      performedByName: currentUser.name,
    ).ignore();
  }

  void escalateComplaintToSuperAdmin({
    required String complaintId,
    required UserModel currentUser,
  }) {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index == -1) return;

    final complaint = _complaints[index];
    _complaints[index] = complaint.copyWith(
      status: ComplaintStatus.escalated,
      isEscalated: true,
    );

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Complaint',
        entityId: complaint.id,
        action: 'ESCALATE_COMPLAINT',
        performedById: currentUser.id,
        performedByName: currentUser.name,
        timestamp: DateTime.now(),
        details: 'Escalated complaint "${complaint.title}" to Super Admin',
      ),
    );

    notifyListeners();

    // Call Backend API to update complaint status
    ApiService.respondComplaint(
      complaintId: complaintId,
      response: 'Escalated to Super Admin for grievance review',
      status: 'escalated',
      performedByName: currentUser.name,
    ).ignore();
  }

  // 8. Update Campaign Rate (SRS 5.1 & 13 BR-10)
  void updateCampaignPerPersonRate({
    required double newRate,
    required UserModel currentUser,
  }) {
    final cIndex = _campaigns.indexWhere((c) => c.id == _selectedCampaignId);
    if (cIndex == -1) return;

    final oldRate = _campaigns[cIndex].perPersonRate;
    _campaigns[cIndex] = _campaigns[cIndex].copyWith(
      perPersonRate: newRate,
      rateEffectiveDate: DateTime.now(),
    );

    _auditLogs.insert(
      0,
      AuditLogModel(
        id: 'aud_${_uuid.v4().substring(0, 8)}',
        organizationId: _organization.id,
        entityType: 'Campaign',
        entityId: _selectedCampaignId,
        action: 'UPDATE_RATE',
        performedById: currentUser.id,
        performedByName: currentUser.name,
        timestamp: DateTime.now(),
        details:
            'Updated campaign rate from Rs. $oldRate to Rs. $newRate. Existing household rates preserved.',
      ),
    );

    notifyListeners();

    // Call Backend API
    ApiService.updateCampaignRate(
      campaignId: _selectedCampaignId,
      newRate: newRate,
      performedByName: currentUser.name,
    ).ignore();
  }

  // CSV Export String (SRS 11)
  String generateHouseholdsCsv() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Household ID,Head of Family,Mobile,Area,Members,Rate Snapshot,Expected Total,Received,Remaining,Status');
    for (var h
        in _households.where((h) => h.campaignId == _selectedCampaignId)) {
      buffer.writeln(
        '${h.id},"${h.headOfFamilyName}",${h.mobileNumber},"${h.villageArea}",${h.familyMemberCount},${h.perPersonRateSnapshot},${h.expectedTotalVargani},${h.amountReceived},${h.remainingAmount},${h.paymentStatus.displayName}',
      );
    }
    return buffer.toString();
  }
}
