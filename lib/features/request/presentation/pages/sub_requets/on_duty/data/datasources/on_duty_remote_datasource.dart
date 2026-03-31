import 'package:dio/dio.dart';

import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../../../../../../attendance/data/models/attendance_request_comment_model.dart';
import '../../models/on_duty_request_model.dart';
import '../../models/on_duty_request_stats_model.dart';
import '../../domain/entities/on_duty_detail.dart';
import '../models/on_duty_detail_model.dart';

abstract class OnDutyRemoteDataSource {
  Future<List<OnDutyRequestModel>> getOnDutyRequests();

  Future<List<OnDutyRequestModel>> getTeamOnDutyRequests({
    required int clientId,
    int page = 1,
    int limit = 50,
    String requestType = 'All',
  });

  Future<OnDutyRequestStatsModel> getOnDutyRequestStats({
    required int clientId,
    String requestType = 'User',
  });

  Future<OnDutyDetail> getOnDutyRequestDetail(int requestId);

  Future<String> updateOnDutyRequestStatus({
    required int requestId,
    required String status,
  });

  Future<List<AttendanceRequestComment>> getRequestComments({
    required int clientId,
    required int requestId,
    String type = 'OnDuty',
  });

  Future<String> addRequestComment({
    required int requestId,
    required String comment,
    String type = 'OnDuty',
  });

  Future<String> raiseOnDutyRequest({
    required String subject,
    required String requestType, // 'single' or 'multiple'
    required String description,
    required String startDate, // yyyy-MM-dd
    required String endDate, // yyyy-MM-dd
    required String startHalf, // 'first_half' or 'second_half'
    required String endHalf,
    required int userId,
  });
}

class OnDutyRemoteDataSourceImpl implements OnDutyRemoteDataSource {
  final ApiClient apiClient;

  OnDutyRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<OnDutyRequestModel>> getOnDutyRequests() async {
    final encodedData = encodeData({
      'page': 1,
      'limit': 50,
    });

    try {
      final response = await apiClient.get(
        '${AppUrls.onDutyRequests}?payload=$encodedData',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;

      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load On-Duty requests',
        );
      }

      final rawList = data['data'] as List<dynamic>? ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(OnDutyRequestModel.fromJson)
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
  Future<List<OnDutyRequestModel>> getTeamOnDutyRequests({
    required int clientId,
    int page = 1,
    int limit = 50,
    String requestType = 'All',
  }) async {
    final encodedData = encodeData({
      'client_id': clientId,
      'request_for': [],
      'users': [],
      'date': DateTime.now().toIso8601String().split('T').first,
      'approved_by': [],
      'rejected_by': [],
      'status': [],
      'request_type': requestType,
      'page': page,
      'limit': limit,
    });

    try {
      final response = await apiClient.get(
        '${AppUrls.onDutyTeamRequests}?payload=$encodedData',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load team On-Duty requests',
        );
      }

      final rawList = data['data'] as List<dynamic>? ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(OnDutyRequestModel.fromJson)
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
  Future<OnDutyRequestStatsModel> getOnDutyRequestStats({
    required int clientId,
    String requestType = 'User',
  }) async {
    final encodedData = encodeData({
      'client_id': clientId,
      'requested_to': [],
      'requested_by': [],
      'approved_by': [],
      'rejected_by': [],
      'request_type': requestType,
      'status': [],
    });

    try {
      final response = await apiClient.get(
        '${AppUrls.onDutyRequestStats}?payload=$encodedData',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load On-Duty stats',
        );
      }

      final stats = data['data'] as Map<String, dynamic>? ?? const {};
      return OnDutyRequestStatsModel.fromJson(stats);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<OnDutyDetail> getOnDutyRequestDetail(int requestId) async {
    final encodedData = encodeData({'request_id': requestId});

    try {
      final response = await apiClient.get(
        '${AppUrls.onDutyRequestDetails}?payload=$encodedData',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load On-Duty details',
        );
      }

      return OnDutyDetailModel.fromResponse(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> updateOnDutyRequestStatus({
    required int requestId,
    required String status,
  }) async {
    final encodedData = encodeData({
      'request_id': requestId,
      'status': status,
    });

    try {
      final response = await apiClient.post(
        AppUrls.onDutyRequestStatus,
        data: {'payload': encodedData},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to update On-Duty request',
        );
      }

      return data['message'] as String? ?? 'On Duty request updated successfully';
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
    String type = 'OnDuty',
  }) async {
    final encodedData = encodeData({
      'client_id': clientId,
      'attendance_request_id': requestId,
      'type': type,
    });

    try {
      final response = await apiClient.get(
        '${AppUrls.attendanceRequestCommentsList}?payload=$encodedData',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
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
    String type = 'OnDuty',
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
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
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

  @override
  Future<String> raiseOnDutyRequest({
    required String subject,
    required String requestType,
    required String description,
    required String startDate,
    required String endDate,
    required String startHalf,
    required String endHalf,
    required int userId,
  }) async {
    // API expects wfh_request_date to be the previous day at 18:30:00.000Z (Midnight IST)
    final startDateTime = DateTime.parse(startDate);
    final endDateTime = DateTime.parse(endDate);
    
    final wfhRequestDate = startDateTime.subtract(const Duration(days: 1));
    final wfhToRequestDate = endDateTime.subtract(const Duration(days: 1));

    final fromDateIso = '${wfhRequestDate.toString().substring(0, 10)}T18:30:00.000Z';
    final toDateIso = '${wfhToRequestDate.toString().substring(0, 10)}T18:30:00.000Z';

    final payloadMap = <String, dynamic>{
      'subject': subject,
      'request_type': requestType,
      'description': description,
      'wfh_request_date': fromDateIso,
      'start_half': startHalf,
      'end_half': endHalf,
      'user_id': userId,
      'start_date': startDate,
      'end_date': endDate,
    };

    if (requestType != 'single') {
      payloadMap['wfh_to_request_date'] = toDateIso;
    }

    final encodedData = encodeData(payloadMap);

    try {
      final response = await apiClient.post(
        AppUrls.onDutyRequestRaise,
        data: {'payload': encodedData},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw const ServerException('Invalid server response');
      }
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to raise On-Duty request',
        );
      }

      return data['message'] as String? ?? 'On Duty request raised successfully';
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
