// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forget_password_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForgetPasswordRequestModel _$ForgetPasswordRequestModelFromJson(
  Map<String, dynamic> json,
) => ForgetPasswordRequestModel(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$ForgetPasswordRequestModelToJson(
  ForgetPasswordRequestModel instance,
) => <String, dynamic>{'email': instance.email, 'password': instance.password};
