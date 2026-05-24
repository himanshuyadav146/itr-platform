import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/network/exceptions.dart';
import 'package:tax_client/features/status/data/datasources/status_remote_data_source.dart';
import 'package:tax_client/features/status/data/models/itr_detailed_status_model.dart';

final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepositoryImpl(ref.read(statusRemoteDataSourceProvider));
});

abstract class StatusRepository {
  Future<Either<Failure, ItrDetailedStatusModel>> getDetailedStatus(String orderId,String itrId);
}

class StatusRepositoryImpl implements StatusRepository {
  final StatusRemoteDataSource remoteDataSource;

  StatusRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ItrDetailedStatusModel>> getDetailedStatus(String orderId,String itrId) async {
    try {
      final result = await remoteDataSource.getDetailedStatus(orderId,itrId);
      return Right(result);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
