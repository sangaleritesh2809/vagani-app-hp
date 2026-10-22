enum HandoverStatus {
  pending,
  confirmed,
  rejected,
}

extension HandoverStatusExtension on HandoverStatus {
  String get displayName {
    switch (this) {
      case HandoverStatus.pending:
        return 'Pending Confirmation';
      case HandoverStatus.confirmed:
        return 'Confirmed / Received';
      case HandoverStatus.rejected:
        return 'Rejected';
    }
  }
}

class CashHandoverModel {
  final String id;
  final String organizationId;
  final String campaignId;
  final String handoverFromId;
  final String handoverFromName;
  final String handoverToId;
  final String handoverToName;
  final double amount;
  final DateTime dateTime;
  final String remarks;
  final HandoverStatus status;
  final String? confirmedById;
  final String? confirmedByName;
  final DateTime? confirmedAt;

  const CashHandoverModel({
    required this.id,
    required this.organizationId,
    required this.campaignId,
    required this.handoverFromId,
    required this.handoverFromName,
    required this.handoverToId,
    required this.handoverToName,
    required this.amount,
    required this.dateTime,
    this.remarks = '',
    this.status = HandoverStatus.pending,
    this.confirmedById,
    this.confirmedByName,
    this.confirmedAt,
  });

  CashHandoverModel copyWith({
    String? id,
    String? organizationId,
    String? campaignId,
    String? handoverFromId,
    String? handoverFromName,
    String? handoverToId,
    String? handoverToName,
    double? amount,
    DateTime? dateTime,
    String? remarks,
    HandoverStatus? status,
    String? confirmedById,
    String? confirmedByName,
    DateTime? confirmedAt,
  }) {
    return CashHandoverModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      campaignId: campaignId ?? this.campaignId,
      handoverFromId: handoverFromId ?? this.handoverFromId,
      handoverFromName: handoverFromName ?? this.handoverFromName,
      handoverToId: handoverToId ?? this.handoverToId,
      handoverToName: handoverToName ?? this.handoverToName,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      confirmedById: confirmedById ?? this.confirmedById,
      confirmedByName: confirmedByName ?? this.confirmedByName,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}
