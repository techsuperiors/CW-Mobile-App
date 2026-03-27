import 'package:equatable/equatable.dart';
import '../../domain/entities/leave_entity.dart';

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
  static const Object _unset = Object();

  final List<LeaveEntity> leaveRequests;
  final List<LeaveEntity> filteredLeaveRequests;
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
    List<LeaveEntity>? leaveRequests,
    List<LeaveEntity>? filteredLeaveRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
    Object? typeFilter = _unset,
  }) {
    return LeaveRequestLoaded(
      leaveRequests: leaveRequests ?? this.leaveRequests,
      filteredLeaveRequests:
          filteredLeaveRequests ?? this.filteredLeaveRequests,
      searchQuery:
          identical(searchQuery, _unset) ? this.searchQuery : searchQuery as String?,
      statusFilter:
          identical(statusFilter, _unset)
              ? this.statusFilter
              : statusFilter as LeaveStatus?,
      typeFilter:
          identical(typeFilter, _unset) ? this.typeFilter : typeFilter as String?,
    );
  }
}

/// Applying state
class LeaveRequestApplying extends LeaveRequestState {
  const LeaveRequestApplying();
}

/// Applied successfully state
class LeaveRequestApplied extends LeaveRequestState {
  final dynamic result;

  const LeaveRequestApplied({required this.result});

  @override
  List<Object> get props => [result];
}

/// Error state
class LeaveRequestError extends LeaveRequestState {
  final String message;

  const LeaveRequestError(this.message);

  @override
  List<Object> get props => [message];
}
