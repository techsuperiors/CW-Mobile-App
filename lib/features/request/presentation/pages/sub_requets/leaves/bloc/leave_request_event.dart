import 'package:equatable/equatable.dart';

import '../models/leave_request_model.dart';

/// Leave request events
abstract class LeaveRequestEvent extends Equatable {
  const LeaveRequestEvent();

  @override
  List<Object> get props => [];
}

/// Load leave requests event
class LoadLeaveRequests extends LeaveRequestEvent {
  const LoadLeaveRequests();
}

/// Search leave requests event
class SearchLeaveRequests extends LeaveRequestEvent {
  final String query;

  const SearchLeaveRequests(this.query);

  @override
  List<Object> get props => [query];
}

/// Filter leave requests by status event
class FilterLeaveRequestsByStatus extends LeaveRequestEvent {
  final LeaveStatus? status;

  const FilterLeaveRequestsByStatus(this.status);

  @override
  List<Object> get props => [status ?? ''];
}

/// Filter leave requests by type event
class FilterLeaveRequestsByType extends LeaveRequestEvent {
  final String? leaveType;

  const FilterLeaveRequestsByType(this.leaveType);

  @override
  List<Object> get props => [leaveType ?? ''];
}

/// Clear filters event
class ClearFilters extends LeaveRequestEvent {
  const ClearFilters();
}
