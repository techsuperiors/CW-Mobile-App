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

  /// Logout
  Future<void> logout() async {
    try {
      // Clear token from storage
      await TokenStorage.clearToken();
      debugPrint('Token cleared on logout');
      // You can implement logout API call here if needed
    } catch (e) {
      // Log error but don't throw - logout should always succeed locally
      debugPrint('Logout error: $e');
    }
  }
}

