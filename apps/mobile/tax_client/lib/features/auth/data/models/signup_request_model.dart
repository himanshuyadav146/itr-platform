import 'package:json_annotation/json_annotation.dart';

part 'signup_request_model.g.dart';

@JsonSerializable()
class SignupRequestModel {
  final String name;
  final String email;
  final String mobile;
  final String password;
  final String platform;
  final String version;

  SignupRequestModel({
    required this.name,
    required this.email,
    required this.mobile,
    required this.password,
    required this.platform,
    required this.version,
  });

  factory SignupRequestModel.fromJson(Map<String, dynamic> json) =>
      _$SignupRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$SignupRequestModelToJson(this);
}
