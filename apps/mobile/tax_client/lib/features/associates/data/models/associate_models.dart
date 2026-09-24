class CatalogService {
  final int id;
  final String name;
  final String description;

  CatalogService({
    required this.id,
    required this.name,
    required this.description,
  });

  factory CatalogService.fromJson(Map<String, dynamic> json) {
    return CatalogService(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class AssociateServiceFee {
  final int serviceId;
  final String serviceName;
  final String description;
  final double fee;
  final bool isActive;

  AssociateServiceFee({
    required this.serviceId,
    required this.serviceName,
    required this.description,
    required this.fee,
    required this.isActive,
  });

  factory AssociateServiceFee.fromJson(Map<String, dynamic> json) {
    return AssociateServiceFee(
      serviceId: int.tryParse('${json['serviceId'] ?? json['service_id']}') ?? 0,
      serviceName: (json['serviceName'] ?? json['service_name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fee: double.tryParse('${json['fee'] ?? 0}') ?? 0,
      isActive: json['isActive'] == true || json['isActive'] == 1,
    );
  }
}

class AssociateModel {
  final int id;
  final String name;
  final String role;
  final String bio;
  final int yearsExperience;
  final String qualification;
  final String licenseNumber;
  final String city;
  final List<String> languages;
  final double? listedFee;
  final int? serviceId;
  final String? serviceName;
  final List<AssociateServiceFee> services;

  AssociateModel({
    required this.id,
    required this.name,
    required this.role,
    required this.bio,
    required this.yearsExperience,
    required this.qualification,
    required this.licenseNumber,
    required this.city,
    required this.languages,
    this.listedFee,
    this.serviceId,
    this.serviceName,
    required this.services,
  });

  factory AssociateModel.fromJson(Map<String, dynamic> json) {
    final servicesJson = json['services'];
    return AssociateModel(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      yearsExperience: int.tryParse('${json['yearsExperience'] ?? 0}') ?? 0,
      qualification: (json['qualification'] ?? '').toString(),
      licenseNumber: (json['licenseNumber'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      languages: (json['languages'] is List)
          ? (json['languages'] as List).map((e) => e.toString()).toList()
          : const [],
      listedFee: json['listedFee'] != null
          ? double.tryParse('${json['listedFee']}')
          : null,
      serviceId: json['serviceId'] != null
          ? int.tryParse('${json['serviceId']}')
          : null,
      serviceName: json['serviceName']?.toString(),
      services: servicesJson is List
          ? servicesJson
                .map((item) => AssociateServiceFee.fromJson(
                      item as Map<String, dynamic>,
                    ))
                .toList()
          : const [],
    );
  }
}

class AssociateSelection {
  final int associateId;
  final String associateName;
  final String role;
  final int serviceId;
  final String serviceName;
  final double quotedFee;
  final String city;
  final int yearsExperience;

  const AssociateSelection({
    required this.associateId,
    required this.associateName,
    required this.role,
    required this.serviceId,
    required this.serviceName,
    required this.quotedFee,
    required this.city,
    required this.yearsExperience,
  });
}
