import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_urls.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/data_encoder.dart';
import '../../domain/entities/attendance_request_comment.dart';
import '../../domain/entities/attendance_regularize_detail.dart';
import '../models/attendance_request_comment_model.dart';
import '../models/attendance_regularize_detail_model.dart';
import '../models/attendance_regularize_model.dart';
import 'package:dio/dio.dart';

/// Attendance Regularize remote data source interface
abstract class AttendanceRegularizeRemoteDataSource {
  Future<AttendanceRegularizeResponse> applyRegularize(
    AttendanceRegularizeRequest request,
  );
  Future<AttendanceRegularizeDetail> getRegularizeRequestDetail(int requestId);
  Future<AttendanceRegularizeResponse> updateRegularize(
    AttendanceRegularizeUpdateRequest request,
  );
  Future<String> updateRegularizeRequestStatus({
    required int requestId,
    required String status,
  });
  Future<List<AttendanceRequestComment>> getRequestComments({
    required int clientId,
    required int requestId,
  });
  Future<String> addRequestComment({
    required int requestId,
    required String comment,
    String type = 'Attendance',
  });
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
          regularizeResponse.message,
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

  @override
  Future<AttendanceRegularizeDetail> getRegularizeRequestDetail(
    int requestId,
  ) async {
    final encodedData = encodeData({'request_id': requestId});

    try {
      final response = await apiClient.get(
        '${AppUrls.regularizeRequestDetails}?payload=$encodedData',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      debugPrint('Attendance regularize response: ${response.data}');

      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ??
              'Failed to load attendance request details',
        );
      }

      return AttendanceRegularizeDetailModel.fromResponse(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to load attendance request details: ${e.toString()}',
      );
    }
  }

  @override
  Future<AttendanceRegularizeResponse> updateRegularize(
    AttendanceRegularizeUpdateRequest request,
  ) async {
    final encodedData = encodeData(request.toJson());

    try {
      final response = await apiClient.put(
        AppUrls.attendanceRequest,
        data: {'payload': encodedData},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final regularizeResponse = AttendanceRegularizeResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!regularizeResponse.success) {
        throw ServerException(regularizeResponse.message);
      }

      return regularizeResponse;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Attendance update failed: ${e.toString()}');
    }
  }

  @override
  Future<String> updateRegularizeRequestStatus({
    required int requestId,
    required String status,
  }) async {
    final encodedData = encodeData({
      'request_id': requestId,
      'status': status,
    });

    try {
      final response = await apiClient.post(
        AppUrls.regularizeRequestStatus,
        data: {'payload': encodedData},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ??
              'Failed to update attendance request status',
        );
      }

      return data['message'] as String? ??
          'Attendance request updated successfully';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Failed to update attendance request status: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<AttendanceRequestComment>> getRequestComments({
    required int clientId,
    required int requestId,
  }) async {
    final encodedData = encodeData({
      'client_id': clientId,
      'attendance_request_id': requestId,
    });

    try {
      final response = await apiClient.get(
        '${AppUrls.attendanceRequestCommentsList}?payload=$encodedData',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load comments',
        );
      }

      return parseAttendanceRequestComments(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load comments: ${e.toString()}');
    }
  }

  @override
  Future<String> addRequestComment({
    required int requestId,
    required String comment,
    String type = 'Attendance',
  }) async {
    final encodedData = encodeData({
      'request_id': requestId,
      'type': type,
      'comment': comment,
    });

    try {
      final response = await apiClient.post(
        AppUrls.attendanceRequestComments,
        data: {'payload': encodedData},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to add comment',
        );
      }

      return data['message'] as String? ?? 'Comment added successfully';
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to add comment: ${e.toString()}');
    }
  }
}
