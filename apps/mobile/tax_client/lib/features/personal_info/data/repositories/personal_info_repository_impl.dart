import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/network/exceptions.dart';
import 'package:tax_client/core/network/logout_handler.dart';
import 'package:tax_client/core/network/logout_handler_impl.dart';
import 'package:tax_client/features/personal_info/data/datasources/personal_info_remote_data_source.dart';
import 'package:tax_client/features/personal_info/data/models/personal_info_request_model.dart';
import 'package:tax_client/features/personal_info/data/models/get_personal_detail_data.dart';
import 'package:tax_client/features/personal_info/data/models/get_itr_by_user_data.dart';
import 'package:tax_client/features/personal_info/domain/repositories/personal_info_repository.dart';

final personalInfoRepositoryProvider = Provider<PersonalInfoRepository>((ref) {
  return PersonalInfoRepositoryImpl(
    remoteDataSource: ref.read(personalInfoRemoteDataSourceProvider),
    logoutHandler: ref.read(logoutHandlerProvider),
  );
});

class PersonalInfoRepositoryImpl implements PersonalInfoRepository {
  final PersonalInfoRemoteDataSource remoteDataSource;
  final LogoutHandler logoutHandler;

  PersonalInfoRepositoryImpl({
    required this.remoteDataSource,
    required this.logoutHandler,
  });

  @override
  Future<Either<Failure, String>> addPersonalDetails(
    PersonalInfoRequestModel request,
  ) async {
    try {
      final result = await remoteDataSource.addPersonalDetails(request);

      // PersonalInfoData contains: message, panNumber
      return Right(result.message);
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Either<Failure, GetPersonalDetailData>> getPersonalDetails({
    required String userId,
    required String panNumber,
  }) async {
    try {
      final result = await remoteDataSource.getPersonalDetails(
        userId: userId,
        panNumber: panNumber,
      );

      return Right(result);
    } catch (e) {
      return _handleError(e);
    }
  }

  @override
  Future<Either<Failure, GetItrByUserData>> getItrByUser(String userId) async {
    try {
      final result = await remoteDataSource.getItrByUser(userId);

      return Right(result);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Handles errors and triggers logout for 401 status codes
  Either<Failure, T> _handleError<T>(dynamic e) {
    // Check if it's an ApiException
    if (e is ApiException) {
      // If status code is 401, trigger automatic logout
      if (e.statusCode == 401) {
        logoutHandler.triggerLogout();
        return Left(ServerFailure(
          message: 'Session expired. Please login again.',
        ));
      }
      // For other ApiExceptions, use the exception message
      return Left(ServerFailure(message: e.message));
    }
    // For other exceptions, convert to string
    return Left(ServerFailure(message: e.toString()));
  }
}
