import 'package:equatable/equatable.dart';

abstract class PersonalInfoState extends Equatable {
  const PersonalInfoState();

  @override
  List<Object?> get props => [];
}

class PersonalInfoInitial extends PersonalInfoState {
  const PersonalInfoInitial();
}

class PersonalInfoLoading extends PersonalInfoState {
  const PersonalInfoLoading();
}

class PersonalInfoSuccess extends PersonalInfoState {
  final String message;

  const PersonalInfoSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class PersonalInfoError extends PersonalInfoState {
  final String message;

  const PersonalInfoError(this.message);

  @override
  List<Object?> get props => [message];
}

class PersonalInfoLoaded extends PersonalInfoState {
  final String firstName;
  final String middleName;
  final String lastName;
  final String phone;
  final String email;
  final String pan;
  final String aadhar;
  final String gender;
  final String financialYear;
  final String address;
  final String country;

  const PersonalInfoLoaded({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.pan,
    required this.aadhar,
    required this.gender,
    required this.financialYear,
    required this.address,
    required this.country,
  });

  @override
  List<Object?> get props => [
        firstName,
        middleName,
        lastName,
        phone,
        email,
        pan,
        aadhar,
        gender,
        financialYear,
        address,
        country,
      ];
}

class ItrListLoading extends PersonalInfoState {
  const ItrListLoading();
}

class ItrListLoaded extends PersonalInfoState {
  final List<dynamic> itrList;
  final int count;

  const ItrListLoaded({
    required this.itrList,
    required this.count,
  });

  @override
  List<Object?> get props => [itrList, count];
}

class ItrListError extends PersonalInfoState {
  final String message;

  const ItrListError(this.message);

  @override
  List<Object?> get props => [message];
}
