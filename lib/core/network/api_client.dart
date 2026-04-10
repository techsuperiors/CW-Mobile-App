import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../error/exceptions.dart';
import '../utils/token_storage.dart';
import 'network_info.dart';
import 'dart:developer' as developer;

/// API client for making HTTP requests
class ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;
  VoidCallback? onTokenExpired;

  ApiClient({
    required Dio dio,
    required NetworkInfo networkInfo,
    this.onTokenExpired,
  }) : _dio = dio,
       _networkInfo = networkInfo {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.options.baseUrl = AppConfig.baseUrl;
    _dio.options.connectTimeout = const Duration(
      milliseconds: AppConstants.connectionTimeout,
    );
    _dio.options.receiveTimeout = const Duration(
      milliseconds: AppConstants.receiveTimeout,
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available to all API requests
          final token = TokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = token;
            options.headers['authorization'] = token; // Support both cases
          }

          // Debug: Log request details
          if (kDebugMode) {
            final fullUrl = options.uri.toString();
            developer.log(
              '═══════════════════════════════════════════════════════',
            );
            developer.log('API Request: ${options.method} $fullUrl');
            if (options.queryParameters.isNotEmpty) {
              developer.log('Query Parameters: ${options.queryParameters}');
            }
            developer.log('Headers: ${options.headers}');
            if (options.data != null) {
              developer.log('Request Data: ${options.data}');
            }
            if (token != null && token.isNotEmpty) {
              developer.log(
                'Authorization: Token present (${token.length} chars)',
              );
            } else {
              developer.log('Warning: No authorization token available');
            }
            developer.log(
              '═══════════════════════════════════════════════════════',
            );
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            final fullUrl = response.requestOptions.uri.toString();
            developer.log(
              '═══════════════════════════════════════════════════════',
            );
            developer.log(
              'API Response: ${response.requestOptions.method} $fullUrl',
            );
            developer.log('Status Code: ${response.statusCode}');
            developer.log('Response Data: ${response.data}');
            developer.log(
              '═══════════════════════════════════════════════════════',
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            final fullUrl = error.requestOptions.uri.toString();
            developer.log(
              '═══════════════════════════════════════════════════════',
            );
            developer.log('API Error: ${error.requestOptions.method} $fullUrl');
            developer.log('Error Type: ${error.type}');
            developer.log('Error Message: ${error.message}');
            if (error.response != null) {
              developer.log('Error Status Code: ${error.response?.statusCode}');
              developer.log('Error Response Data: ${error.response?.data}');
            }
            developer.log(
              '═══════════════════════════════════════════════════════',
            );
          }

          // Handle 401 Unauthorized - token expired
          if (error.response?.statusCode == 401) {
            await _handleTokenExpiration();
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(AppStrings.noInternetConnection);
    }

    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(AppStrings.noInternetConnection);
    }

    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(AppStrings.noInternetConnection);
    }

    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(AppStrings.noInternetConnection);
    }

    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle token expiration or missing token
  Future<void> _handleTokenExpiration() async {
    developer.log(
      "Token expired or missing - clearing token and navigating to login",
    );
    await TokenStorage.clearAll();

    // Trigger callback to navigate to login
    if (onTokenExpired != null) {
      onTokenExpired!();
    }
  }

  /// Handle Dio errors
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(AppStrings.connectionTimeout);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          // Token expiration is handled in interceptor
          return const AuthException(AppStrings.unauthorized);
        } else if (statusCode == 404) {
          return const ServerException(AppStrings.resourceNotFound);
        } else if (statusCode != null && statusCode >= 500) {
          return const ServerException(AppStrings.serverError);
        } else {
          return ServerException(
            error.response?.data?['message'] ?? AppStrings.serverError,
          );
        }
      case DioExceptionType.cancel:
        return const NetworkException(AppStrings.requestCancelled);
      default:
        return const NetworkException(AppStrings.networkError);
    }
  }
}
