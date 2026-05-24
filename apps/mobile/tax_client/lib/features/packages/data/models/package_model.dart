import 'package:json_annotation/json_annotation.dart';

part 'package_model.g.dart';

@JsonSerializable()
class PackageModel {
  @JsonKey(name: 'id')
  final String id;
  
  @JsonKey(name: 'packagename')
  final String name;
  
  @JsonKey(name: 'description1')
  final String description;
  
  @JsonKey(name: 'turnover')
  final String? turnover;
  
  @JsonKey(name: 'price')
  final String price;
  
  @JsonKey(name: 'icon')
  final String icon;
  
  @JsonKey(name: 'color')
  final String color;

  PackageModel({
    required this.id,
    required this.name,
    required this.description,
    this.turnover,
    required this.price,
    required this.icon,
    required this.color,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) =>
      _$PackageModelFromJson(json);

  Map<String, dynamic> toJson() => _$PackageModelToJson(this);
}

@JsonSerializable()
class PackagesData {
  final List<PackageModel> packages;

  PackagesData({
    required this.packages,
  });

  factory PackagesData.fromJson(Map<String, dynamic> json) {
    // If the json is actually a list, wrap it
    if (json is List) {
      return PackagesData(
        packages: (json as List).map((item) => PackageModel.fromJson(item as Map<String, dynamic>)).toList(),
      );
    }
    // Otherwise, try to parse from the expected format
    return _$PackagesDataFromJson(json);
  }

  Map<String, dynamic> toJson() => _$PackagesDataToJson(this);
}
