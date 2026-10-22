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
}
