class OrganizationModel {
  final String id;
  final String name;
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
    required this.registrationNumber,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.village,
    required this.taluka,
    required this.district,
    required this.state,
    required this.registrationDate,
    this.status = 'Active',
    this.logoUrl,
  });
}
