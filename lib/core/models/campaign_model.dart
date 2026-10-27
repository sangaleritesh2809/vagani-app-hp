enum VarganiType {
  ganeshotsav,
  shivjayanti,
  navratri,
  villageFair,
  templeProgram,
  sportsEvent,
  villageDevelopment,
  socialProgram,
  custom,
}

extension VarganiTypeExtension on VarganiType {
  String get displayName {
    switch (this) {
      case VarganiType.ganeshotsav:
        return 'Ganeshotsav';
      case VarganiType.shivjayanti:
        return 'Shiv Jayanti';
      case VarganiType.navratri:
        return 'Navratri Festival';
      case VarganiType.villageFair:
        return 'Village Fair / Yatra';
      case VarganiType.templeProgram:
        return 'Temple Festival';
      case VarganiType.sportsEvent:
        return 'Sports Event';
      case VarganiType.villageDevelopment:
        return 'Village Development Fund';
      case VarganiType.socialProgram:
        return 'Social Initiative';
      case VarganiType.custom:
        return 'Custom Festival / Other';
    }
  }
}

class CampaignModel {
  final String id;
  final String organizationId;
  final String name;
  final VarganiType varganiType;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double targetAmount;
  final double perPersonRate; // e.g. 100 INR per family member
  final double suggestedAmount;
  final bool allowPartialPayment;
  final String status; // Active, Completed, Inactive
  final DateTime rateEffectiveDate;

  const CampaignModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.varganiType,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.targetAmount,
    required this.perPersonRate,
    this.suggestedAmount = 0.0,
    this.allowPartialPayment = true,
    this.status = 'Active',
    required this.rateEffectiveDate,
  });

  CampaignModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    VarganiType? varganiType,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? targetAmount,
    double? perPersonRate,
    double? suggestedAmount,
    bool? allowPartialPayment,
    String? status,
    DateTime? rateEffectiveDate,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      varganiType: varganiType ?? this.varganiType,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetAmount: targetAmount ?? this.targetAmount,
      perPersonRate: perPersonRate ?? this.perPersonRate,
      suggestedAmount: suggestedAmount ?? this.suggestedAmount,
      allowPartialPayment: allowPartialPayment ?? this.allowPartialPayment,
      status: status ?? this.status,
      rateEffectiveDate: rateEffectiveDate ?? this.rateEffectiveDate,
    );
  }

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    VarganiType type = VarganiType.ganeshotsav;
    final typeStr = (json['vargani_type'] ?? json['varganiType'] ?? '')
        .toString()
        .toLowerCase();
    for (final t in VarganiType.values) {
      if (typeStr.contains(t.name.toLowerCase())) {
        type = t;
        break;
      }
    }

    return CampaignModel(
      id: json['id'] as String? ?? 'cmp_ganesh_2026',
      organizationId: json['organization_id'] as String? ??
          json['organizationId'] as String? ??
          'org_001',
      name: json['name'] as String? ?? 'Ganeshotsav 2026',
      varganiType: type,
      description: json['description'] as String? ?? '',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString()) ??
              DateTime(2026, 9, 1)
          : DateTime(2026, 9, 1),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString()) ??
              DateTime(2026, 9, 11)
          : DateTime(2026, 9, 11),
      targetAmount:
          ((json['target_amount'] ?? json['targetAmount'] ?? 500000.0) as num)
              .toDouble(),
      perPersonRate:
          ((json['per_person_rate'] ?? json['perPersonRate'] ?? 100.0) as num)
              .toDouble(),
      suggestedAmount:
          ((json['suggested_amount'] ?? json['suggestedAmount'] ?? 0.0) as num)
              .toDouble(),
      allowPartialPayment:
          json['allow_partial_payment'] ?? json['allowPartialPayment'] ?? true,
      status: json['status'] as String? ?? 'Active',
      rateEffectiveDate: json['rate_effective_date'] != null
          ? DateTime.tryParse(json['rate_effective_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'vargani_type': varganiType.name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_amount': targetAmount,
      'per_person_rate': perPersonRate,
      'suggested_amount': suggestedAmount,
      'allow_partial_payment': allowPartialPayment,
      'status': status,
      'rate_effective_date': rateEffectiveDate.toIso8601String(),
    };
  }
}
