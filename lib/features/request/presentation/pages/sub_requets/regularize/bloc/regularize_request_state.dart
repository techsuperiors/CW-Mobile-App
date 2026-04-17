import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../models/regularize_request_model.dart';

/// Regularize request states
abstract class RegularizeRequestState extends Equatable {
  const RegularizeRequestState();

  @override
  List<Object> get props => [];
}

/// Initial state
class RegularizeRequestInitial extends RegularizeRequestState {
  const RegularizeRequestInitial();
}

/// Loading state
class RegularizeRequestLoading extends RegularizeRequestState {
  const RegularizeRequestLoading();
}

/// Loaded state
class RegularizeRequestLoaded extends RegularizeRequestState {
  static const Object _unset = Object();
  final List<RegularizeRequestModel> regularizeRequests;
  final List<RegularizeRequestModel> filteredRegularizeRequests;
  final String? searchQuery;
  final RegularizeStatus? statusFilter;
  final RequestAudienceScope selectedScope;
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
  final String? contentErrorMessage;

  const RegularizeRequestLoaded({
    required this.regularizeRequests,
    required this.filteredRegularizeRequests,
    this.searchQuery,
    this.statusFilter,
    this.selectedScope = RequestAudienceScope.allUsers,
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
    this.contentErrorMessage,
  });

  @override
  List<Object> get props => [
        regularizeRequests,
        filteredRegularizeRequests,
        searchQuery ?? '',
        statusFilter ?? '',
        selectedScope,
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
        contentErrorMessage ?? '',
      ];

  RegularizeRequestLoaded copyWith({
    List<RegularizeRequestModel>? regularizeRequests,
    List<RegularizeRequestModel>? filteredRegularizeRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
    RequestAudienceScope? selectedScope,
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
    Object? contentErrorMessage = _unset,
  }) {
    return RegularizeRequestLoaded(
      regularizeRequests: regularizeRequests ?? this.regularizeRequests,
      filteredRegularizeRequests: filteredRegularizeRequests ?? this.filteredRegularizeRequests,
      searchQuery:
      identical(searchQuery, _unset) ? this.searchQuery : searchQuery as String?,
      statusFilter:
      identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as RegularizeStatus?,
      selectedScope: selectedScope ?? this.selectedScope,
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
      contentErrorMessage:
          identical(contentErrorMessage, _unset)
              ? this.contentErrorMessage
              : contentErrorMessage as String?,
    );
  }
}

/// Error state
class RegularizeRequestError extends RegularizeRequestState {
  final String message;

  const RegularizeRequestError(this.message);

  @override
  List<Object> get props => [message];
}
