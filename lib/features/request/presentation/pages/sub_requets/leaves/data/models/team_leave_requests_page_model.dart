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

    return TeamLeaveRequestsPageModel(
      requests:
          requestsList
              .map(
                (item) =>
                    LeaveRequestModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
      totalLeaveRequest: _toInt(json['totalLeaveRequest']),
      approvedListCount: _toInt(json['approvedListCount']),
      pendingListCount: _toInt(json['pendingListCount']),
      rejectListCount: _toInt(json['rejectListCount']),
      totalLeaveRequestList: _toInt(json['totalLeaveRequestList']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
