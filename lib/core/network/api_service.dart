import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../error/exceptions.dart';
import '../utils/token_storage.dart';
import 'network_info.dart';
import 'api_exception.dart';

class ApiService {
  final NetworkInfo _networkInfo;
  VoidCallback? onTokenExpired;

  ApiService({
    required NetworkInfo networkInfo,
    this.onTokenExpired,
  }) : _networkInfo = networkInfo;

  Future<ApiResponse<T>> getNew<T>(
    String endpoint, {
    required T Function(dynamic json) fromJson,
  }) async {
    // Check network connectivity
    if (!await _networkInfo.isConnected) {
      return ApiResponse(
        error: ApiException(
          0,
          AppStrings.noInternetConnection,
        ),
      );
    }

    try {
      final fullUrl = endpoint.startsWith('http')
          ? endpoint
          : '${AppConfig.baseUrl}$endpoint';

      // Get headers with token
      final headers = _getHeaders();

      // Debug: Log request details
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('API Request: GET $fullUrl');
        debugPrint('Headers: $headers');
        debugPrint('═══════════════════════════════════════════════════════');
      }
      log("GET Request: $fullUrl");

      final response = await http
          .get(
            Uri.parse(fullUrl),
            headers: headers,
          )
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
            onTimeout: () {
              throw const NetworkException(AppStrings.connectionTimeout);
            },
          );

      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('API Response: GET $fullUrl');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('═══════════════════════════════════════════════════════');
      }

      return _handleNewResponse<T>(response, fromJson, endpoint: endpoint);
    } on NetworkException catch (e) {
      if (kDebugMode) {
        debugPrint("GET Request Network Error: $e");
      }
      log("GET Request Network Error: $e");
      return ApiResponse(
        error: ApiException(0, e.message),
      );
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint("GET Request Client Error: $e");
      }
      log("GET Request Client Error: $e");
      return ApiResponse(
        error: ApiException(0, AppStrings.networkError),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("GET Request Error: $e");
      }
      log("GET Request Error: $e");
      return ApiResponse(
        error: ApiException(0, AppStrings.networkError),
      );
    }
  }

  Future<ApiResponse<T>> postNew<T>(
    String endpoint, {
    required Map<String, dynamic> data,
    required T Function(dynamic json) fromJson,
  }) async {
    // Check network connectivity
    if (!await _networkInfo.isConnected) {
      return ApiResponse(
        error: ApiException(
          0,
          AppStrings.noInternetConnection,
        ),
      );
    }

    try {
      final fullUrl = endpoint.startsWith('http')
          ? endpoint
          : '${AppConfig.baseUrl}$endpoint';

      // Get headers with token
      final headers = _getHeaders();

      // Debug: Log request details
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('API Request: POST $fullUrl');
        debugPrint('Headers: $headers');
        debugPrint('Request Data: ${jsonEncode(data)}');
        debugPrint('═══════════════════════════════════════════════════════');
      }
      log("POST Request: $fullUrl");
      log("POST Data: ${jsonEncode(data)}");

      final response = await http
          .post(
            Uri.parse(fullUrl),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(
            Duration(milliseconds: AppConstants.connectionTimeout),
            onTimeout: () {
              throw const NetworkException(AppStrings.connectionTimeout);
            },
          );

      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('API Response: POST $fullUrl');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('═══════════════════════════════════════════════════════');
      }

      return _handleNewResponse<T>(response, fromJson, endpoint: endpoint);
    } on NetworkException catch (e) {
      if (kDebugMode) {
        debugPrint("POST Request Network Error: $e");
      }
      log("POST Request Network Error: $e");
      return ApiResponse(
        error: ApiException(0, e.message),
      );
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint("POST Request Client Error: $e");
      }
      log("POST Request Client Error: $e");
      return ApiResponse(
        error: ApiException(0, AppStrings.networkError),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("POST Request Error: $e");
      }
      log("POST Request Error: $e");
      return ApiResponse(
        error: ApiException(0, AppStrings.networkError),
      );
    }
  }

  Future<ApiResponse<T>> _handleNewResponse<T>(
    http.Response response,
    T Function(dynamic json) fromJson, {
    required String endpoint,
  }) async {
    if (kDebugMode) {
      debugPrint("API Response Handler: $endpoint");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
    }
    log("API Response (${response.statusCode}): ${response.body}");

    try {
      // Handle token expiration (401 Unauthorized)
      if (response.statusCode == 401) {
        await _handleTokenExpiration();
        final jsonBody = jsonDecode(response.body);
        final errorMessage = _extractErrorMessage(
          jsonBody,
          response.statusCode,
        );
        return ApiResponse(
          error: ApiException(response.statusCode, errorMessage),
        );
      }

      // Handle different status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonBody = jsonDecode(response.body);
        return ApiResponse(data: fromJson(jsonBody));
      }

      // Parse error response
      final jsonBody = jsonDecode(response.body);
      final errorMessage = _extractErrorMessage(
        jsonBody,
        response.statusCode,
      );

      debugPrint('Error Message: $errorMessage');
      return ApiResponse(
        error: ApiException(response.statusCode, errorMessage),
      );
    } on FormatException catch (e) {
      log("JSON Parse Error: $e");
      return ApiResponse(
        error: ApiException(
          response.statusCode,
          AppStrings.serverError,
        ),
      );
    } catch (e) {
      log("Response Handling Error: $e");
      return ApiResponse(
        error: ApiException(
          response.statusCode,
          AppStrings.serverError,
        ),
      );
    }
  }

  /// Get headers with authentication token
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Add authorization token if available
    final token = TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      // Add token directly without Bearer prefix (as per API requirements)
      headers['Authorization'] = token;
      headers['authorization'] = token; // Support both cases
      if (kDebugMode) {
        log('API Request: Authorization token added to headers');
      }
    } else {
      if (kDebugMode) {
        log('Warning: No authorization token available');
      }
    }

    return headers;
  }

  /// Handle token expiration
  Future<void> _handleTokenExpiration() async {
    log("Token expired - clearing token and navigating to login");
    await TokenStorage.clearToken();
    
    // Trigger callback to navigate to login
    if (onTokenExpired != null) {
      onTokenExpired!();
    }
  }

  /// Extract error message from response
  String _extractErrorMessage(
    Map<String, dynamic> jsonBody,
    int statusCode,
  ) {
    // Try different common error message fields
    final message = jsonBody['message']?.toString() ??
        jsonBody['error']?.toString() ??
        jsonBody['detail']?.toString() ??
        jsonBody['error_message']?.toString();

    if (message != null && message.isNotEmpty) {
      return message;
    }

    // Return status code specific messages
    switch (statusCode) {
      case 400:
        return AppStrings.serverError; // Bad Request
      case 401:
        return AppStrings.unauthorized;
      case 403:
        return AppStrings.serverError; // Forbidden
      case 404:
        return AppStrings.resourceNotFound;
      case 422:
        return AppStrings.serverError; // Validation Error
      case 500:
      case 502:
      case 503:
        return AppStrings.serverError;
      default:
        return AppStrings.serverError;
    }
  }
}

