// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_token_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshTokenData _$RefreshTokenDataFromJson(Map<String, dynamic> json) =>
    RefreshTokenData(
      message: json['message'] as String,
      token: json['token'] as String,
      userId: (json['userId'] as num?)?.toInt(),
      email: json['email'] as String?,
      name: json['name'] as String?,
      mobile: json['mobile'] as String?,
    );

Map<String, dynamic> _$RefreshTokenDataToJson(RefreshTokenData instance) =>
    <String, dynamic>{
      'message': instance.message,
      'token': instance.token,
      'userId': instance.userId,
      'email': instance.email,
      'name': instance.name,
      'mobile': instance.mobile,
    };
