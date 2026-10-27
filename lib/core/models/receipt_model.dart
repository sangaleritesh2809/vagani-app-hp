import 'payment_model.dart';

class ReceiptModel {
  final String id;
  final String receiptNo; // e.g. VRG-2026-0001
  final String organizationId;
  final String campaignId;
  final String campaignName;
  final String householdId;
  final String householdHeadName;
  final int familyMemberCount;
  final double perPersonRate;
  final double amountReceived;
  final PaymentType paymentType;
  final String? referenceId;
  final String collectedByName;
  final String receivedByName;
  final DateTime issuedAt;
  final bool isCancelled;
  final String? cancellationReason;
  final String? cancelledByName;
  final DateTime? cancelledAt;

  const ReceiptModel({
    required this.id,
    required this.receiptNo,
    required this.organizationId,
    required this.campaignId,
    required this.campaignName,
    required this.householdId,
    required this.householdHeadName,
    required this.familyMemberCount,
    required this.perPersonRate,
    required this.amountReceived,
    required this.paymentType,
    this.referenceId,
    required this.collectedByName,
    required this.receivedByName,
    required this.issuedAt,
    this.isCancelled = false,
    this.cancellationReason,
    this.cancelledByName,
    this.cancelledAt,
  });

  ReceiptModel cancel({
    required String reason,
    required String cancelledByName,
    required DateTime cancelledAt,
  }) {
    return ReceiptModel(
      id: id,
      receiptNo: receiptNo,
      organizationId: organizationId,
      campaignId: campaignId,
      campaignName: campaignName,
      householdId: householdId,
      householdHeadName: householdHeadName,
      familyMemberCount: familyMemberCount,
      perPersonRate: perPersonRate,
      amountReceived: amountReceived,
      paymentType: paymentType,
      referenceId: referenceId,
      collectedByName: collectedByName,
      receivedByName: receivedByName,
      issuedAt: issuedAt,
      isCancelled: true,
      cancellationReason: reason,
      cancelledByName: cancelledByName,
      cancelledAt: cancelledAt,
    );
  }

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
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

    return ReceiptModel(
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
      familyMemberCount: (json['family_member_count'] ??
          json['familyMemberCount'] ??
          1) as int,
      perPersonRate:
          ((json['per_person_rate'] ?? json['perPersonRate'] ?? 100.0) as num)
              .toDouble(),
      amountReceived: ((json['amount_received'] ??
              json['amountReceived'] ??
              json['amount'] ??
              0.0) as num)
          .toDouble(),
      paymentType: pType,
      referenceId:
          json['reference_id'] as String? ?? json['referenceId'] as String?,
      collectedByName: json['collected_by_name'] as String? ??
          json['collectedByName'] as String? ??
          '',
      receivedByName: json['received_by_name'] as String? ??
          json['receivedByName'] as String? ??
          '',
      issuedAt: json['issued_at'] != null
          ? DateTime.tryParse(json['issued_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isCancelled: json['is_cancelled'] == true || json['isCancelled'] == true,
      cancellationReason: json['cancellation_reason'] as String? ??
          json['cancellationReason'] as String?,
      cancelledByName: json['cancelled_by_name'] as String? ??
          json['cancelledByName'] as String?,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.tryParse(json['cancelled_at'].toString())
          : null,
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
      'family_member_count': familyMemberCount,
      'per_person_rate': perPersonRate,
      'amount_received': amountReceived,
      'payment_type': paymentType.name,
      'reference_id': referenceId,
      'collected_by_name': collectedByName,
      'received_by_name': receivedByName,
      'issued_at': issuedAt.toIso8601String(),
      'is_cancelled': isCancelled,
      'cancellation_reason': cancellationReason,
      'cancelled_by_name': cancelledByName,
    };
  }
}
