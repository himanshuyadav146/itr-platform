// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_personal_detail_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetPersonalDetailData _$GetPersonalDetailDataFromJson(
  Map<String, dynamic> json,
) => GetPersonalDetailData(
  userId: (json['UserId'] as num?)?.toInt(),
  firstName: json['FirstName'] as String?,
  middleName: json['MiddleName'] as String?,
  lastName: json['LastName'] as String?,
  panNumber: json['PANNumber'] as String?,
  dateOfBirth: json['DATEOFBIRTH'] as String?,
  address: json['Address'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  pincode: json['pincode'] as String?,
  mobileNumber: json['MobileNumber'] as String?,
  email: json['EMAIL'] as String?,
  aadhaarCardNumber: json['aadharCardNumber'] as String?,
  gender: json['Gender'] as String?,
  financialYear: json['FinancialYear'] as String?,
  country: json['Country'] as String?,
);

Map<String, dynamic> _$GetPersonalDetailDataToJson(
  GetPersonalDetailData instance,
) => <String, dynamic>{
  'UserId': instance.userId,
  'FirstName': instance.firstName,
  'MiddleName': instance.middleName,
  'LastName': instance.lastName,
  'PANNumber': instance.panNumber,
  'DATEOFBIRTH': instance.dateOfBirth,
  'Address': instance.address,
  'city': instance.city,
  'state': instance.state,
  'pincode': instance.pincode,
  'MobileNumber': instance.mobileNumber,
  'EMAIL': instance.email,
  'aadharCardNumber': instance.aadhaarCardNumber,
  'Gender': instance.gender,
  'FinancialYear': instance.financialYear,
  'Country': instance.country,
};
