class AuditLogModel {
  final String id;
  final String organizationId;
  final String entityType; // Campaign, Household, Payment, Handover, Expense, Complaint
  final String entityId;
  final String action; // CREATE, UPDATE_RATE, CANCEL_RECEIPT, CONFIRM_HANDOVER, APPROVE_EXPENSE, ESCALATE
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
}
