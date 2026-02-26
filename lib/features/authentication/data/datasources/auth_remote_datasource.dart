import '../../domain/entities/user.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import 'package:dio/dio.dart';

/// Login response model
class LoginResponse {
  final bool success;
  final String? message;
  final String? token;

  LoginResponse({
    required this.success,
    this.message,
    this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      token: json['data'] as String?,
    );
  }
}

/// Authentication remote data source interface
abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(String username, String password);
  Future<void> logout();
}

/// Authentication remote data source implementation
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await apiClient.post(
        AppUrls.login,
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final loginResponse = LoginResponse.fromJson(response.data as Map<String, dynamic>);

      if (!loginResponse.success) {
        throw ServerException(
          loginResponse.message ?? 'Login failed',
        );
      }

      if (loginResponse.token == null || loginResponse.token!.isEmpty) {
        throw ServerException('Token not received from server');
      }

      return loginResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(AppUrls.logout);
    } catch (e) {
      // Log error but don't throw - logout should always succeed locally
    }
  }
}

