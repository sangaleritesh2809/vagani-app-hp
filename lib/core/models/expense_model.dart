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
        return 'Tent & Mandap (मंडप / शामियाना)';
      case ExpenseCategory.sound:
        return 'Sound & DJ (ध्वनिक्षेपक / साऊंड)';
      case ExpenseCategory.lighting:
        return 'Lighting & Electricity (विद्युत रोषणाई)';
      case ExpenseCategory.decoration:
        return 'Decoration (सजावट / देखावा)';
      case ExpenseCategory.food:
        return 'Food & Mahaprasad (महाप्रसाद / भोजन)';
      case ExpenseCategory.eventArrangements:
        return 'Event Arrangements (व्यवस्था / नियोजन)';
      case ExpenseCategory.advertising:
        return 'Advertising & Banners (जाहिरात व फलक)';
      case ExpenseCategory.transport:
        return 'Transport (वाहतूक)';
      case ExpenseCategory.prizes:
        return 'Prizes & Trophies (बक्षिसे)';
      case ExpenseCategory.other:
        return 'Other Expenses (इतर खर्च)';
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
}
