import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
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
  final bool isTeamRequestMode;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int currentPage;
  final int totalLeaveRequest;
  final int approvedListCount;
  final int pendingListCount;
  final int rejectListCount;
  final RequestAudienceScope selectedScope;
  final String? contentErrorMessage;

  const LeaveRequestLoaded({
    required this.leaveRequests,
    required this.filteredLeaveRequests,
    this.searchQuery,
    this.statusFilter,
    this.typeFilter,
    this.isTeamRequestMode = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.totalLeaveRequest = 0,
    this.approvedListCount = 0,
    this.pendingListCount = 0,
    this.rejectListCount = 0,
    this.selectedScope = RequestAudienceScope.allUsers,
    this.contentErrorMessage,
  });

  @override
  List<Object> get props => [
    leaveRequests,
    filteredLeaveRequests,
    searchQuery ?? '',
    statusFilter ?? '',
    typeFilter ?? '',
    isTeamRequestMode,
    isLoadingMore,
    isRefreshing,
    hasMore,
    currentPage,
    totalLeaveRequest,
    approvedListCount,
    pendingListCount,
    rejectListCount,
    selectedScope,
    contentErrorMessage ?? '',
  ];

  LeaveRequestLoaded copyWith({
    List<LeaveEntity>? leaveRequests,
    List<LeaveEntity>? filteredLeaveRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
    Object? typeFilter = _unset,
    bool? isTeamRequestMode,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? currentPage,
    int? totalLeaveRequest,
    int? approvedListCount,
    int? pendingListCount,
    int? rejectListCount,
    RequestAudienceScope? selectedScope,
    Object? contentErrorMessage = _unset,
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
      isTeamRequestMode: isTeamRequestMode ?? this.isTeamRequestMode,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalLeaveRequest: totalLeaveRequest ?? this.totalLeaveRequest,
      approvedListCount: approvedListCount ?? this.approvedListCount,
      pendingListCount: pendingListCount ?? this.pendingListCount,
      rejectListCount: rejectListCount ?? this.rejectListCount,
      selectedScope: selectedScope ?? this.selectedScope,
      contentErrorMessage:
          identical(contentErrorMessage, _unset)
              ? this.contentErrorMessage
              : contentErrorMessage as String?,
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
