enum PaymentStatus {
  pending,
  partiallyPaid,
  paid,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';
      case PaymentStatus.paid:
        return 'Paid';
    }
  }

  String get localizedKey {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.partiallyPaid:
        return 'partiallyPaid';
      case PaymentStatus.paid:
        return 'paid';
    }
  }
}

class HouseholdModel {
  final String id;
  final String campaignId;
  final String organizationId;
  final String headOfFamilyName;
  final String mobileNumber;
  final String villageArea;
  final int familyMemberCount;
  final double perPersonRateSnapshot; // Preserved snapshot of rate at registration
  final double amountReceived;
  final DateTime createdAt;

  const HouseholdModel({
    required this.id,
    required this.campaignId,
    required this.organizationId,
    required this.headOfFamilyName,
    required this.mobileNumber,
    required this.villageArea,
    required this.familyMemberCount,
    required this.perPersonRateSnapshot,
    this.amountReceived = 0.0,
    required this.createdAt,
  });

  // Expected Total Vargani = Family Member Count × Configured Per-Person Amount (SRS 5.3)
  double get expectedTotalVargani => familyMemberCount * perPersonRateSnapshot;

  // Remaining Amount = Expected Total Vargani − Sum of Verified Payments, minimum 0 (SRS 6.2)
  double get remainingAmount {
    final diff = expectedTotalVargani - amountReceived;
    return diff > 0 ? diff : 0.0;
  }

  // Payment Status (SRS 6.2)
  PaymentStatus get paymentStatus {
    if (amountReceived <= 0.0) {
      return PaymentStatus.pending;
    } else if (amountReceived < expectedTotalVargani) {
      return PaymentStatus.partiallyPaid;
    } else {
      return PaymentStatus.paid;
    }
  }

  HouseholdModel copyWith({
    String? id,
    String? campaignId,
    String? organizationId,
    String? headOfFamilyName,
    String? mobileNumber,
    String? villageArea,
    int? familyMemberCount,
    double? perPersonRateSnapshot,
    double? amountReceived,
    DateTime? createdAt,
  }) {
    return HouseholdModel(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      organizationId: organizationId ?? this.organizationId,
      headOfFamilyName: headOfFamilyName ?? this.headOfFamilyName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      villageArea: villageArea ?? this.villageArea,
      familyMemberCount: familyMemberCount ?? this.familyMemberCount,
      perPersonRateSnapshot: perPersonRateSnapshot ?? this.perPersonRateSnapshot,
      amountReceived: amountReceived ?? this.amountReceived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
