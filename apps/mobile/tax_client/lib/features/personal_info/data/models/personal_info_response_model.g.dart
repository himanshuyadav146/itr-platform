// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_info_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalInfoResponseModel _$PersonalInfoResponseModelFromJson(
  Map<String, dynamic> json,
) => PersonalInfoResponseModel(
  status: json['status'] as String,
  message: json['message'] as String,
  panNumber: json['panNumber'] as String?,
);

Map<String, dynamic> _$PersonalInfoResponseModelToJson(
  PersonalInfoResponseModel instance,
) => <String, dynamic>{
  'status': instance.status,
  'message': instance.message,
  'panNumber': instance.panNumber,
};
