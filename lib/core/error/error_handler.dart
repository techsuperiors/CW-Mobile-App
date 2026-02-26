import 'exceptions.dart';
import 'failures.dart';
import '../constants/app_strings.dart';

/// Error handler utility
class ErrorHandler {
  /// Convert exception to failure
  static Failure handleException(dynamic exception) {
    if (exception is ServerException) {
      return ServerFailure(exception.message);
    } else if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message);
    } else if (exception is AuthException) {
      return AuthFailure(exception.message);
    } else {
      return UnknownFailure(
        exception?.toString() ?? AppStrings.unknownError,
      );
    }
  }

  /// Get user-friendly error message
  static String getErrorMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return AppStrings.networkError;
    } else if (failure is ServerFailure) {
      return AppStrings.serverError;
    } else if (failure is CacheFailure) {
      return AppStrings.storageError;
    } else {
      return failure.message;
    }
  }
}

