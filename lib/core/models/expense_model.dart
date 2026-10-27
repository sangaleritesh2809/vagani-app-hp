enum ExpenseCategory {
  tent,
  sound,
  lighting,
  decoration,
  food,
  eventArrangements,
  advertising,
  transport,
  prizes,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.tent:
        return 'Tent & Mandap';
      case ExpenseCategory.sound:
        return 'Sound & DJ';
      case ExpenseCategory.lighting:
        return 'Lighting & Electricity';
      case ExpenseCategory.decoration:
        return 'Decoration';
      case ExpenseCategory.food:
        return 'Food & Mahaprasad';
      case ExpenseCategory.eventArrangements:
        return 'Event Arrangements';
      case ExpenseCategory.advertising:
        return 'Advertising & Banners';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.prizes:
        return 'Prizes & Trophies';
      case ExpenseCategory.other:
        return 'Other Expenses';
    }
  }
}

enum ExpenseApprovalStatus {
  pending,
  approved,
  rejected,
}

enum ExpensePaymentStatus {
  unpaid,
  partiallyPaid,
  paid,
}

class ExpenseModel {
  final String id;
  final String organizationId;
  final String campaignId;
  final ExpenseCategory category;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final String vendorPayee;
  final String paymentMode;
  final String billNumber;
  final bool hasProof;
  final String? attachmentUrl;
  final String enteredById;
  final String enteredByName;
  final ExpenseApprovalStatus approvalStatus;
  final ExpensePaymentStatus paymentStatus;
  final bool isPublicVisible;

  const ExpenseModel({
    required this.id,
    required this.organizationId,
    required this.campaignId,
    required this.category,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.vendorPayee,
    required this.paymentMode,
    required this.billNumber,
    this.hasProof = false,
    this.attachmentUrl,
    required this.enteredById,
    required this.enteredByName,
    this.approvalStatus = ExpenseApprovalStatus.pending,
    this.paymentStatus = ExpensePaymentStatus.paid,
    this.isPublicVisible = true,
  });

  ExpenseModel copyWith({
    String? id,
    String? organizationId,
    String? campaignId,
    ExpenseCategory? category,
    String? title,
    String? description,
    double? amount,
    DateTime? date,
    String? vendorPayee,
    String? paymentMode,
    String? billNumber,
    bool? hasProof,
    String? attachmentUrl,
    String? enteredById,
    String? enteredByName,
    ExpenseApprovalStatus? approvalStatus,
    ExpensePaymentStatus? paymentStatus,
    bool? isPublicVisible,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      campaignId: campaignId ?? this.campaignId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      vendorPayee: vendorPayee ?? this.vendorPayee,
      paymentMode: paymentMode ?? this.paymentMode,
      billNumber: billNumber ?? this.billNumber,
      hasProof: hasProof ?? this.hasProof,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      enteredById: enteredById ?? this.enteredById,
      enteredByName: enteredByName ?? this.enteredByName,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isPublicVisible: isPublicVisible ?? this.isPublicVisible,
    );
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    ExpenseCategory cat = ExpenseCategory.other;
    final catStr = (json['category'] ?? '').toString().toLowerCase();
    for (final c in ExpenseCategory.values) {
      if (c.name.toLowerCase() == catStr) {
        cat = c;
        break;
      }
    }

    ExpenseApprovalStatus aStatus = ExpenseApprovalStatus.pending;
    final aStr =
        (json['approval_status'] ?? json['approvalStatus'] ?? 'pending')
            .toString()
            .toLowerCase();
    for (final a in ExpenseApprovalStatus.values) {
      if (a.name.toLowerCase() == aStr) {
        aStatus = a;
        break;
      }
    }

    ExpensePaymentStatus pStatus = ExpensePaymentStatus.paid;
    final pStr = (json['payment_status'] ?? json['paymentStatus'] ?? 'paid')
        .toString()
        .toLowerCase();
    for (final p in ExpensePaymentStatus.values) {
      if (p.name.toLowerCase() == pStr) {
        pStatus = p;
        break;
      }
    }

    return ExpenseModel(
      id: json['id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ??
          json['organizationId'] as String? ??
          'org_001',
      campaignId: json['campaign_id'] as String? ??
          json['campaignId'] as String? ??
          'cmp_ganesh_2026',
      category: cat,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: ((json['amount'] ?? 0.0) as num).toDouble(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      vendorPayee: json['vendor_payee'] as String? ??
          json['vendorPayee'] as String? ??
          '',
      paymentMode: json['payment_mode'] as String? ??
          json['paymentMode'] as String? ??
          'Cash',
      billNumber:
          json['bill_number'] as String? ?? json['billNumber'] as String? ?? '',
      hasProof: json['has_proof'] ?? json['hasProof'] ?? false,
      attachmentUrl:
          json['attachment_url'] as String? ?? json['attachmentUrl'] as String?,
      enteredById: json['entered_by_id'] as String? ??
          json['enteredById'] as String? ??
          'usr_admin',
      enteredByName: json['entered_by_name'] as String? ??
          json['enteredByName'] as String? ??
          '',
      approvalStatus: aStatus,
      paymentStatus: pStatus,
      isPublicVisible:
          json['is_public_visible'] ?? json['isPublicVisible'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'category': category.name,
      'title': title,
      'description': description,
      'amount': amount,
      'vendor_payee': vendorPayee,
      'payment_mode': paymentMode,
      'bill_number': billNumber,
      'has_proof': hasProof,
      'entered_by_name': enteredByName,
      'approval_status': approvalStatus.name,
      'payment_status': paymentStatus.name,
      'is_public_visible': isPublicVisible,
    };
  }
}
