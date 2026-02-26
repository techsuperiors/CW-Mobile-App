import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

import '../../../../core/utils/data_encoder.dart';

/// Punch-in request model
class PunchInRequest {
  final String punchInLocation;
  final double latitude;
  final double longitude;
  final String punchType;

  PunchInRequest({
    required this.punchInLocation,
    required this.latitude,
    required this.longitude,
    required this.punchType,
  });

  Map<String, dynamic> toJson() {
    return {
      'punch_in_location': punchInLocation,
      'userLocation': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'punch_type': punchType,
    };
  }
}

/// Punch-in response model
class PunchInResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  PunchInResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory PunchInResponse.fromJson(Map<String, dynamic> json) {
    return PunchInResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Punch-out request model
class PunchOutRequest {
  final String punchOutLocation;
  final double latitude;
  final double longitude;

  PunchOutRequest({
    required this.punchOutLocation,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'punch_out_location': punchOutLocation,
      'userLocation': {
        'latitude': latitude,
        'longitude': longitude,
      },
    };
  }
}

/// Punch-out response model
class PunchOutResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  PunchOutResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory PunchOutResponse.fromJson(Map<String, dynamic> json) {
    return PunchOutResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

/// Attendance remote data source interface
abstract class AttendanceRemoteDataSource {
  Future<PunchInResponse> punchIn(PunchInRequest request);
  Future<PunchOutResponse> punchOut(PunchOutRequest request);
}

/// Attendance remote data source implementation
class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PunchInResponse> punchIn(PunchInRequest request) async {
    final encodedData = encodeData(request);
    debugPrint('Encoded data: $encodedData');
    try {
      final response = await apiClient.post(
        AppUrls.punchIn,
        data: {
          'payload': encodedData,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      debugPrint("response is ${response.data}");
      final punchInResponse = PunchInResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!punchInResponse.success) {
        throw ServerException(
          punchInResponse.message ?? 'Punch-in failed',
        );
      }

      return punchInResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Punch-in failed: ${e.toString()}');
    }
  }

  @override
  Future<PunchOutResponse> punchOut(PunchOutRequest request) async {
    final encodedData = encodeData(request);
    debugPrint('Punch-out encoded data: $encodedData');
    try {
      final response = await apiClient.post(
        AppUrls.punchOut,
        data: {
          'payload': encodedData,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      debugPrint("Punch-out response: ${response.data}");
      final punchOutResponse = PunchOutResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!punchOutResponse.success) {
        throw ServerException(
          punchOutResponse.message ?? 'Punch-out failed',
        );
      }

      return punchOutResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Punch-out failed: ${e.toString()}');
    }
  }
}

