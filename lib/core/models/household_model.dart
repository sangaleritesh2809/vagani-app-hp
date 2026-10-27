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
  final double
      perPersonRateSnapshot; // Preserved snapshot of rate at registration
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
      perPersonRateSnapshot:
          perPersonRateSnapshot ?? this.perPersonRateSnapshot,
      amountReceived: amountReceived ?? this.amountReceived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HouseholdModel.fromJson(Map<String, dynamic> json) {
    return HouseholdModel(
      id: json['id'] as String? ?? '',
      campaignId: json['campaign_id'] as String? ??
          json['campaignId'] as String? ??
          'cmp_ganesh_2026',
      organizationId: json['organization_id'] as String? ??
          json['organizationId'] as String? ??
          'org_001',
      headOfFamilyName: json['head_of_family_name'] as String? ??
          json['headOfFamilyName'] as String? ??
          '',
      mobileNumber: json['mobile_number'] as String? ??
          json['mobileNumber'] as String? ??
          '',
      villageArea: json['village_area'] as String? ??
          json['villageArea'] as String? ??
          '',
      familyMemberCount: (json['family_member_count'] ??
          json['familyMemberCount'] ??
          1) as int,
      perPersonRateSnapshot: ((json['per_person_rate_snapshot'] ??
              json['perPersonRateSnapshot'] ??
              100.0) as num)
          .toDouble(),
      amountReceived:
          ((json['amount_received'] ?? json['amountReceived'] ?? 0.0) as num)
              .toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'organization_id': organizationId,
      'head_of_family_name': headOfFamilyName,
      'mobile_number': mobileNumber,
      'village_area': villageArea,
      'family_member_count': familyMemberCount,
      'per_person_rate_snapshot': perPersonRateSnapshot,
      'amount_received': amountReceived,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
