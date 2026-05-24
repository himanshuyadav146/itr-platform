import 'package:json_annotation/json_annotation.dart';

part 'forget_password_data.g.dart';

@JsonSerializable()
class ForgetPasswordData {
  final String message;

  ForgetPasswordData({
    required this.message,
  });

  factory ForgetPasswordData.fromJson(Map<String, dynamic> json) =>
      _$ForgetPasswordDataFromJson(json);

  Map<String, dynamic> toJson() => _$ForgetPasswordDataToJson(this);
}
