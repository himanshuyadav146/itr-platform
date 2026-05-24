import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/auth/data/models/signup_request_model.dart';
import 'package:tax_client/features/auth/domain/repositories/auth_repository.dart';

class Register {
  final AuthRepository repository;

  Register(this.repository);

  Future<Either<Failure, String>> call(
    RegisterParams params,
  ) async {
    final request = SignupRequestModel(
      name: params.name,
      email: params.email,
      mobile: params.mobile,
      password: params.password,
      platform: params.platform,
      version: params.version,
    );
    return await repository.register(request);
  }
}

class RegisterParams {
  final String name;
  final String mobile;
  final String email;
  final String password;
  final String platform;
  final String version;

  RegisterParams({
    required this.name,
    required this.mobile,
    required this.email,
    required this.password,
    String? platform,
    String? version,
  }) : platform = platform ?? (Platform.isAndroid ? 'android' : 'ios'),
       version = version ?? '1.0';
}
