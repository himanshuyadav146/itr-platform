import 'package:json_annotation/json_annotation.dart';

part 'personal_info_data.g.dart';

@JsonSerializable()
class PersonalInfoData {
  final String message;
  final String? panNumber;

  PersonalInfoData({
    required this.message,
    this.panNumber,
  });

  factory PersonalInfoData.fromJson(Map<String, dynamic> json) =>
      _$PersonalInfoDataFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalInfoDataToJson(this);
}
