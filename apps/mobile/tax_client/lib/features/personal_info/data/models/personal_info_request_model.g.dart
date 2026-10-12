// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_info_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalInfoRequestModel _$PersonalInfoRequestModelFromJson(
  Map<String, dynamic> json,
) => PersonalInfoRequestModel(
  panNumber: json['panNumber'] as String,
  firstName: json['firstName'] as String,
  middleName: json['middleName'] as String,
  lastName: json['lastName'] as String,
  email: json['email'] as String,
  mobileNumber: json['mobileNumber'] as String,
  aadhaarCardNumber: json['aadhaarCardNumber'] as String,
  gender: json['gender'] as String,
  financialYear: json['financialYear'] as String,
  address: json['address'] as String,
  country: json['country'] as String,
  journeyType: json['journeyType'] as String,
  packageId: (json['packageId'] as num?)?.toInt(),
);

Map<String, dynamic> _$PersonalInfoRequestModelToJson(
  PersonalInfoRequestModel instance,
) => <String, dynamic>{
  'panNumber': instance.panNumber,
  'firstName': instance.firstName,
  'middleName': instance.middleName,
  'lastName': instance.lastName,
  'email': instance.email,
  'mobileNumber': instance.mobileNumber,
  'aadhaarCardNumber': instance.aadhaarCardNumber,
  'gender': instance.gender,
  'financialYear': instance.financialYear,
  'address': instance.address,
  'country': instance.country,
  'journeyType': instance.journeyType,
  'packageId': instance.packageId,
};
