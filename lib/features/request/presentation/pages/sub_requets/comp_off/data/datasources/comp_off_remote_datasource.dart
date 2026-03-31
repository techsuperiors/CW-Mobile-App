import 'package:dio/dio.dart';

import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../attendance/data/models/attendance_request_comment_model.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../domain/entities/comp_off_detail.dart';
import '../../models/comp_off_request_model.dart';
import '../../models/comp_off_request_stats_model.dart';
import '../models/comp_off_detail_model.dart';

abstract class CompOffRemoteDataSource {
  Future<List<CompOffRequestModel>> getCompOffRequests();
  Future<CompOffTeamPageData> getTeamCompOffRequests({
    int page = 1,
    int limit = 20,
    String requestType = 'All',
  });
  Future<CompOffRequestStatsModel> getCompOffRequestStats({
    required int userId,
  });
  Future<CompOffDetail> getCompOffDetail(int compOffId);
  Future<String> createCompOffRequest({
    required String type,
    required String date,
    required String duration,
    required String reason,
    required String subject,
    required int requestTo,
    required int userId,
  });
  Future<String> updateCompOffRequest({
    required int compOffId,
    required String subject,
    required String date,
    required String duration,
    required String reason,
  });
  Future<String> uploadCompOffFile({
    required int compOffId,
    required String filePath,
  });
  Future<String> updateCompOffRequestStatus({
    required int compOffId,
    required String status,
    String type = 'earn',
  });
  Future<List<AttendanceRequestComment>> getComments({
    required int compOffId,
  });
  Future<String> addComment({
    required int compOffId,
    required String comment,
  });
}

class CompOffTeamPageData {
  final List<CompOffRequestModel> requests;
  final int totalCount;

  const CompOffTeamPageData({
    required this.requests,
    required this.totalCount,
  });
}

class CompOffRemoteDataSourceImpl implements CompOffRemoteDataSource {
  final ApiClient apiClient;

  CompOffRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CompOffRequestModel>> getCompOffRequests() async {
    try {
      final payload = encodeData({'current': 1, 'pageSize': 20, 'is_compoff': true, 'request_type': 'Team'});
      final response = await apiClient.get(
        '${AppUrls.compOffList}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load comp-off requests',
        );
      }
      final rawList = data['data'] as List<dynamic>? ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(CompOffRequestModel.fromJson)
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
  Future<CompOffTeamPageData> getTeamCompOffRequests({
    int page = 1,
    int limit = 20,
    String requestType = 'All',
  }) async {
    try {
      final payload = encodeData({
        'current': page,
        'pageSize': limit,
        'is_compoff': true,
        'request_type': requestType,
      });
      final response = await apiClient.get(
        '${AppUrls.compOffTeamList}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ??
              'Failed to load team comp-off requests',
        );
      }
      final rawList = data['data'] as List<dynamic>? ?? const [];
      final requests = rawList
          .whereType<Map<String, dynamic>>()
          .map(CompOffRequestModel.fromJson)
          .toList();
      final badgeCount =
          (data['badge_count'] as Map<String, dynamic>?)?['team_compoff'];
      final totalCount =
          badgeCount is num ? badgeCount.toInt() : requests.length;
      return CompOffTeamPageData(requests: requests, totalCount: totalCount);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<CompOffRequestStatsModel> getCompOffRequestStats({
    required int userId,
  }) async {
    try {
      final payload = encodeData({'user_id': userId});
      final response = await apiClient.get(
        '${AppUrls.compOffTeamStats}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load comp-off stats',
        );
      }
      return CompOffRequestStatsModel.fromJson(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<CompOffDetail> getCompOffDetail(int compOffId) async {
    try {
      final payload = encodeData({'compoff_id': compOffId, 'is_compoff': true});
      final response = await apiClient.get(
        '${AppUrls.compOffDetails}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load comp-off details',
        );
      }
      return CompOffDetailModel.fromResponse(data);
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> createCompOffRequest({
    required String type,
    required String date,
    required String duration,
    required String reason,
    required String subject,
    required int requestTo,
    required int userId,
  }) async {
    try {
      final payload = encodeData({
        'type': type,
        'date': date,
        'days': 1,
        'duration': duration,
        'reason': reason,
        'subject': subject,
        'request_to': requestTo,
        'user_id': userId,
        'status': 'Pending',
      });
      final response = await apiClient.post(
        AppUrls.compOffRequest,
        data: {'payload': payload},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        // backend sometimes false on downtime; still return message
        throw ServerException(
          data['message'] as String? ?? 'Failed to submit Comp-Off',
        );
      }
      return data['message'] as String? ?? 'Comp-Off request submitted successfully.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> updateCompOffRequest({
    required int compOffId,
    required String subject,
    required String date,
    required String duration,
    required String reason,
  }) async {
    try {
      final payload = encodeData({
        'compoff_id': compOffId,
        'subject': subject,
        'date': date,
        'duration': duration,
        'reason': reason,
      });
      final response = await apiClient.put(
        AppUrls.compOffRequest,
        data: {'payload': payload},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to update Comp-Off',
        );
      }
      return data['message'] as String? ?? 'Comp-Off request updated successfully.';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> uploadCompOffFile({
    required int compOffId,
    required String filePath,
  }) async {
    try {
      final payload = encodeData({'leave_id': compOffId});
      final formData = FormData.fromMap({
        'files': await MultipartFile.fromFile(filePath),
        'payload': payload,
      });
      final response = await apiClient.post(
        AppUrls.compOffFileUpload,
        data: formData,
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'File upload failed',
        );
      }
      return data['message'] as String? ?? 'File uploaded';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<String> updateCompOffRequestStatus({
    required int compOffId,
    required String status,
    String type = 'earn',
  }) async {
    try {
      final payload = encodeData({
        'type': type,
        'status': status,
        'compoff_request_id': compOffId,
      });
      final response = await apiClient.post(
        AppUrls.compOffStatus,
        data: {'payload': payload},
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>?;
      if (data == null) throw const ServerException('Invalid server response');
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to update comp-off request',
        );
      }
      return data['message'] as String? ??
          'CompOff request status successfully updated';
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      _throwMappedDioException(e);
    } catch (_) {
      throw const ServerException(AppStrings.unknownError);
    }
  }

  @override
  Future<List<AttendanceRequestComment>> getComments({

    required int compOffId,
  }) async {
    try {
      final payload = encodeData({'compoff_id': compOffId});
      final response = await apiClient.get(
        '${AppUrls.compOffCommentsList}?payload=$payload',
        options: Options(headers: const {'Content-Type': 'application/json'}),
      );
      // print("object");
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
  Future<String> addComment({
    required int compOffId,
    required String comment,
  }) async {
    try {
      final payload = encodeData({'compoff_id': compOffId, 'comment': comment});
      final response = await apiClient.post(
        AppUrls.compOffComments,
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
