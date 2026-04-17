import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import '../models/on_duty_request_model.dart';

/// On-Duty request states
abstract class OnDutyRequestState extends Equatable {
  const OnDutyRequestState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class OnDutyRequestInitial extends OnDutyRequestState {
  const OnDutyRequestInitial();
}

/// Loading state
class OnDutyRequestLoading extends OnDutyRequestState {
  const OnDutyRequestLoading();
}

/// Loaded state
class OnDutyRequestLoaded extends OnDutyRequestState {
  static const Object _unset = Object();

  final List<OnDutyRequestModel> onDutyRequests;
  final List<OnDutyRequestModel> filteredOnDutyRequests;
  final String? searchQuery;
  final OnDutyStatus? statusFilter;
  final bool isTeamRequestMode;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int withdrawnCount;
  final RequestAudienceScope selectedScope;
  final String? contentErrorMessage;

  const OnDutyRequestLoaded({
    required this.onDutyRequests,
    required this.filteredOnDutyRequests,
    this.searchQuery,
    this.statusFilter,
    this.isTeamRequestMode = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.withdrawnCount = 0,
    this.selectedScope = RequestAudienceScope.allUsers,
    this.contentErrorMessage,
  });

  @override
  List<Object?> get props => [
    onDutyRequests,
    filteredOnDutyRequests,
    searchQuery ?? '',
    statusFilter ?? '',
    isTeamRequestMode,
    isLoadingMore,
    isRefreshing,
    hasMore,
    currentPage,
    totalCount,
    pendingCount,
    approvedCount,
    rejectedCount,
    withdrawnCount,
    selectedScope,
    contentErrorMessage ?? '',
  ];

  OnDutyRequestLoaded copyWith({
    List<OnDutyRequestModel>? onDutyRequests,
    List<OnDutyRequestModel>? filteredOnDutyRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
    bool? isTeamRequestMode,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
    int? withdrawnCount,
    RequestAudienceScope? selectedScope,
    Object? contentErrorMessage = _unset,
  }) {
    return OnDutyRequestLoaded(
      onDutyRequests: onDutyRequests ?? this.onDutyRequests,
      filteredOnDutyRequests:
          filteredOnDutyRequests ?? this.filteredOnDutyRequests,
      searchQuery:
      identical(searchQuery, _unset) ? this.searchQuery : searchQuery as String?,
      statusFilter:
      identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as OnDutyStatus?,
      isTeamRequestMode: isTeamRequestMode ?? this.isTeamRequestMode,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      withdrawnCount: withdrawnCount ?? this.withdrawnCount,
      selectedScope: selectedScope ?? this.selectedScope,
      contentErrorMessage:
          identical(contentErrorMessage, _unset)
              ? this.contentErrorMessage
              : contentErrorMessage as String?,
    );
  }
}

/// Error state
class OnDutyRequestError extends OnDutyRequestState {
  final String message;

  const OnDutyRequestError(this.message);

  @override
  List<Object> get props => [message];
}
