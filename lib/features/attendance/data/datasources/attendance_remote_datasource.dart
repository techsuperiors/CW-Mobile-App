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
  final String? punchIn;

  PunchInRequest({
    required this.punchInLocation,
    required this.latitude,
    required this.longitude,
    required this.punchType,
    this.punchIn,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'punch_in_location': punchInLocation,
      'userLocation': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'punch_type': punchType,
      'device_type': 'app',
    };
    if (punchIn != null && punchIn!.trim().isNotEmpty) {
      data['punch_in_time'] = punchIn;
    }
    return data;
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
  final String? punchOut;

  PunchOutRequest({
    required this.punchOutLocation,
    required this.latitude,
    required this.longitude,
    this.punchOut,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'punch_out_location': punchOutLocation,
      'userLocation': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'device_type': 'app',
    };
    if (punchOut != null && punchOut!.trim().isNotEmpty) {
      data['punch_out_time'] = punchOut;
    }
    return data;
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
    final payload = request.toJson();
    debugPrint('Punch-in payload before encode: $payload');
    final encodedData = encodeData(payload);
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
      debugPrint("response is ${response.statusCode}");
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
    final payload = request.toJson();
    debugPrint('Punch-out payload before encode: $payload');
    final encodedData = encodeData(payload);
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
