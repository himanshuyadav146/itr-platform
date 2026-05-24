import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/auth/domain/repositories/auth_repository.dart';

class RefreshToken {
  final AuthRepository repository;

  RefreshToken(this.repository);

  Future<Either<Failure, String>> call(String oldToken) async {
    return await repository.refreshToken(oldToken);
  }
}

