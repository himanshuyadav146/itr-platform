import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/personal_info/data/models/personal_info_request_model.dart';
import 'package:tax_client/features/personal_info/domain/repositories/personal_info_repository.dart';

class AddPersonalDetails implements UseCase<String, AddPersonalDetailsParams> {
  final PersonalInfoRepository repository;

  AddPersonalDetails(this.repository);

  @override
  Future<Either<Failure, String>> call(AddPersonalDetailsParams params) async {
    final request = PersonalInfoRequestModel(
      panNumber: params.panNumber,
      firstName: params.firstName,
      middleName: params.middleName,
      lastName: params.lastName,
      email: params.email,
      mobileNumber: params.mobileNumber,
      aadhaarCardNumber: params.aadhaarCardNumber,
      gender: params.gender,
      financialYear: params.financialYear,
      address: params.address,
      country: params.country,
      journeyType: params.journeyType,
      packageId: params.packageId,
    );
    return await repository.addPersonalDetails(request);
  }
}

class AddPersonalDetailsParams {
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

  AddPersonalDetailsParams({
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
}
