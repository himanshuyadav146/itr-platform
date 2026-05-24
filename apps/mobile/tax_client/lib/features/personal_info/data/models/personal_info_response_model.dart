import 'package:json_annotation/json_annotation.dart';

part 'personal_info_response_model.g.dart';

@JsonSerializable()
class PersonalInfoResponseModel {
  final String status;
  final String message;
  final String? panNumber;

  PersonalInfoResponseModel({
    required this.status,
    required this.message,
    this.panNumber,
  });

  factory PersonalInfoResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PersonalInfoResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalInfoResponseModelToJson(this);
}
