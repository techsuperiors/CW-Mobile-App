import 'package:equatable/equatable.dart';

/// Authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Login event
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object> get props => [email, password, rememberMe];
}

/// Logout event
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Check authentication status
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

