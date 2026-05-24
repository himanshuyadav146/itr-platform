// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginData _$LoginDataFromJson(Map<String, dynamic> json) => LoginData(
  message: json['message'] as String,
  userId: json['UserId'] as String?,
  email: json['email'] as String,
  token: json['token'] as String,
  firstName: json['firstName'] as String?,
  middleName: json['middleName'] as String?,
  lastName: json['lastName'] as String?,
  mobile: json['mobile'] as String?,
);

Map<String, dynamic> _$LoginDataToJson(LoginData instance) => <String, dynamic>{
  'message': instance.message,
  'UserId': instance.userId,
  'email': instance.email,
  'token': instance.token,
  'firstName': instance.firstName,
  'middleName': instance.middleName,
  'lastName': instance.lastName,
  'mobile': instance.mobile,
};
