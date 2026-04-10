import 'package:flutter/material.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/data_encoder.dart';
import '../../../../core/utils/token_storage.dart';
import '../models/login_response.dart';
import '../models/user_model.dart';
import '../models/forgot_password_response.dart';
import '../models/validate_otp_response.dart';
import '../models/reset_password_response.dart';
import '../../domain/entities/user.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  /// Login with email and password
  /// Returns a minimal user object (just for state management)
  Future<User> login(String email, String password) async {
    try {
      // Encode the login payload using encodeData
      final payload = {
        'username': email,
        'password': password,
      };
      final encodedData = encodeData(payload);
      debugPrint('Encoded data: $encodedData');

      // Send the encoded data to the API
      final response = await _apiService.postNew<LoginResponse>(
        AppUrls.login,
        data: {
          'payload': encodedData,
        },
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      debugPrint('Login response success: ${response.isSuccess}');
      debugPrint('Login response: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final loginResponse = response.data!;

        if (!loginResponse.success) {
          throw ServerException(
            loginResponse.message ?? AppStrings.loginFailed,
          );
        }

        if (loginResponse.token == null || loginResponse.token!.isEmpty) {
          throw ServerException('Token not received from server');
        }

        // Save token to storage
        await TokenStorage.saveToken(loginResponse.token!);
        debugPrint('Token saved successfully');

        // Create minimal user object (just for state management)
        // No user data comes from API, so we just use email
        final user = UserModel(
          id: email,
          email: email,
          name: email,
          avatar: null,
          role: null,
          createdAt: null,
        );

        return user;
      } else {
        // Convert ApiException to appropriate AppException
        if (response.error != null) {
          final apiError = response.error!;
          if (apiError.statusCode == 401) {
            throw const AuthException(AppStrings.unauthorized);
          } else if (apiError.statusCode >= 500) {
            throw ServerException(apiError.message);
          } else {
            throw ServerException(apiError.message);
          }
        }
        throw ServerException(AppStrings.loginFailed);
      }
    } on ServerException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('Login failed: ${e.toString()}');
    }
  }

  /// Logout - best effort backend logout followed by local session clear.
  /// Returns true when local auth data is cleared successfully.
  Future<bool> logout() async {
    var remoteLogoutSucceeded = false;

    try {
      // Try to invalidate the backend session when possible, but don't trap
      // the user in the app if the token is already gone or expired.
      remoteLogoutSucceeded = await _apiService.callLogoutApi();
    } catch (e) {
      debugPrint('Logout API error: $e');
    }

    try {
      final localDataCleared = await TokenStorage.clearAll();
      if (!localDataCleared) {
        debugPrint('Logout failed - unable to clear local auth data');
        return false;
      }

      if (remoteLogoutSucceeded) {
        debugPrint('Logout complete - backend session invalidated and local data cleared');
      } else {
        debugPrint('Logout completed locally - backend logout was skipped or failed');
      }

      return true;
    } catch (e) {
      debugPrint('Logout local clear error: $e');
      return false;
    }
  }

  /// Forgot password - sends OTP to email
  Future<void> forgotPassword(String email) async {
    try {
      final payload = {'email': email};
      final encodedData = encodeData(payload);

      final response = await _apiService.postNew<ForgotPasswordResponse>(
        AppUrls.forgotPassword,
        data: {'payload': encodedData},
        fromJson: (json) => ForgotPasswordResponse.fromJson(
          json as Map<String, dynamic>,
        ),
      );

      if (response.isSuccess && response.data != null) {
        if (!response.data!.success) {
          throw ServerException(
            response.data!.data?.email != null
                ? 'Failed to send OTP'
                : AppStrings.serverError,
          );
        }
      } else {
        if (response.error != null) {
          throw ServerException(response.error!.message);
        }
        throw ServerException(AppStrings.serverError);
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('Forgot password failed: ${e.toString()}');
    }
  }

  /// Validate OTP - verifies OTP and returns token for reset password
  Future<void> validatePasswordResetOtp(String email, String otp) async {
    try {
      final payload = {'email': email, 'otp': otp};
      final encodedData = encodeData(payload);

      final response = await _apiService.postNew<ValidateOtpResponse>(
        AppUrls.validatePasswordResetOtp,
        data: {'payload': encodedData},
        fromJson: (json) => ValidateOtpResponse.fromJson(
          json as Map<String, dynamic>,
        ),
      );

      if (response.isSuccess && response.data != null) {
        final validateResponse = response.data!;
        if (!validateResponse.success) {
          throw ServerException('Invalid or expired OTP');
        }
        if (validateResponse.token == null ||
            validateResponse.token!.isEmpty) {
          throw ServerException('Token not received from server');
        }
        // Save token for reset password API
        await TokenStorage.saveToken(validateResponse.token!);
      } else {
        if (response.error != null) {
          throw ServerException(response.error!.message);
        }
        throw ServerException('Invalid or expired OTP');
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('OTP validation failed: ${e.toString()}');
    }
  }

  /// Reset password - requires token from validate OTP
  Future<void> resetPassword(String password) async {
    try {
      final payload = {'password': password};
      final encodedData = encodeData(payload);

      final response = await _apiService.postNew<ResetPasswordResponse>(
        AppUrls.resetPassword,
        data: {'payload': encodedData},
        fromJson: (json) => ResetPasswordResponse.fromJson(
          json as Map<String, dynamic>,
        ),
      );

      if (response.isSuccess && response.data != null) {
        if (!response.data!.success) {
          throw ServerException(
            response.data!.message ?? 'Failed to reset password',
          );
        }
        // Clear the temporary token after successful reset
        await TokenStorage.clearToken();
      } else {
        if (response.error != null) {
          throw ServerException(response.error!.message);
        }
        throw ServerException(AppStrings.serverError);
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('Reset password failed: ${e.toString()}');
    }
  }

  /// Change password - for logged-in users (requires token)
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final payload = {
        'old_password': oldPassword,
        'new_password': newPassword,
      };
      final encodedData = encodeData(payload);

      final response = await _apiService.postNew<ResetPasswordResponse>(
        AppUrls.changePassword,
        data: {'payload': encodedData},
        fromJson: (json) => ResetPasswordResponse.fromJson(
          json as Map<String, dynamic>,
        ),
      );

      if (response.isSuccess && response.data != null) {
        if (!response.data!.success) {
          throw ServerException(
            response.data!.message ?? 'Failed to change password',
          );
        }
      } else {
        if (response.error != null) {
          throw ServerException(response.error!.message);
        }
        throw ServerException(AppStrings.serverError);
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('Change password failed: ${e.toString()}');
    }
  }
}
