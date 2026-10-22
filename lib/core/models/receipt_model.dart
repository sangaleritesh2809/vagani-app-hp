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
}
