import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/personal_info/data/models/personal_info_request_model.dart';
import 'package:tax_client/features/personal_info/data/models/get_personal_detail_data.dart';
import 'package:tax_client/features/personal_info/data/models/get_itr_by_user_data.dart';

abstract class PersonalInfoRepository {
  Future<Either<Failure, String>> addPersonalDetails(
    PersonalInfoRequestModel request,
  );

  Future<Either<Failure, GetPersonalDetailData>> getPersonalDetails({
    required String userId,
    required String panNumber,
  });

  Future<Either<Failure, GetItrByUserData>> getItrByUser(String userId);
}
