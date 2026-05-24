import 'package:equatable/equatable.dart';
import 'package:tax_client/features/auth/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});

  bool get isAuthenticated => token.isNotEmpty;

  @override
  List<Object?> get props => [user, token];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegistered extends AuthState {
  final String message;

  const AuthRegistered({this.message = 'Registration successful'});

  @override
  List<Object?> get props => [message];
}

class AuthDeleteSuccess extends AuthState {
  final String message;

  const AuthDeleteSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
