import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../error/exceptions.dart';
import '../utils/token_storage.dart';
import 'network_info.dart';

/// API client for making HTTP requests
class ApiClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;

  ApiClient({
    required Dio dio,
    required NetworkInfo networkInfo,
  })  : _dio = dio,
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
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('API Request: ${options.method} $fullUrl');
            if (options.queryParameters.isNotEmpty) {
              debugPrint('Query Parameters: ${options.queryParameters}');
            }
            debugPrint('Headers: ${options.headers}');
            if (options.data != null) {
              debugPrint('Request Data: ${options.data}');
            }
            if (token != null && token.isNotEmpty) {
              debugPrint('Authorization: Token present (${token.length} chars)');
            } else {
              debugPrint('Warning: No authorization token available');
            }
            debugPrint('═══════════════════════════════════════════════════════');
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            final fullUrl = response.requestOptions.uri.toString();
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('API Response: ${response.requestOptions.method} $fullUrl');
            debugPrint('Status Code: ${response.statusCode}');
            debugPrint('Response Data: ${response.data}');
            debugPrint('═══════════════════════════════════════════════════════');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            final fullUrl = error.requestOptions.uri.toString();
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('API Error: ${error.requestOptions.method} $fullUrl');
            debugPrint('Error Type: ${error.type}');
            debugPrint('Error Message: ${error.message}');
            if (error.response != null) {
              debugPrint('Error Status Code: ${error.response?.statusCode}');
              debugPrint('Error Response Data: ${error.response?.data}');
            }
            debugPrint('═══════════════════════════════════════════════════════');
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

