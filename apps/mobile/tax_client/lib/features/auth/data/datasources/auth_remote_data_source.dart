import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/constant/api_constants.dart';
import 'package:tax_client/core/network/api_client.dart';
import 'package:tax_client/features/auth/data/models/login_data.dart';
import 'package:tax_client/features/auth/data/models/signup_data.dart';
import 'package:tax_client/features/auth/data/models/forget_password_data.dart';
import 'package:tax_client/features/auth/data/models/refresh_token_data.dart';
import 'package:tax_client/features/auth/data/models/login_request_model.dart';
import 'package:tax_client/features/auth/data/models/signup_request_model.dart';
import 'package:tax_client/features/auth/data/models/forget_password_request_model.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(apiClientProvider));
});

abstract class AuthRemoteDataSource {
  Future<LoginData> login(LoginRequestModel request);

  Future<SignupData> signup(SignupRequestModel request);

  Future<ForgetPasswordData> forgetPassword(
    ForgetPasswordRequestModel request,
  );

  Future<RefreshTokenData> refreshToken(String oldToken);

  Future<void> registerFcm(String fcmToken, String platform);

  Future<String> deleteAccount(String userId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LoginData> login(LoginRequestModel request) async {
    final response = await apiClient.post(
      ApiConstants.authLogin,
      request.toJson(),
      (json) => LoginData.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<SignupData> signup(SignupRequestModel request) async {
    final response = await apiClient.post(
      ApiConstants.authSignup,
      request.toJson(),
      (json) => SignupData.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<ForgetPasswordData> forgetPassword(
    ForgetPasswordRequestModel request,
  ) async {
    final response = await apiClient.post(
      ApiConstants.authForgetPassword,
      request.toJson(),
      (json) => ForgetPasswordData.fromJson(json),
    );

    return response.data;
  }

  @override
  Future<RefreshTokenData> refreshToken(String oldToken) async {
    // Refresh token uses GET request with Authorization header
    final response = await apiClient.get(
      ApiConstants.authRefreshToken,
      (json) => RefreshTokenData.fromJson(json),
      headers: {'Authorization': 'Bearer $oldToken'},
    );

    return response.data;
  }

  @override
  Future<String> deleteAccount(String userId) async {
    final response = await apiClient.post(
      ApiConstants.authDeleteAccount,
      {}, // Empty body - backend uses JWT token from Authorization header
      (json) {
        // Parse nested response: {"status": "success", "statusCode": 200, "data": {"message": "..."}}
        if (json['data'] != null && json['data']['message'] != null) {
          return json['data']['message'] as String;
        }
        return json['message'] as String? ?? 'Account deleted successfully';
      },
    );

    return response.data;
  }

  @override
  Future<void> registerFcm(String fcmToken, String platform) async {
    await apiClient.post(
      ApiConstants.authRegisterFcm,
      {
        "fcm_token": fcmToken,
        "platform": platform,
      },
      (json) => null, // Backend just returns a success message
    );
  }
}
