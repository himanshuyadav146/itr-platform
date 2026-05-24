import 'package:dartz/dartz.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/auth/data/models/login_request_model.dart';
import 'package:tax_client/features/auth/data/models/signup_request_model.dart';
import 'package:tax_client/features/auth/data/models/forget_password_request_model.dart';
import 'package:tax_client/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, ({User user, String token})>> login(
    LoginRequestModel request,
  );

  Future<Either<Failure, String>> register(
    SignupRequestModel request,
  );

  Future<Either<Failure, String>> forgetPassword(
    ForgetPasswordRequestModel request,
  );

  Future<Either<Failure, String>> refreshToken(String oldToken);

  Future<Either<Failure, String>> deleteAccount(String userId);

  Future<Either<Failure, String>> registerFcm(String fcmToken, String platform);

  Future<void> logout();
}
