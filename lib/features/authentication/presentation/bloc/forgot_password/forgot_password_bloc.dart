import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/error_handler.dart';
import '../../../data/repository/auth_repository.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

/// BLoC for forgot password flow
class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final AuthRepository authRepository;

  ForgotPasswordBloc({
    required this.authRepository,
  }) : super(const ForgotPasswordInitial()) {
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ForgotPasswordResendRequested>(_onResendRequested);
    on<ForgotPasswordOtpValidated>(_onOtpValidated);
    on<ForgotPasswordResetRequested>(_onResetRequested);
    on<ForgotPasswordReset>(_onReset);
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());
    try {
      await authRepository.forgotPassword(event.email);
      emit(ForgotPasswordForgotSuccess(event.email));
    } on AppException catch (e) {
      emit(ForgotPasswordError(ErrorHandler.handleException(e)));
    } catch (e) {
      emit(ForgotPasswordError(ErrorHandler.handleException(e)));
    }
  }

  Future<void> _onResendRequested(
    ForgotPasswordResendRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());
    try {
      await authRepository.forgotPassword(event.email);
      emit(const ForgotPasswordResendSuccess());
    } on AppException catch (e) {
      emit(ForgotPasswordError(ErrorHandler.handleException(e)));
    } catch (e) {
      emit(ForgotPasswordError(ErrorHandler.handleException(e)));
    }
  }

  Future<void> _onOtpValidated(
    ForgotPasswordOtpValidated event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());
    try {
      await authRepository.validatePasswordResetOtp(event.email, event.otp);
      emit(const ForgotPasswordOtpValidatedSuccess());
    } on AppException catch (e) {
      emit(ForgotPasswordError(ErrorHandler.handleException(e)));
    } catch (e) {
      emit(ForgotPasswordError(ErrorHandler.handleException(e)));
    }
  }

  Future<void> _onResetRequested(
    ForgotPasswordResetRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());
    try {
      await authRepository.resetPassword(event.password);
      emit(const ForgotPasswordResetSuccess());
    } on AppException catch (e) {
      emit(ForgotPasswordError(ErrorHandler.handleException(e)));
    } catch (e) {
      emit(ForgotPasswordError(ErrorHandler.handleException(e)));
    }
  }

  void _onReset(
    ForgotPasswordReset event,
    Emitter<ForgotPasswordState> emit,
  ) {
    emit(const ForgotPasswordInitial());
  }
}
