import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/personal_info/data/models/get_personal_detail_data.dart';
import 'package:tax_client/features/personal_info/domain/repositories/personal_info_repository.dart';

class GetPersonalDetails implements UseCase<GetPersonalDetailData, GetPersonalDetailsParams> {
  final PersonalInfoRepository repository;

  GetPersonalDetails(this.repository);

  @override
  Future<Either<Failure, GetPersonalDetailData>> call(GetPersonalDetailsParams params) async {
    return await repository.getPersonalDetails(
      userId: params.userId,
      panNumber: params.panNumber,
    );
  }
}

class GetPersonalDetailsParams {
  final String userId;
  final String panNumber;

  GetPersonalDetailsParams({
    required this.userId,
    required this.panNumber,
  });
}

