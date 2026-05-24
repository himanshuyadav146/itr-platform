import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccount implements UseCase<String, String> {
  final AuthRepository repository;

  DeleteAccount(this.repository);

  @override
  Future<Either<Failure, String>> call(String userId) async {
    return await repository.deleteAccount(userId);
  }
}
