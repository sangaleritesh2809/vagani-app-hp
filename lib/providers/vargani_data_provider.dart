import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../core/services/mock_data_service.dart';

class VarganiDataProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  OrganizationModel _organization = MockDataService.organization;
  List<CampaignModel> _campaigns = List.from(MockDataService.campaigns);
  late String _selectedCampaignId;

  List<HouseholdModel> _households = List.from(MockDataService.getInitialHouseholds());
  List<PaymentModel> _payments = List.from(MockDataService.getInitialPayments());
  List<ReceiptModel> _receipts = List.from(MockDataService.getInitialReceipts());
  List<CashHandoverModel> _handovers = List.from(MockDataService.getInitialHandovers());
  List<ExpenseModel> _expenses = List.from(MockDataService.getInitialExpenses());
  List<ComplaintModel> _complaints = List.from(MockDataService.getInitialComplaints());
  List<AuditLogModel> _auditLogs = List.from(MockDataService.getInitialAuditLogs());

  // Search & Filters
  String _householdSearchQuery = '';
  String _selectedAreaFilter = 'All';
  PaymentStatus? _selectedStatusFilter;

  VarganiDataProvider() {
    _selectedCampaignId = _campaigns.first.id;
  }

  // Getters
  OrganizationModel get organization => _organization;
  List<CampaignModel> get campaigns => _campaigns;
  String get selectedCampaignId => _selectedCampaignId;

  CampaignModel get currentCampaign =>
      _campaigns.firstWhere((c) => c.id == _selectedCampaignId, orElse: () => _campaigns.first);

  void selectCampaign(String id) {
    _selectedCampaignId = id;
    notifyListeners();
  }

  // Filtered Households
  List<HouseholdModel> get households {
    return _households.where((h) {
      if (h.campaignId != _selectedCampaignId) return false;
      if (_selectedAreaFilter != 'All' && !h.villageArea.toLowerCase().contains(_selectedAreaFilter.toLowerCase())) {
        return false;
      }
      if (_selectedStatusFilter != null && h.paymentStatus != _selectedStatusFilter) {
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
  // Cash in hand = cash collected by that person − cash handovers confirmed as received
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

    return (confirmedHandoversReceived + directCashCollected) - cashExpensesPaid;
  }

  // ACTIONS

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
      perPersonRateSnapshot: currentCampaign.perPersonRate, // Preserves rate snapshot!
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
            'Registered ${newHousehold.headOfFamilyName} (${familyMemberCount} members @ Rs. ${currentCampaign.perPersonRate})',
      ),
    );

    notifyListeners();
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
    final receiptNumber = 'VRG-${DateTime.now().year}-${(_receipts.length + 1).toString().padLeft(4, '0')}';
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
      collectedByName: currentUser.name, // Derived automatically from auth!
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
    return receipt;
  }

  // 3. Cancel / Reverse Receipt (SRS 7: No hard-delete, audit history required)
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
      _households[hIndex] = hh.copyWith(amountReceived: newAmt > 0 ? newAmt : 0.0);
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
        details: 'Cancelled receipt ${receipt.receiptNo} of Rs. ${receipt.amountReceived}. Reason: $reason',
      ),
    );

    notifyListeners();
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
        details: '${approve ? "Confirmed" : "Rejected"} handover of Rs. ${handover.amount} from ${handover.handoverFromName}',
      ),
    );

    notifyListeners();
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
        details: 'Entered expense "${expense.title}" of Rs. $amount (${category.displayName})',
      ),
    );

    notifyListeners();
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
        details: 'Updated expense "${expense.title}" status to ${status.name.toUpperCase()}',
      ),
    );

    notifyListeners();
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
        details: 'Admin response added to complaint "${complaint.title}". Status: ${status.name}',
      ),
    );

    notifyListeners();
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
  }

  // 8. Update Campaign Rate (SRS 5.1 & 13 BR-10: Preserves historical household rate)
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
  }

  // CSV Export String (SRS 11)
  String generateHouseholdsCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Household ID,Head of Family,Mobile,Area,Members,Rate Snapshot,Expected Total,Received,Remaining,Status');
    for (var h in _households.where((h) => h.campaignId == _selectedCampaignId)) {
      buffer.writeln(
        '${h.id},"${h.headOfFamilyName}",${h.mobileNumber},"${h.villageArea}",${h.familyMemberCount},${h.perPersonRateSnapshot},${h.expectedTotalVargani},${h.amountReceived},${h.remainingAmount},${h.paymentStatus.displayName}',
      );
    }
    return buffer.toString();
  }
}
