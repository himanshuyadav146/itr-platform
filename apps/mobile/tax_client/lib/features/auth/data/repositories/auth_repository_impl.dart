import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/core/network/token_storage.dart';
import 'package:tax_client/core/utils/device_platform.dart';
import 'package:tax_client/core/utils/jwt_decoder.dart';
import 'package:tax_client/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:tax_client/features/auth/data/models/login_request_model.dart';
import 'package:tax_client/features/auth/data/models/signup_request_model.dart';
import 'package:tax_client/features/auth/data/models/forget_password_request_model.dart';
import 'package:tax_client/features/auth/domain/entities/user.dart';
import 'package:tax_client/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    tokenStorage: ref.read(tokenStorageProvider),
    apiClient: ref.read(apiClientProvider),
  );
});

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenStorage tokenStorage;
  final ApiClient apiClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenStorage,
    required this.apiClient,
  });

  @override
  Future<Either<Failure, ({User user, String token})>> login(
    LoginRequestModel request,
  ) async {
    try {
      final result = await remoteDataSource.login(request);

      // LoginData contains: message, userId, email, token
      if (result.token.isNotEmpty) {
        final token = result.token;
        
        // Create User entity from LoginData
        final user = User(
          id: result.userId?.toString() ?? '',
          email: result.email,
          name: result.name,
          mobile: result.mobile ?? '',
        );

        // Extract userId from token payload
        final userIdFromToken = JwtDecoder.getUserIdFromToken(token);
        final userId = userIdFromToken ?? result.userId?.toString() ?? '';
        
        // Save token and user data
        await tokenStorage.saveToken(token);
        await tokenStorage.saveAuthResponse({
          'token': token,
          'email': result.email,
          'userId': userId.isNotEmpty ? userId : (result.userId?.toString() ?? ''),
          'message': result.message,
          'name': result.name,
          'mobile': result.mobile ?? '',
        });

        // Save user data separately for easy access by TokenStorage.getUserData()
        await tokenStorage.saveUserData({
          'id': userId,
          'name': result.name,
          'email': result.email,
          'mobile': result.mobile ?? '',
        });

        // Set token in API client for future requests
        apiClient.setAuthToken(token);

        await _registerStoredFcmToken();

        return Right((user: user, token: token));
      } else {
        return Left(ServerFailure(message: result.message));
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> register(
    SignupRequestModel request,
  ) async {
    try {
      final result = await remoteDataSource.signup(request);

      // SignupData contains: message, userId, email
      return Right(result.message);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> forgetPassword(
    ForgetPasswordRequestModel request,
  ) async {
    try {
      final result = await remoteDataSource.forgetPassword(request);

      // ForgetPasswordData contains: message
      return Right(result.message);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken(String oldToken) async {
    try {
      final result = await remoteDataSource.refreshToken(oldToken);

      if (result.token.isNotEmpty) {
        final token = result.token;

        // Extract userId from new token payload
        final userIdFromToken = JwtDecoder.getUserIdFromToken(token);
        final userId = userIdFromToken ?? result.userId?.toString() ?? '';
        
        // Save new token
        await tokenStorage.saveToken(token);
        await tokenStorage.saveAuthResponse({
          'token': token,
          'email': result.email,
          'userId': userId.isNotEmpty ? userId : (result.userId?.toString() ?? ''),
          'message': result.message,
          'name': result.name,
          'mobile': result.mobile ?? '',
        });

        // Update user data separately
        await tokenStorage.saveUserData({
          'id': userId,
          'name': result.name,
          'email': result.email,
          'mobile': result.mobile ?? '',
        });

        // Update token in API client
        apiClient.setAuthToken(token);

        await _registerStoredFcmToken();

        return Right(token);
      } else {
        return Left(ServerFailure(message: result.message));
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> deleteAccount(String userId) async {
    try {
      final result = await remoteDataSource.deleteAccount(userId);
      // After deleting on server, clear local data
      await logout();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> registerFcm(
    String fcmToken,
    String platform,
  ) async {
    try {
      await remoteDataSource.registerFcm(fcmToken, platform);
      return Right('FCM Token registered successfully');
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Registers locally stored FCM token when user session is active.
  Future<void> _registerStoredFcmToken() async {
    try {
      final fcmToken = await tokenStorage.getFcmToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('No stored FCM token to register after auth.');
        return;
      }

      final result = await registerFcm(fcmToken, getDevicePlatform());
      result.fold(
        (failure) => debugPrint(
          'Failed to register FCM token after auth: ${failure is ServerFailure ? failure.message : failure}',
        ),
        (_) => debugPrint('FCM token registered with backend after auth.'),
      );
    } catch (e) {
      debugPrint('Failed to register FCM token after auth: $e');
    }
  }

  @override
  Future<void> logout() async {
    await tokenStorage.deleteToken();
    apiClient.clearAuthToken();
  }
}
