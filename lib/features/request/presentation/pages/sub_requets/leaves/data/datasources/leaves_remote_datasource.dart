import 'package:collectivWork/core/network/api_client.dart';
import 'package:collectivWork/core/constants/app_urls.dart';
import 'package:collectivWork/core/error/exceptions.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/entities/leave_entity.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import 'package:dio/dio.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../models/leave_request_model.dart';
import '../models/apply_leave_model.dart';
import '../models/leave_history_model.dart';
import '../models/team_leave_requests_page_model.dart';

abstract class LeavesRemoteDataSource {
  /// Calls the [AppUrls.leaveRequests] endpoint.
  /// Throws a [ServerException] for all error codes.
  Future<List<LeaveRequestModel>> getLeaves();

  /// Calls the team approval list endpoint for manager/admin approvals.
  Future<TeamLeaveRequestsPageModel> getTeamLeaveRequests({
    required int clientId,
    RequestAudienceScope scope = RequestAudienceScope.allUsers,
    LeaveStatus? status,
    int page = 1,
    int limit = 50,
  });

  /// Calls the [AppUrls.applyLeave] endpoint.
  /// Throws a [ServerException] for all error codes.
  Future<ApplyLeaveResponseModel> applyLeave(ApplyLeaveRequestModel request);

  /// Calls the [AppUrls.leaveHistory] endpoint fetching history for a specific leaveType.
  /// Throws a [ServerException] for all error codes.
  Future<List<LeaveHistoryModel>> getLeaveHistory(String leaveType);
}

class LeavesRemoteDataSourceImpl implements LeavesRemoteDataSource {
  final ApiClient apiClient;

  LeavesRemoteDataSourceImpl({required this.apiClient});

  String _teamLeaveStatusFilterValue(LeaveStatus? status) {
    switch (status) {
      case null:
        return 'total';
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  String _normalizeLeaveHistoryType(String leaveType) {
    final normalizedType = leaveType.trim();
    final loweredType = normalizedType.toLowerCase();

    if (loweredType == 'lop' || loweredType.contains('loss of pay')) {
      return 'lop';
    }

    return normalizedType;
  }

  @override
  Future<List<LeaveRequestModel>> getLeaves() async {
    try {
      final response = await apiClient.get(
        AppUrls.leaveRequests,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load leave requests',
        );
      }

      final List<dynamic> requestsList = data['data'] as List<dynamic>? ?? [];

      return requestsList
          .map(
            (item) => LeaveRequestModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? e.message ?? 'Server error occurred',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<TeamLeaveRequestsPageModel> getTeamLeaveRequests({
    required int clientId,
    RequestAudienceScope scope = RequestAudienceScope.allUsers,
    LeaveStatus? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final payloadData = <String, dynamic>{
        'client_id': clientId,
        'stat_filter': _teamLeaveStatusFilterValue(status),
        'leave_type': <dynamic>[],
        'approved_by': <dynamic>[],
        'leave_between': <dynamic>[],
        'status': <dynamic>[],
        'request_type': scope.leaveRequestType,
        'limit': limit,
        'page': page,
      };

      final payload = encodeData(payloadData);

      final response = await apiClient.get(
        '${AppUrls.leaveTeamRequestList}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load team leave requests',
        );
      }

      return TeamLeaveRequestsPageModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? e.message ?? 'Server error occurred',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<ApplyLeaveResponseModel> applyLeave(
    ApplyLeaveRequestModel request,
  ) async {
    try {
      final response = await apiClient.post(
        AppUrls.applyLeave,
        data: request.toJson(),
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true || response.statusCode == 200) {
        return ApplyLeaveResponseModel.fromJson(responseData);
      } else {
        throw ServerException(
          responseData['message'] as String? ?? 'Failed to apply leave',
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to apply leave: ${e.toString()}');
    }
  }

  @override
  Future<List<LeaveHistoryModel>> getLeaveHistory(String leaveType) async {
    try {
      final payload = {
        'leave_type': _normalizeLeaveHistoryType(leaveType),
      };
      final encodedPayload = encodeData(payload);

      final response = await apiClient.get(
        '${AppUrls.leaveHistory}?payload=$encodedPayload',
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
        return data
            .map(
              (item) =>
                  LeaveHistoryModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ServerException(
          responseData['message'] as String? ?? 'Failed to load leave history',
        );
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data as Map<String, dynamic>;
        throw ServerException(
          data['message'] as String? ?? 'Failed to load leave history',
        );
      }
      throw ServerException('Network error or timeout');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
