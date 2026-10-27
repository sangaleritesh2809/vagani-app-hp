class OrganizationModel {
  final String id;
  final String name;
  final String slug;
  final String organizationType;
  final String description;
  final String registrationNumber;
  final String contactPerson;
  final String phone;
  final String address;
  final String village;
  final String taluka;
  final String district;
  final String state;
  final DateTime registrationDate;
  final String status;
  final String? logoUrl;

  const OrganizationModel({
    required this.id,
    required this.name,
    String? slug,
    this.organizationType = 'Festival Committee',
    this.description = '',
    this.registrationNumber = '',
    this.contactPerson = '',
    this.phone = '',
    this.address = '',
    this.village = '',
    this.taluka = '',
    this.district = '',
    this.state = 'Maharashtra',
    required this.registrationDate,
    this.status = 'active',
    this.logoUrl,
  }) : slug = slug ?? '';

  bool get isActive => status.toLowerCase() == 'active';
  bool get isArchived => status.toLowerCase() == 'archived';

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    final nameStr = json['name'] as String? ?? '';
    final slugStr = json['slug'] as String? ??
        nameStr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    return OrganizationModel(
      id: json['id'] as String? ?? 'org_001',
      name: nameStr,
      slug: slugStr,
      organizationType: json['organization_type'] as String? ??
          json['organizationType'] as String? ??
          'Festival Committee',
      description: json['description'] as String? ?? '',
      registrationNumber: json['registration_number'] as String? ??
          json['registrationNumber'] as String? ??
          '',
      contactPerson: json['contact_person'] as String? ??
          json['contactPerson'] as String? ??
          '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      village: json['village'] as String? ?? '',
      taluka: json['taluka'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? 'Maharashtra',
      registrationDate: json['registration_date'] != null
          ? DateTime.tryParse(json['registration_date'].toString()) ??
              DateTime(2018, 5, 12)
          : DateTime(2018, 5, 12),
      status: json['status'] as String? ?? 'active',
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug.isNotEmpty
          ? slug
          : name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      'organization_type': organizationType,
      'organizationType': organizationType,
      'description': description,
      'registrationNumber': registrationNumber,
      'registration_number': registrationNumber,
      'contactPerson': contactPerson,
      'contact_person': contactPerson,
      'phone': phone,
      'address': address,
      'village': village,
      'taluka': taluka,
      'district': district,
      'state': state,
      'registrationDate': registrationDate.toIso8601String(),
      'registration_date': registrationDate.toIso8601String(),
      'status': status,
      'logoUrl': logoUrl,
    };
  }

  /// Sanitized payload matching exact columns in public.organizations table
  Map<String, dynamic> toSupabaseJson() {
    final map = <String, dynamic>{
      'name': name.trim(),
      'registration_number': registrationNumber.isNotEmpty
          ? registrationNumber.trim()
          : (organizationType.isNotEmpty ? organizationType : 'Festival Committee'),
      'contact_person':
          contactPerson.isNotEmpty ? contactPerson.trim() : 'Admin',
      'address': address.isNotEmpty
          ? address.trim()
          : (description.isNotEmpty ? description.trim() : 'Main Area'),
      'village': village.isNotEmpty ? village.trim() : 'Town',
      'taluka': taluka.isNotEmpty
          ? taluka.trim()
          : (district.isNotEmpty ? district.trim() : 'Taluka'),
      'district': district.isNotEmpty ? district.trim() : 'District',
      'state': state.isNotEmpty ? state.trim() : 'Maharashtra',
      'phone': phone.isNotEmpty ? phone.trim() : '9800000000',
      'registration_date': registrationDate.toIso8601String().split('T').first,
      'status': status,
    };
    if (RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(id)) {
      map['id'] = id;
    }
    return map;
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? organizationType,
    String? description,
    String? registrationNumber,
    String? contactPerson,
    String? phone,
    String? address,
    String? village,
    String? taluka,
    String? district,
    String? state,
    DateTime? registrationDate,
    String? status,
    String? logoUrl,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      organizationType: organizationType ?? this.organizationType,
      description: description ?? this.description,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      village: village ?? this.village,
      taluka: taluka ?? this.taluka,
      district: district ?? this.district,
      state: state ?? this.state,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
