import 'package:json_annotation/json_annotation.dart';

part 'signup_data.g.dart';

@JsonSerializable()
class SignupData {
  final String message;
  @JsonKey(name: 'userId')
  final int? userId;
  final String? email;

  SignupData({
    required this.message,
    this.userId,
    this.email,
  });

  factory SignupData.fromJson(Map<String, dynamic> json) =>
      _$SignupDataFromJson(json);

  Map<String, dynamic> toJson() => _$SignupDataToJson(this);
}
