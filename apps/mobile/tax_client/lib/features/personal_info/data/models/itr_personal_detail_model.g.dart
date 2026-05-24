// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itr_personal_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItrPersonalDetailModel _$ItrPersonalDetailModelFromJson(
  Map<String, dynamic> json,
) => ItrPersonalDetailModel(
  id: json['id'] as String,
  itrId: json['itrId'] as String?,
  userId: json['UserId'] as String,
  panNumber: json['PANNumber'] as String,
  firstName: json['FirstName'] as String,
  middleName: json['MiddleName'] as String?,
  lastName: json['LastName'] as String,
  email: json['EMAIL'] as String,
  mobileNumber: json['MobileNumber'] as String,
  aadharCardNumber: json['aadharCardNumber'] as String,
  gender: json['Gender'] as String,
  dateOfBirth: json['DATEOFBIRTH'] as String?,
  financialYear: json['FinancialYear'] as String,
  address: json['Address'] as String,
  country: json['Country'] as String,
  isActive: json['isActive'] as String,
  createdAt: json['createdAt'] as String,
  createdBy: json['createdBy'] as String?,
  updatedAt: json['updatedAt'] as String?,
  updatedBy: json['updatedBy'] as String?,
  documents: (json['documents'] as List<dynamic>?)
      ?.map((e) => ItrDocumentModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  documentCount: (json['documentCount'] as num?)?.toInt(),
  packageId: (json['packageId'] as num?)?.toInt(),
  packageName: json['packageName'] as String?,
  paymentStatus: json['paymentStatus'] as String?,
  itrStatus: json['itrStatus'] as String?,
  statusDisplayText: json['statusDisplayText'] as String?,
);

Map<String, dynamic> _$ItrPersonalDetailModelToJson(
  ItrPersonalDetailModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'itrId': instance.itrId,
  'UserId': instance.userId,
  'PANNumber': instance.panNumber,
  'FirstName': instance.firstName,
  'MiddleName': instance.middleName,
  'LastName': instance.lastName,
  'EMAIL': instance.email,
  'MobileNumber': instance.mobileNumber,
  'aadharCardNumber': instance.aadharCardNumber,
  'Gender': instance.gender,
  'DATEOFBIRTH': instance.dateOfBirth,
  'FinancialYear': instance.financialYear,
  'Address': instance.address,
  'Country': instance.country,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt,
  'createdBy': instance.createdBy,
  'updatedAt': instance.updatedAt,
  'updatedBy': instance.updatedBy,
  'documents': instance.documents,
  'documentCount': instance.documentCount,
  'packageId': instance.packageId,
  'packageName': instance.packageName,
  'paymentStatus': instance.paymentStatus,
  'itrStatus': instance.itrStatus,
  'statusDisplayText': instance.statusDisplayText,
};
