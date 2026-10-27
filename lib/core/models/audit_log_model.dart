class AuditLogModel {
  final String id;
  final String organizationId;
  final String
      entityType; // Campaign, Household, Payment, Handover, Expense, Complaint
  final String entityId;
  final String
      action; // CREATE, UPDATE_RATE, CANCEL_RECEIPT, CONFIRM_HANDOVER, APPROVE_EXPENSE, ESCALATE
  final String performedById;
  final String performedByName;
  final DateTime timestamp;
  final String details;

  const AuditLogModel({
    required this.id,
    required this.organizationId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.performedById,
    required this.performedByName,
    required this.timestamp,
    required this.details,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ??
          json['organizationId'] as String? ??
          'org_001',
      entityType: json['entity_type'] as String? ??
          json['entityType'] as String? ??
          'System',
      entityId:
          json['entity_id'] as String? ?? json['entityId'] as String? ?? '',
      action: json['action'] as String? ?? '',
      performedById: json['performed_by_id'] as String? ??
          json['performedById'] as String? ??
          '',
      performedByName: json['performed_by_name'] as String? ??
          json['performedByName'] as String? ??
          '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      details: json['details'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'performed_by_id': performedById,
      'performed_by_name': performedByName,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}
