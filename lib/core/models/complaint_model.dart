enum ComplaintType {
  collectionDiscrepancy,
  receiptIssue,
  expenseAudit,
  generalInquiry,
}

extension ComplaintTypeExtension on ComplaintType {
  String get displayName {
    switch (this) {
      case ComplaintType.collectionDiscrepancy:
        return 'Collection Discrepancy (वर्गणी तफावत)';
      case ComplaintType.receiptIssue:
        return 'Receipt Issue (पावती तक्रार)';
      case ComplaintType.expenseAudit:
        return 'Expense Question / Audit (खर्च आक्षेप)';
      case ComplaintType.generalInquiry:
        return 'General Feedback / Inquiry (सामान्य विचारणा)';
    }
  }
}

enum ComplaintStatus {
  submitted,
  underReview,
  additionalInfoRequired,
  actionTaken,
  resolved,
  rejectedWithReason,
  escalated,
}

extension ComplaintStatusExtension on ComplaintStatus {
  String get displayName {
    switch (this) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.underReview:
        return 'Under Review';
      case ComplaintStatus.additionalInfoRequired:
        return 'Info Required';
      case ComplaintStatus.actionTaken:
        return 'Action Taken';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejectedWithReason:
        return 'Rejected';
      case ComplaintStatus.escalated:
        return 'Escalated to Super Admin';
    }
  }
}

class ComplaintModel {
  final String id;
  final String organizationId;
  final String campaignId;
  final String campaignName;
  final String? relatedRecordId; // paymentId or expenseId
  final ComplaintType type;
  final String title;
  final String description;
  final String submittedById;
  final String submittedByName;
  final String submittedByPhone;
  final DateTime submittedDate;
  final ComplaintStatus status;
  final String? adminResponse;
  final String? resolutionNotes;
  final DateTime? resolvedDate;
  final bool isEscalated;

  const ComplaintModel({
    required this.id,
    required this.organizationId,
    required this.campaignId,
    required this.campaignName,
    this.relatedRecordId,
    required this.type,
    required this.title,
    required this.description,
    required this.submittedById,
    required this.submittedByName,
    required this.submittedByPhone,
    required this.submittedDate,
    this.status = ComplaintStatus.submitted,
    this.adminResponse,
    this.resolutionNotes,
    this.resolvedDate,
    this.isEscalated = false,
  });

  ComplaintModel copyWith({
    String? id,
    String? organizationId,
    String? campaignId,
    String? campaignName,
    String? relatedRecordId,
    ComplaintType? type,
    String? title,
    String? description,
    String? submittedById,
    String? submittedByName,
    String? submittedByPhone,
    DateTime? submittedDate,
    ComplaintStatus? status,
    String? adminResponse,
    String? resolutionNotes,
    DateTime? resolvedDate,
    bool? isEscalated,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      campaignId: campaignId ?? this.campaignId,
      campaignName: campaignName ?? this.campaignName,
      relatedRecordId: relatedRecordId ?? this.relatedRecordId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      submittedById: submittedById ?? this.submittedById,
      submittedByName: submittedByName ?? this.submittedByName,
      submittedByPhone: submittedByPhone ?? this.submittedByPhone,
      submittedDate: submittedDate ?? this.submittedDate,
      status: status ?? this.status,
      adminResponse: adminResponse ?? this.adminResponse,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      isEscalated: isEscalated ?? this.isEscalated,
    );
  }
}
