import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_client/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:tax_client/features/auth/domain/usecases/forget_password.dart';
import 'package:tax_client/features/auth/domain/usecases/login.dart';
import 'package:tax_client/features/auth/domain/usecases/logout.dart';
import 'package:tax_client/features/auth/domain/usecases/register.dart';
import 'package:tax_client/features/auth/domain/usecases/delete_account.dart';
import 'package:tax_client/features/auth/presentation/providers/auth_state.dart';

import '../viewmodel/auth_view_model.dart';

/// DI: Exposes the `Login` use case with its repository dependency.
/// Presentation layer consumes this without direct knowledge of repository wiring.
final loginProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final registerProvider = Provider<Register>((ref) {
  return Register(ref.watch(authRepositoryProvider));
});

final forgetPasswordProvider = Provider<ForgetPassword>((ref) {
  return ForgetPassword(ref.watch(authRepositoryProvider));
});

final logoutProvider = Provider<Logout>((ref) {
  return Logout(ref.watch(authRepositoryProvider));
});

final deleteAccountProvider = Provider<DeleteAccount>((ref) {
  return DeleteAccount(ref.watch(authRepositoryProvider));
});

/// DI: ViewModel provider managing auth UI state and actions.
/// Injects the use cases and exposes reactive state to widgets.
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel(
    ref.watch(loginProvider),
    ref.watch(registerProvider),
    ref.watch(forgetPasswordProvider),
    ref.watch(logoutProvider),
    ref.watch(deleteAccountProvider),
  );
});
