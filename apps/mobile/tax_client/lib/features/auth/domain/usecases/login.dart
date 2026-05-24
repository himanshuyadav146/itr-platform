import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/usecase/usecase.dart';
import 'package:tax_client/features/auth/data/models/login_request_model.dart';
import 'package:tax_client/features/auth/domain/entities/user.dart';
import 'package:tax_client/features/auth/domain/repositories/auth_repository.dart';

class Login implements UseCase<({User user, String token}), LoginParams> {
  final AuthRepository repository;

  Login(this.repository);

  @override
  Future<Either<Failure, ({User user, String token})>> call(
    LoginParams params,
  ) async {
    final request = LoginRequestModel(
      email: params.email,
      password: params.password,
      platform: params.platform,
      version: params.version,
    );
    return await repository.login(request);
  }
}

class LoginParams {
  final String email;
  final String password;
  final String platform;
  final String version;

  LoginParams({
    required this.email,
    required this.password,
    String? platform,
    String? version,
  }) : platform = platform ?? (Platform.isAndroid ? 'android' : 'ios'),
       version = version ?? '1.0';
}
