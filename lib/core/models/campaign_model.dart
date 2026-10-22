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
        return 'Ganeshotsav (गणेशोत्सव)';
      case VarganiType.shivjayanti:
        return 'Shivjayanti (शिवजयंती)';
      case VarganiType.navratri:
        return 'Navratri (नवरात्री उत्सव)';
      case VarganiType.villageFair:
        return 'Village Fair / Yatra (ग्राम यात्रा / जत्रा)';
      case VarganiType.templeProgram:
        return 'Temple Program (मंदिर उत्सव)';
      case VarganiType.sportsEvent:
        return 'Sports Event (क्रीडा स्पर्धा)';
      case VarganiType.villageDevelopment:
        return 'Village Development (ग्राम विकास निधी)';
      case VarganiType.socialProgram:
        return 'Social Program (सामाजिक उपक्रम)';
      case VarganiType.custom:
        return 'Custom Festival / Event (इतर)';
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
}
