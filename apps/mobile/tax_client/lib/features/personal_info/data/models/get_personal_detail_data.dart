import 'package:json_annotation/json_annotation.dart';

part 'get_personal_detail_data.g.dart';

@JsonSerializable()
class GetPersonalDetailData {
  @JsonKey(name: 'UserId')
  final int? userId;
  @JsonKey(name: 'FirstName')
  final String? firstName;
  @JsonKey(name: 'MiddleName')
  final String? middleName;
  @JsonKey(name: 'LastName')
  final String? lastName;
  @JsonKey(name: 'PANNumber')
  final String? panNumber;
  @JsonKey(name: 'DATEOFBIRTH')
  final String? dateOfBirth;
  @JsonKey(name: 'Address')
  final String? address;
  @JsonKey(name: 'city')
  final String? city;
  @JsonKey(name: 'state')
  final String? state;
  @JsonKey(name: 'pincode')
  final String? pincode;
  @JsonKey(name: 'MobileNumber')
  final String? mobileNumber;
  @JsonKey(name: 'EMAIL')
  final String? email;
  @JsonKey(name: 'aadharCardNumber')
  final String? aadhaarCardNumber;
  @JsonKey(name: 'Gender')
  final String? gender;
  @JsonKey(name: 'FinancialYear')
  final String? financialYear;
  @JsonKey(name: 'Country')
  final String? country;

  GetPersonalDetailData({
    this.userId,
    this.firstName,
    this.middleName,
    this.lastName,
    this.panNumber,
    this.dateOfBirth,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.mobileNumber,
    this.email,
    this.aadhaarCardNumber,
    this.gender,
    this.financialYear,
    this.country,
  });

  factory GetPersonalDetailData.fromJson(Map<String, dynamic> json) =>
      _$GetPersonalDetailDataFromJson(json);

  Map<String, dynamic> toJson() => _$GetPersonalDetailDataToJson(this);
}

