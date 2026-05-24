import 'package:json_annotation/json_annotation.dart';
import 'package:tax_client/features/auth/data/models/user_model.dart';

part 'auth_response_model.g.dart';

@JsonSerializable()
class AuthResponseModel {
  @JsonKey(name: 'status')
  final String status;
  final String message;
  final String? token;
  final UserModel? user;

  const AuthResponseModel({
    required this.status,
    required this.message,
    this.token,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);
}
