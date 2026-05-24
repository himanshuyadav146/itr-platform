// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignupData _$SignupDataFromJson(Map<String, dynamic> json) => SignupData(
  message: json['message'] as String,
  userId: (json['userId'] as num?)?.toInt(),
  email: json['email'] as String?,
);

Map<String, dynamic> _$SignupDataToJson(SignupData instance) =>
    <String, dynamic>{
      'message': instance.message,
      'userId': instance.userId,
      'email': instance.email,
    };
