import '../../domain/entities/team_leave_requests_page_entity.dart';
import 'leave_request_model.dart';

class TeamLeaveRequestsPageModel extends TeamLeaveRequestsPageEntity {
  const TeamLeaveRequestsPageModel({
    required super.requests,
    required super.totalLeaveRequest,
    required super.approvedListCount,
    required super.pendingListCount,
    required super.rejectListCount,
    required super.totalLeaveRequestList,
  });

  factory TeamLeaveRequestsPageModel.fromJson(Map<String, dynamic> json) {
    final requestsList = json['data'] as List<dynamic>? ?? const [];
    final requests =
        requestsList
            .map(
              (item) =>
                  LeaveRequestModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final totalLeaveRequest = _readInt(
      json,
      const ['totalLeaveRequest', 'totalLeaveRequests', 'total_leave_request'],
    );
    final totalLeaveRequestList = _readInt(
      json,
      const [
        'totalLeaveRequestList',
        'total_leave_request_list',
        'totalListCount',
      ],
    );

    return TeamLeaveRequestsPageModel(
      requests: requests,
      totalLeaveRequest:
          totalLeaveRequest > 0
              ? totalLeaveRequest
              : (totalLeaveRequestList > 0
                  ? totalLeaveRequestList
                  : requests.length),
      approvedListCount: _readInt(
        json,
        const ['approvedListCount', 'approved_count', 'approveListCount'],
      ),
      pendingListCount: _readInt(
        json,
        const ['pendingListCount', 'pending_count'],
      ),
      rejectListCount: _readInt(
        json,
        const ['rejectListCount', 'rejectedListCount', 'rejected_count'],
      ),
      totalLeaveRequestList:
          totalLeaveRequestList > 0 ? totalLeaveRequestList : requests.length,
    );
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      final normalized = _toInt(value);
      if (normalized > 0 || value == 0 || value == '0' || value == 0.0) {
        return normalized;
      }
    }
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
