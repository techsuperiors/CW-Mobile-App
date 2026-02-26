import 'package:equatable/equatable.dart';
import '../../../../../core/error/failures.dart';

/// Forgot password flow states
abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

/// Loading state
class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

/// Forgot password (send OTP) success - navigate to OTP page
class ForgotPasswordForgotSuccess extends ForgotPasswordState {
  final String email;

  const ForgotPasswordForgotSuccess(this.email);

  @override
  List<Object?> get props => [email];
}

/// Resend OTP success
class ForgotPasswordResendSuccess extends ForgotPasswordState {
  const ForgotPasswordResendSuccess();
}

/// OTP validated success - navigate to reset password page
class ForgotPasswordOtpValidatedSuccess extends ForgotPasswordState {
  const ForgotPasswordOtpValidatedSuccess();
}

/// Reset password success - navigate to success page
class ForgotPasswordResetSuccess extends ForgotPasswordState {
  const ForgotPasswordResetSuccess();
}

/// Error state
class ForgotPasswordError extends ForgotPasswordState {
  final Failure failure;

  const ForgotPasswordError(this.failure);

  @override
  List<Object?> get props => [failure];
}
