import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/auth/data/models/forget_password_request_model.dart';
import 'package:tax_client/features/auth/domain/repositories/auth_repository.dart';

class ForgetPassword implements UseCase<String, ForgetPasswordParams> {
  final AuthRepository repository;

  ForgetPassword(this.repository);

  @override
  Future<Either<Failure, String>> call(ForgetPasswordParams params) async {
    final request = ForgetPasswordRequestModel(
      email: params.email,
      password: params.password,
    );
    return await repository.forgetPassword(request);
  }
}

class ForgetPasswordParams {
  final String email;
  final String password;

  ForgetPasswordParams({required this.email, required this.password});
}
