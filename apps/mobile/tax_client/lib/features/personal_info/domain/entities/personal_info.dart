import 'package:equatable/equatable.dart';

class PersonalInfo extends Equatable {
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

  const PersonalInfo({
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
  });

  @override
  List<Object?> get props => [
        panNumber,
        firstName,
        middleName,
        lastName,
        email,
        mobileNumber,
        aadhaarCardNumber,
        gender,
        financialYear,
        address,
        country,
      ];
}
