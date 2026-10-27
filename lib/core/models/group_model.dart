class GroupModel {
  final String id;
  final String organizationId;
  final String name;
  final String code;
  final String description;
  final String location;
  final String status;
  final Map<String, dynamic> contributionSettings;

  const GroupModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.description,
    this.location = '',
    this.status = 'active',
    this.contributionSettings = const {
      'suggested_amount': 100,
      'allow_partial': true,
      'per_person_rate': 100,
    },
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isArchived => status.toLowerCase() == 'archived';

  double get perPersonRate {
    final rate = contributionSettings['per_person_rate'];
    if (rate is num) return rate.toDouble();
    return 100.0;
  }

  double get suggestedAmount {
    final amt = contributionSettings['suggested_amount'];
    if (amt is num) return amt.toDouble();
    return 100.0;
  }

  bool get allowPartial {
    final p = contributionSettings['allow_partial'];
    if (p is bool) return p;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'code': code,
      'description': description,
      'location': location,
      'status': status,
      'contribution_settings': contributionSettings,
    };
  }

  /// Sanitized payload matching columns in public.groups table
  Map<String, dynamic> toSupabaseJson() {
    final map = <String, dynamic>{
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'description': description.trim(),
      'location': location.trim(),
      'status': status,
      'contribution_settings': contributionSettings,
    };
    if (RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(id)) {
      map['id'] = id;
    }
    if (RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(organizationId)) {
      map['organization_id'] = organizationId;
    }
    return map;
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> settings = {
      'suggested_amount': 100,
      'allow_partial': true,
      'per_person_rate': 100,
    };
    if (json['contribution_settings'] is Map) {
      settings =
          Map<String, dynamic>.from(json['contribution_settings'] as Map);
    }

    return GroupModel(
      id: json['id'] as String? ?? '',
      organizationId:
          (json['organization_id'] ?? json['organizationId']) as String? ??
              'org_001',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      contributionSettings: settings,
    );
  }

  GroupModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? code,
    String? description,
    String? location,
    String? status,
    Map<String, dynamic>? contributionSettings,
  }) {
    return GroupModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      contributionSettings: contributionSettings ?? this.contributionSettings,
    );
  }
}
