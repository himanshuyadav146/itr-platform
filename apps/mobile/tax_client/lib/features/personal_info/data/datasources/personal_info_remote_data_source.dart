import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/personal_info/data/models/personal_info_request_model.dart';
import 'package:tax_client/features/personal_info/data/models/personal_info_data.dart';
import 'package:tax_client/features/personal_info/data/models/get_personal_detail_data.dart';
import 'package:tax_client/features/personal_info/data/models/get_itr_by_user_data.dart';

final personalInfoRemoteDataSourceProvider =
    Provider<PersonalInfoRemoteDataSource>((ref) {
  return PersonalInfoRemoteDataSourceImpl(ref.read(apiClientProvider));
});

abstract class PersonalInfoRemoteDataSource {
  Future<PersonalInfoData> addPersonalDetails(
    PersonalInfoRequestModel request,
  );

  Future<GetPersonalDetailData> getPersonalDetails({
    required String userId,
    required String panNumber,
  });

  Future<GetItrByUserData> getItrByUser(String userId);
}

class PersonalInfoRemoteDataSourceImpl
    implements PersonalInfoRemoteDataSource {
  final ApiClient apiClient;

  PersonalInfoRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PersonalInfoData> addPersonalDetails(
    PersonalInfoRequestModel request,
  ) async {
    final response = await apiClient.post(
      ApiConstants.itrDetailsAddPersonalDetails,
      request.toJson(),
      (json) => PersonalInfoData.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<GetPersonalDetailData> getPersonalDetails({
    required String userId,
    required String panNumber,
  }) async {
    // Build query parameters
    final path = '${ApiConstants.itrDetailsGetPersonalDetails}?UserId=$userId&PanNumber=$panNumber';
    
    final response = await apiClient.get(
      path,
      (json) => GetPersonalDetailData.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<GetItrByUserData> getItrByUser(String userId) async {
    // Build query parameters
    final path = '${ApiConstants.itrGetItrByUser}?userId=$userId';
    
    final response = await apiClient.get(
      path,
      (json) => GetItrByUserData.fromJson(json),
    );

    return response.data;
  }
}
