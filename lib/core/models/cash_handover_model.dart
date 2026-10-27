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

  factory CashHandoverModel.fromJson(Map<String, dynamic> json) {
    HandoverStatus hStatus = HandoverStatus.pending;
    final statusStr = (json['status'] ?? 'pending').toString().toLowerCase();
    for (final s in HandoverStatus.values) {
      if (s.name.toLowerCase() == statusStr) {
        hStatus = s;
        break;
      }
    }

    return CashHandoverModel(
      id: json['id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ??
          json['organizationId'] as String? ??
          'org_001',
      campaignId: json['campaign_id'] as String? ??
          json['campaignId'] as String? ??
          'cmp_ganesh_2026',
      handoverFromId: json['handover_from_id'] as String? ??
          json['handoverFromId'] as String? ??
          'usr_collector',
      handoverFromName: json['handover_from_name'] as String? ??
          json['handoverFromName'] as String? ??
          '',
      handoverToId: json['handover_to_id'] as String? ??
          json['handoverToId'] as String? ??
          'usr_treasurer',
      handoverToName: json['handover_to_name'] as String? ??
          json['handoverToName'] as String? ??
          '',
      amount: ((json['amount'] ?? 0.0) as num).toDouble(),
      dateTime: json['date_time'] != null
          ? DateTime.tryParse(json['date_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      remarks: json['remarks'] as String? ?? '',
      status: hStatus,
      confirmedById: json['confirmed_by_id'] as String? ??
          json['confirmedById'] as String?,
      confirmedByName: json['confirmed_by_name'] as String? ??
          json['confirmedByName'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.tryParse(json['confirmed_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'handover_from_name': handoverFromName,
      'handover_to_name': handoverToName,
      'amount': amount,
      'remarks': remarks,
      'status': status.name,
    };
  }
}
