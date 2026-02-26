import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import 'package:dio/dio.dart';

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

/// Attendance remote data source interface
abstract class AttendanceRemoteDataSource {
  Future<PunchInResponse> punchIn(PunchInRequest request);
}

/// Attendance remote data source implementation
class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PunchInResponse> punchIn(PunchInRequest request) async {
    debugPrint("punch in request ${request.toJson()}");
    try {
      final response = await apiClient.post(
        AppUrls.punchIn,
        data: request.toJson(),
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
}

