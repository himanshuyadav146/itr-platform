class AssociateServiceFee {
  final int serviceId;
  final String serviceName;
  final String serviceDescription;
  final double? listedFee;
  final bool isActive;

  AssociateServiceFee({
    required this.serviceId,
    required this.serviceName,
    this.serviceDescription = '',
    this.listedFee,
    this.isActive = true,
  });

  factory AssociateServiceFee.fromJson(Map<String, dynamic> json) {
    return AssociateServiceFee(
      serviceId: (json['service_id'] as num?)?.toInt() ?? 0,
      serviceName: (json['service_name'] ?? json['name'] ?? '').toString(),
      serviceDescription: (json['service_description'] ?? json['description'] ?? '').toString(),
      listedFee: json['listed_fee'] == null
          ? null
          : (json['listed_fee'] as num).toDouble(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

class AssociateProfile {
  final int id;
  final String name;
  final String role;
  final String city;
  final String state;
  final String bio;
  final String icaiMembershipNo;
  final int yearsExperience;
  final List<AssociateServiceFee> services;

  AssociateProfile({
    required this.id,
    required this.name,
    required this.role,
    this.city = '',
    this.state = '',
    this.bio = '',
    this.icaiMembershipNo = '',
    this.yearsExperience = 0,
    this.services = const [],
  });

  factory AssociateProfile.fromJson(Map<String, dynamic> json) {
    final servicesJson = json['services'];
    return AssociateProfile(
      id: (json['user_id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      icaiMembershipNo: (json['icai_membership_no'] ?? '').toString(),
      yearsExperience: (json['years_experience'] as num?)?.toInt() ?? 0,
      services: servicesJson is List
          ? servicesJson
              .whereType<Map>()
              .map((item) => AssociateServiceFee.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }
}

class CatalogService {
  final int id;
  final String name;
  final String description;

  CatalogService({required this.id, required this.name, this.description = ''});

  factory CatalogService.fromJson(Map<String, dynamic> json) {
    return CatalogService(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}
