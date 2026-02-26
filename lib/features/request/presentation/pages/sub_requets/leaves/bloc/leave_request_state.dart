import 'package:equatable/equatable.dart';

import '../models/leave_request_model.dart';

/// Leave request states
abstract class LeaveRequestState extends Equatable {
  const LeaveRequestState();

  @override
  List<Object> get props => [];
}

/// Initial state
class LeaveRequestInitial extends LeaveRequestState {
  const LeaveRequestInitial();
}

/// Loading state
class LeaveRequestLoading extends LeaveRequestState {
  const LeaveRequestLoading();
}

/// Loaded state
class LeaveRequestLoaded extends LeaveRequestState {
  final List<LeaveRequestModel> leaveRequests;
  final List<LeaveRequestModel> filteredLeaveRequests;
  final String? searchQuery;
  final LeaveStatus? statusFilter;
  final String? typeFilter;

  const LeaveRequestLoaded({
    required this.leaveRequests,
    required this.filteredLeaveRequests,
    this.searchQuery,
    this.statusFilter,
    this.typeFilter,
  });

  @override
  List<Object> get props => [
        leaveRequests,
        filteredLeaveRequests,
        searchQuery ?? '',
        statusFilter ?? '',
        typeFilter ?? '',
      ];

  LeaveRequestLoaded copyWith({
    List<LeaveRequestModel>? leaveRequests,
    List<LeaveRequestModel>? filteredLeaveRequests,
    String? searchQuery,
    LeaveStatus? statusFilter,
    String? typeFilter,
  }) {
    return LeaveRequestLoaded(
      leaveRequests: leaveRequests ?? this.leaveRequests,
      filteredLeaveRequests: filteredLeaveRequests ?? this.filteredLeaveRequests,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }
}

/// Error state
class LeaveRequestError extends LeaveRequestState {
  final String message;

  const LeaveRequestError(this.message);

  @override
  List<Object> get props => [message];
}
