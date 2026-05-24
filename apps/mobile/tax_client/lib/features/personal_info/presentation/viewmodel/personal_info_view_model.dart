import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/features/personal_info/domain/usecases/add_personal_details.dart';
import 'package:tax_client/features/personal_info/domain/usecases/get_personal_details.dart';
import 'package:tax_client/features/personal_info/domain/usecases/get_itr_by_user.dart';
import 'package:tax_client/features/personal_info/presentation/providers/personal_info_state.dart';

class PersonalInfoViewModel extends StateNotifier<PersonalInfoState> {
  final AddPersonalDetails _addPersonalDetails;
  final GetPersonalDetails _getPersonalDetails;
  final GetItrByUser _getItrByUser;
  final TokenStorage _tokenStorage;

  PersonalInfoViewModel(
    this._addPersonalDetails,
    this._getPersonalDetails,
    this._getItrByUser,
    this._tokenStorage,
  ) : super(const PersonalInfoInitial());

  Future<void> addPersonalDetails({
    required String panNumber,
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String aadhaarCardNumber,
    required String gender,
    required String financialYear,
    required String address,
    required String country,
    required String journeyType,
    int? packageId,
  }) async {
    state = const PersonalInfoLoading();

    final params = AddPersonalDetailsParams(
      panNumber: panNumber,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      mobileNumber: mobileNumber,
      aadhaarCardNumber: aadhaarCardNumber,
      gender: gender,
      financialYear: financialYear,
      address: address,
      country: country,
      journeyType: journeyType,
      packageId: packageId,
    );

    final result = await _addPersonalDetails(params);

    result.fold(
      (failure) {
        state = PersonalInfoError(_getErrorMessage(failure));
      },
      (message) async {
        // Save PAN number to SharedPreferences on success
        await _tokenStorage.savePanNumber(panNumber);
        state = PersonalInfoSuccess(message: message);
      },
    );
  }

  Future<void> getPersonalDetails({
    required String userId,
    required String panNumber,
  }) async {
    state = const PersonalInfoLoading();

    final params = GetPersonalDetailsParams(
      userId: userId,
      panNumber: panNumber,
    );

    final result = await _getPersonalDetails(params);

    result.fold(
      (failure) {
        state = PersonalInfoError(_getErrorMessage(failure));
      },
      (data) {
        state = PersonalInfoLoaded(
          firstName: data.firstName ?? '',
          middleName: data.middleName ?? '',
          lastName: data.lastName ?? '',
          phone: data.mobileNumber ?? '',
          email: data.email ?? '',
          pan: data.panNumber ?? '',
          aadhar: data.aadhaarCardNumber ?? '',
          gender: data.gender ?? 'Male',
          financialYear: data.financialYear ?? '2023-24',
          address: data.address ?? '',
          country: data.country ?? 'India',
        );
      },
    );
  }

  Future<void> getItrByUser(String userId) async {
    state = const ItrListLoading();

    final params = GetItrByUserParams(userId: userId);

    final result = await _getItrByUser(params);

    result.fold(
      (failure) {
        state = ItrListError(_getErrorMessage(failure));
      },
      (data) {
        final filteredList = data.personalDetails.where((itr) {
          final status = (itr.paymentStatus ?? '').trim().toLowerCase();
          return status != 'success';
        }).toList();

        state = ItrListLoaded(
          itrList: filteredList,
          count: filteredList.length,
        );
      },
    );
  }

  void resetState() {
    state = const PersonalInfoInitial();
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure && failure.message != null) {
      return failure.message!;
    }
    return 'An error occurred. Please try again.';
  }
}
