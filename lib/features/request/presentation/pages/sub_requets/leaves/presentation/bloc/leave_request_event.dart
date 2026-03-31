import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import '../../domain/entities/leave_entity.dart';

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

class LoadTeamLeaveRequests extends LeaveRequestEvent {
  final int clientId;
  final RequestAudienceScope scope;
  final int page;
  final int limit;

  const LoadTeamLeaveRequests({
    required this.clientId,
    this.scope = RequestAudienceScope.allUsers,
    this.page = 1,
    this.limit = 50,
  });

  @override
  List<Object> get props => [clientId, scope, page, limit];
}

class LoadMoreTeamLeaveRequests extends LeaveRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreTeamLeaveRequests({
    required this.clientId,
    this.limit = 5,
  });

  @override
  List<Object> get props => [clientId, limit];
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

/// Apply a new leave event
class ApplyLeave extends LeaveRequestEvent {
  final String leaveType;
  final String clubing;
  final bool isClubbing;
  final String startDate;
  final String endDate;
  final String subject;
  final String reason;
  final String startHalf;
  final String endHalf;
  final String dayType;
  final String description;
  final String shortCode;
  final int requestTo;
  final List<String> rHDates;

  const ApplyLeave({
    required this.leaveType,
    required this.clubing,
    required this.isClubbing,
    required this.startDate,
    required this.endDate,
    required this.subject,
    required this.reason,
    required this.startHalf,
    required this.endHalf,
    required this.dayType,
    required this.description,
    required this.shortCode,
    required this.requestTo,
    required this.rHDates,
  });

  @override
  List<Object> get props => [
    leaveType,
    clubing,
    isClubbing,
    startDate,
    endDate,
    subject,
    reason,
    startHalf,
    endHalf,
    dayType,
    description,
    shortCode,
    requestTo,
    rHDates,
  ];
}
