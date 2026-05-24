import 'package:json_annotation/json_annotation.dart';

part 'refresh_token_data.g.dart';

@JsonSerializable()
class RefreshTokenData {
  final String message;
  final String token;
  @JsonKey(name: 'userId')
  final int? userId;
  final String? email;
  final String? name;
  final String? mobile;

  RefreshTokenData({
    required this.message,
    required this.token,
    this.userId,
    this.email,
    this.name,
    this.mobile,
  });

  factory RefreshTokenData.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenDataFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenDataToJson(this);
}

