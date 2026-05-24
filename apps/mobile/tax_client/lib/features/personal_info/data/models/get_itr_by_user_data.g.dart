// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_itr_by_user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetItrByUserData _$GetItrByUserDataFromJson(Map<String, dynamic> json) =>
    GetItrByUserData(
      personalDetails: (json['personalDetails'] as List<dynamic>)
          .map(
            (e) => ItrPersonalDetailModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      count: (json['count'] as num).toInt(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$GetItrByUserDataToJson(GetItrByUserData instance) =>
    <String, dynamic>{
      'personalDetails': instance.personalDetails,
      'count': instance.count,
      'message': instance.message,
    };
