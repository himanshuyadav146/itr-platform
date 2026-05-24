import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/personal_info/data/models/get_itr_by_user_data.dart';
import 'package:tax_client/features/personal_info/domain/repositories/personal_info_repository.dart';

class GetItrByUser implements UseCase<GetItrByUserData, GetItrByUserParams> {
  final PersonalInfoRepository repository;

  GetItrByUser(this.repository);

  @override
  Future<Either<Failure, GetItrByUserData>> call(GetItrByUserParams params) async {
    return await repository.getItrByUser(params.userId);
  }
}

class GetItrByUserParams {
  final String userId;

  GetItrByUserParams({
    required this.userId,
  });
}

