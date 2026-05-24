// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_info_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalInfoData _$PersonalInfoDataFromJson(Map<String, dynamic> json) =>
    PersonalInfoData(
      message: json['message'] as String,
      panNumber: json['panNumber'] as String?,
    );

Map<String, dynamic> _$PersonalInfoDataToJson(PersonalInfoData instance) =>
    <String, dynamic>{
      'message': instance.message,
      'panNumber': instance.panNumber,
    };
