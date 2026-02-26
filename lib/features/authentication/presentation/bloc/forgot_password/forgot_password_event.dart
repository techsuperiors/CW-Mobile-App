import 'package:equatable/equatable.dart';

/// Forgot password flow events
abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

/// Request OTP for forgot password
class ForgotPasswordRequested extends ForgotPasswordEvent {
  final String email;

  const ForgotPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

/// Resend OTP
class ForgotPasswordResendRequested extends ForgotPasswordEvent {
  final String email;

  const ForgotPasswordResendRequested(this.email);

  @override
  List<Object?> get props => [email];
}

/// Validate OTP
class ForgotPasswordOtpValidated extends ForgotPasswordEvent {
  final String email;
  final String otp;

  const ForgotPasswordOtpValidated({
    required this.email,
    required this.otp,
  });

  @override
  List<Object?> get props => [email, otp];
}

/// Reset password with new password
class ForgotPasswordResetRequested extends ForgotPasswordEvent {
  final String password;

  const ForgotPasswordResetRequested(this.password);

  @override
  List<Object?> get props => [password];
}

/// Reset bloc state (e.g. when navigating away)
class ForgotPasswordReset extends ForgotPasswordEvent {
  const ForgotPasswordReset();
}
