import 'package:equatable/equatable.dart';

import 'leave_entity.dart';

class TeamLeaveRequestsPageEntity extends Equatable {
  final List<LeaveEntity> requests;
  final int totalLeaveRequest;
  final int approvedListCount;
  final int pendingListCount;
  final int rejectListCount;
  final int totalLeaveRequestList;

  const TeamLeaveRequestsPageEntity({
    required this.requests,
    required this.totalLeaveRequest,
    required this.approvedListCount,
    required this.pendingListCount,
    required this.rejectListCount,
    required this.totalLeaveRequestList,
  });

  @override
  List<Object> get props => [
    requests,
    totalLeaveRequest,
    approvedListCount,
    pendingListCount,
    rejectListCount,
    totalLeaveRequestList,
  ];
}
