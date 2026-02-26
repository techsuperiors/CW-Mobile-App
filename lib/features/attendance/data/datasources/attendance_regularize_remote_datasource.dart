import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/data_encoder.dart';
import '../models/attendance_regularize_model.dart';
import 'package:dio/dio.dart';

/// Attendance Regularize remote data source interface
abstract class AttendanceRegularizeRemoteDataSource {
  Future<AttendanceRegularizeResponse> applyRegularize(
    AttendanceRegularizeRequest request,
  );
}

/// Attendance Regularize remote data source implementation
class AttendanceRegularizeRemoteDataSourceImpl
    implements AttendanceRegularizeRemoteDataSource {
  final ApiClient apiClient;

  AttendanceRegularizeRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AttendanceRegularizeResponse> applyRegularize(
    AttendanceRegularizeRequest request,
  ) async {
    final encodedData = encodeData(request.toJson());
    debugPrint('Encoded attendance regularize data: $encodedData');
    try {
      final response = await apiClient.post(
        AppUrls.attendanceRequest,
        data: {
          'payload': encodedData,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      debugPrint('Attendance regularize response: ${response.data}');

      final regularizeResponse = AttendanceRegularizeResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!regularizeResponse.success) {
        throw ServerException(
          regularizeResponse.message ?? 'Attendance regularization failed',
        );
      }

      return regularizeResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        'Attendance regularization failed: ${e.toString()}',
      );
    }
  }
}
