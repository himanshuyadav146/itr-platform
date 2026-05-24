// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackageModel _$PackageModelFromJson(Map<String, dynamic> json) => PackageModel(
  id: json['id'] as String,
  name: json['packagename'] as String,
  description: json['description1'] as String,
  turnover: json['turnover'] as String?,
  price: json['price'] as String,
  icon: json['icon'] as String,
  color: json['color'] as String,
);

Map<String, dynamic> _$PackageModelToJson(PackageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'packagename': instance.name,
      'description1': instance.description,
      'turnover': instance.turnover,
      'price': instance.price,
      'icon': instance.icon,
      'color': instance.color,
    };

PackagesData _$PackagesDataFromJson(Map<String, dynamic> json) => PackagesData(
  packages: (json['packages'] as List<dynamic>)
      .map((e) => PackageModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PackagesDataToJson(PackagesData instance) =>
    <String, dynamic>{'packages': instance.packages};
