import 'package:json_annotation/json_annotation.dart';

part 'personal_info_request_model.g.dart';

@JsonSerializable()
class PersonalInfoRequestModel {
  final String panNumber;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String aadhaarCardNumber;
  final String gender;
  final String financialYear;
  final String address;
  final String country;
  final String journeyType;
  final int? packageId;

  PersonalInfoRequestModel({
    required this.panNumber,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.aadhaarCardNumber,
    required this.gender,
    required this.financialYear,
    required this.address,
    required this.country,
    required this.journeyType,
    this.packageId,
  });

  factory PersonalInfoRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PersonalInfoRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalInfoRequestModelToJson(this);
}
