import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/core/error/failures.dart';
import 'package:tax_client/features/auth/domain/usecases/forget_password.dart';
import 'package:tax_client/features/auth/domain/usecases/login.dart';
import 'package:tax_client/features/auth/domain/usecases/logout.dart';
import 'package:tax_client/features/auth/domain/usecases/register.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_state.dart';

import '../../domain/usecases/delete_account.dart';

class AuthViewModel extends StateNotifier<AuthState> {
  final Login _login;
  final Register _register;
  final ForgetPassword _forgetPassword;
  final Logout _logout;
  final DeleteAccount _deleteAccount;

  AuthViewModel(this._login, this._register, this._forgetPassword, this._logout, this._deleteAccount)
    : super(const AuthInitial());

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    final result = await _login(LoginParams(email: email, password: password));
    state = result.fold(
      (failure) => AuthError(_getErrorMessage(failure)),
      (data) => AuthAuthenticated(user: data.user, token: data.token),
    );
  }

  Future<void> register(
    String name,
    String mobile,
    String email,
    String password,
  ) async {
    state = const AuthLoading();
    final result = await _register(
      RegisterParams(
        name: name,
        mobile: mobile,
        email: email,
        password: password,
      ),
    );
    state = result.fold(
      (failure) => AuthError(_getErrorMessage(failure)),
      (message) => AuthRegistered(message: message),
    );
  }

  Future<void> forgetPassword(String email, String password) async {
    state = const AuthLoading();
    final result = await _forgetPassword(
      ForgetPasswordParams(email: email, password: password),
    );
    state = result.fold(
      (failure) => AuthError(_getErrorMessage(failure)),
      (message) => const AuthInitial(), // Return to initial state after success
    );
  }

  Future<void> logout() async {
    await _logout(NoParams());
    state = const AuthInitial();
  }

  Future<void> deleteAccount(String userId) async {
    state = const AuthLoading();
    final result = await _deleteAccount(userId);
    state = result.fold(
      (failure) => AuthError(_getErrorMessage(failure)),
      (message) => AuthDeleteSuccess(message: message),
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure && failure.message != null) {
      return failure.message!;
    }
    return 'An error occurred. Please try again.';
  }
}
