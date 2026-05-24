import 'package:json_annotation/json_annotation.dart';
import 'package:tax_client/features/auth/domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? mobile;  // Made optional since login response doesn't include it

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() => User(
    id: id, 
    name: name, 
    email: email, 
    mobile: mobile ?? '',  // Provide empty string if null
  );
}
