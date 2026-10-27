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
        return 'Collection Discrepancy';
      case ComplaintType.receiptIssue:
        return 'Receipt Issue';
      case ComplaintType.expenseAudit:
        return 'Expense Question / Audit';
      case ComplaintType.generalInquiry:
        return 'General Feedback / Inquiry';
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

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    ComplaintType cType = ComplaintType.generalInquiry;
    final typeStr = (json['type'] ?? '').toString().toLowerCase();
    for (final t in ComplaintType.values) {
      if (t.name.toLowerCase() == typeStr) {
        cType = t;
        break;
      }
    }

    ComplaintStatus cStatus = ComplaintStatus.submitted;
    final sStr = (json['status'] ?? 'submitted').toString().toLowerCase();
    for (final s in ComplaintStatus.values) {
      if (s.name.toLowerCase() == sStr) {
        cStatus = s;
        break;
      }
    }

    return ComplaintModel(
      id: json['id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ??
          json['organizationId'] as String? ??
          'org_001',
      campaignId: json['campaign_id'] as String? ??
          json['campaignId'] as String? ??
          'cmp_ganesh_2026',
      campaignName: json['campaign_name'] as String? ??
          json['campaignName'] as String? ??
          'Ganeshotsav 2026',
      relatedRecordId: json['related_record_id'] as String? ??
          json['relatedRecordId'] as String?,
      type: cType,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      submittedById: json['submitted_by_id'] as String? ??
          json['submittedById'] as String? ??
          'usr_citizen',
      submittedByName: json['submitted_by_name'] as String? ??
          json['submittedByName'] as String? ??
          '',
      submittedByPhone: json['submitted_by_phone'] as String? ??
          json['submittedByPhone'] as String? ??
          '',
      submittedDate: json['submitted_date'] != null
          ? DateTime.tryParse(json['submitted_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      status: cStatus,
      adminResponse:
          json['admin_response'] as String? ?? json['adminResponse'] as String?,
      resolutionNotes: json['resolution_notes'] as String? ??
          json['resolutionNotes'] as String?,
      resolvedDate: json['resolved_date'] != null
          ? DateTime.tryParse(json['resolved_date'].toString())
          : null,
      isEscalated: json['is_escalated'] == true || json['isEscalated'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'type': type.name,
      'title': title,
      'description': description,
      'submitted_by_name': submittedByName,
      'submitted_by_phone': submittedByPhone,
      'status': status.name,
      'admin_response': adminResponse,
    };
  }
}
