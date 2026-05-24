import 'package:json_annotation/json_annotation.dart';

part 'login_data.g.dart';

@JsonSerializable()
class LoginData {
  final String message;
  @JsonKey(name: 'UserId')
  final String? userId;
  final String email;
  final String token;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? mobile;

  LoginData({
    required this.message,
    this.userId,
    required this.email,
    required this.token,
    this.firstName,
    this.middleName,
    this.lastName,
    this.mobile,
  });

  String get name => "${firstName ?? ''} ${lastName ?? ''}".trim();

  factory LoginData.fromJson(Map<String, dynamic> json) =>
      _$LoginDataFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDataToJson(this);
}
