enum PaymentType {
  cash,
  upi,
  bankTransfer,
  other,
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.cash:
        return 'Cash';
      case PaymentType.upi:
        return 'UPI / QR';
      case PaymentType.bankTransfer:
        return 'Bank Transfer / NEFT';
      case PaymentType.other:
        return 'Other';
    }
  }

  String get localizedKey {
    switch (this) {
      case PaymentType.cash:
        return 'cash';
      case PaymentType.upi:
        return 'upi';
      case PaymentType.bankTransfer:
        return 'bankTransfer';
      case PaymentType.other:
        return 'other';
    }
  }
}

enum VerificationStatus {
  verified,
  pending,
  failed,
}

class PaymentModel {
  final String id;
  final String receiptNo; // e.g. VRG-2026-0001
  final String organizationId;
  final String campaignId;
  final String campaignName;
  final String householdId;
  final String householdHeadName;
  final double amount;
  final PaymentType paymentType;
  final String? referenceId; // UPI UTR or bank transaction reference
  final String collectedById;
  final String collectedByName;
  final String receivedById;
  final String receivedByName;
  final VerificationStatus verificationStatus;
  final DateTime collectionDateTime;
  final String remarks;

  const PaymentModel({
    required this.id,
    required this.receiptNo,
    required this.organizationId,
    required this.campaignId,
    required this.campaignName,
    required this.householdId,
    required this.householdHeadName,
    required this.amount,
    required this.paymentType,
    this.referenceId,
    required this.collectedById,
    required this.collectedByName,
    required this.receivedById,
    required this.receivedByName,
    this.verificationStatus = VerificationStatus.verified,
    required this.collectionDateTime,
    this.remarks = '',
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    PaymentType pType = PaymentType.cash;
    final typeStr = (json['payment_type'] ?? json['paymentType'] ?? 'cash')
        .toString()
        .toLowerCase();
    for (final t in PaymentType.values) {
      if (t.name.toLowerCase() == typeStr) {
        pType = t;
        break;
      }
    }

    return PaymentModel(
      id: json['id'] as String? ?? '',
      receiptNo:
          json['receipt_no'] as String? ?? json['receiptNo'] as String? ?? '',
      organizationId: json['organization_id'] as String? ??
          json['organizationId'] as String? ??
          'org_001',
      campaignId: json['campaign_id'] as String? ??
          json['campaignId'] as String? ??
          'cmp_ganesh_2026',
      campaignName: json['campaign_name'] as String? ??
          json['campaignName'] as String? ??
          'Ganeshotsav 2026',
      householdId: json['household_id'] as String? ??
          json['householdId'] as String? ??
          '',
      householdHeadName: json['household_head_name'] as String? ??
          json['householdHeadName'] as String? ??
          '',
      amount: ((json['amount'] ?? 0.0) as num).toDouble(),
      paymentType: pType,
      referenceId:
          json['reference_id'] as String? ?? json['referenceId'] as String?,
      collectedById: json['collected_by_id'] as String? ??
          json['collectedById'] as String? ??
          'usr_collector',
      collectedByName: json['collected_by_name'] as String? ??
          json['collectedByName'] as String? ??
          '',
      receivedById: json['received_by_id'] as String? ??
          json['receivedById'] as String? ??
          'usr_treasurer',
      receivedByName: json['received_by_name'] as String? ??
          json['receivedByName'] as String? ??
          '',
      verificationStatus: VerificationStatus.verified,
      collectionDateTime: json['collection_date_time'] != null
          ? DateTime.tryParse(json['collection_date_time'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      remarks: json['remarks'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receipt_no': receiptNo,
      'organization_id': organizationId,
      'campaign_id': campaignId,
      'campaign_name': campaignName,
      'household_id': householdId,
      'household_head_name': householdHeadName,
      'amount': amount,
      'payment_type': paymentType.name,
      'reference_id': referenceId,
      'collected_by_id': collectedById,
      'collected_by_name': collectedByName,
      'received_by_id': receivedById,
      'received_by_name': receivedByName,
      'remarks': remarks,
    };
  }
}
