import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../attendance/data/models/attendance_request_comment_model.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../domain/entities/overtime_detail.dart';
import '../../models/overtime_request_model.dart';
import '../../models/overtime_request_stats_model.dart';
import '../models/overtime_detail_model.dart';

abstract class OvertimeRemoteDataSource {
  Future<List<OvertimeRequestModel>> getOvertimeRequests({
    int page = 1,
    int limit = 20,
  });

  Future<List<OvertimeRequestModel>> getTeamOvertimeRequests({
    int page = 1,
    int limit = 20,
    String requestType = 'All',
  });

  Future<OvertimeRequestStatsModel> getOvertimeRequestStats({
    required int clientId,
    String requestType = 'User',
  });

  Future<OvertimeDetail> getOvertimeRequestDetail(int requestId);

  Future<String> createOvertimeRequest({
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required String subject,
    required String description,
    required int userId,
  });

  Future<String> updateOvertimeRequest({
    required int requestId,
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required int userId,
    required String description,
  });

  Future<String> withdrawOvertimeRequest({
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
  });
}

class OvertimeRemoteDataSourceImpl implements OvertimeRemoteDataSource {
  final ApiClient apiClient;

  OvertimeRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<OvertimeRequestModel>> getOvertimeRequests({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final payload = encodeData({'page': page, 'limit': limit});
      final response = await apiClient.get(
        '${AppUrls.overtimeRequests}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      debugPrint("payload:-- $payload");
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load overtime requests',
        );
      }
      final rawList = data['data'] as List<dynamic>? ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(OvertimeRequestModel.fromJson)
          .toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<List<OvertimeRequestModel>> getTeamOvertimeRequests({
    int page = 1,
    int limit = 20,
    String requestType = 'All',
  }) async {
    try {
      final payload = encodeData({
        'request_type': requestType,
        'page': page,
        'limit': limit,
      });
      final response = await apiClient.get(
        '${AppUrls.overtimeTeamRequests}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load team overtime requests',
        );
      }
      final rawList = data['data'] as List<dynamic>? ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(OvertimeRequestModel.fromJson)
          .toList();
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<OvertimeRequestStatsModel> getOvertimeRequestStats({
    required int clientId,
    String requestType = 'User',
  }) async {
    try {
      final payload = encodeData({
        'client_id': clientId,
        'users': <dynamic>[],
        'status': <dynamic>[],
        'date': <dynamic>[],
        'approved_by': <dynamic>[],
        'rejected_by': <dynamic>[],
        'request_type': requestType,
      });
      final response = await apiClient.get(
        '${AppUrls.overtimeRequestStats}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load overtime stats',
        );
      }
      return OvertimeRequestStatsModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<OvertimeDetail> getOvertimeRequestDetail(int requestId) async {
    try {
      final payload = encodeData({'id': requestId});
      final response = await apiClient.get(
        '${AppUrls.overtimeRequestDetails}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load overtime details',
        );
      }
      return OvertimeDetailModel.fromResponse(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> createOvertimeRequest({
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required String subject,
    required String description,
    required int userId,
  }) async {
    try {
      final payload = encodeData({
        'request_date': requestDate,
        'check_in': checkIn,
        'check_out': checkOut,
        'subject': subject,
        'description': description,
        'user_id': userId,
      });
      final response = await apiClient.post(
        AppUrls.overtimeRequestCreate,
        data: {'payload': payload},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to create overtime request',
        );
      }
      return data['message'] as String? ?? 'Overtime request created successfully.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> updateOvertimeRequest({
    required int requestId,
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required int userId,
    required String description,
  }) async {
    try {
      final payload = encodeData({
        'request_id': requestId,
        'request_date': requestDate,
        'check_in': checkIn,
        'check_out': checkOut,
        'user_id': userId,
        'description': description,
      });
      final response = await apiClient.put(
        AppUrls.overtimeRequestUpdate,
        data: {'payload': payload},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to update overtime request',
        );
      }
      return data['message'] as String? ?? 'Overtime request updated successfuly.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> withdrawOvertimeRequest({
    required int requestId,
    required String status,
  }) async {
    try {
      final payload = encodeData({'request_id': requestId, 'status': status});
      final response = await apiClient.post(
        AppUrls.overtimeRequestStatus,
        data: {'payload': payload},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to update overtime request',
        );
      }
      return data['message'] as String? ??
          'Overtime request updated successfully';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<List<AttendanceRequestComment>> getRequestComments({
    required int clientId,
    required int requestId,
  }) async {
    try {
      final payload = encodeData({
        'client_id': clientId,
        'attendance_request_id': requestId,
        "type": "Overtime"
      });
      final response = await apiClient.get(
        '${AppUrls.attendanceRequestCommentsList}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load comments',
        );
      }
      return parseAttendanceRequestComments(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> addRequestComment({
    required int requestId,
    required String comment,
  }) async {
    try {
      final payload = encodeData({
        'request_id': requestId,
        'type': 'Overtime',
        'comment': comment,
      });
      final response = await apiClient.post(
        AppUrls.attendanceRequestComments,
        data: {'payload': payload},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to add comment',
        );
      }
      return data['message'] as String? ?? 'Comment added successfully';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }
}

Never _throwMappedDioException(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    throw const NetworkException(AppStrings.connectionTimeout);
  }
  if (e.type == DioExceptionType.cancel) {
    throw const NetworkException(AppStrings.requestCancelled);
  }
  if (e.response?.statusCode == 401) {
    throw const AuthException(AppStrings.unauthorized);
  }
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'] as String?;
    if ((e.response?.statusCode ?? 0) >= 500) {
      throw ServerException(message ?? AppStrings.serverError);
    }
    throw ValidationException(message ?? AppStrings.unknownError);
  }
  throw const NetworkException(AppStrings.networkError);
}
