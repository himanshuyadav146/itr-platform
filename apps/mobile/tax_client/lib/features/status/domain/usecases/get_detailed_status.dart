import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/status/data/models/itr_detailed_status_model.dart';
import 'package:tax_client/features/status/data/repositories/status_repository_impl.dart';

final getDetailedStatusProvider = Provider<GetDetailedStatus>((ref) {
  return GetDetailedStatus(ref.read(statusRepositoryProvider));
});

class GetDetailedStatus {
  final StatusRepository repository;

  GetDetailedStatus(this.repository);

  Future<Either<Failure, ItrDetailedStatusModel>> call(String orderId,String itrId) {
    return repository.getDetailedStatus(orderId,itrId);
  }
}
