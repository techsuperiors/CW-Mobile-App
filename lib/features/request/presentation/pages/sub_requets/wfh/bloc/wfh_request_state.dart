import 'package:equatable/equatable.dart';

import '../../../../widgets/request_listing/request_audience_scope.dart';
import '../models/wfh_request_model.dart';

/// WFH request states
abstract class WfhRequestState extends Equatable {
  const WfhRequestState();

  @override
  List<Object> get props => [];
}

/// Initial state
class WfhRequestInitial extends WfhRequestState {
  const WfhRequestInitial();
}

/// Loading state
class WfhRequestLoading extends WfhRequestState {
  const WfhRequestLoading();
}

/// Loaded state
class WfhRequestLoaded extends WfhRequestState {
  static const Object _unset = Object();

  final List<WfhRequestModel> wfhRequests;
  final List<WfhRequestModel> filteredWfhRequests;
  final String? searchQuery;
  final WfhStatus? statusFilter;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int withdrawnCount;
  final RequestAudienceScope selectedScope;

  const WfhRequestLoaded({
    required this.wfhRequests,
    required this.filteredWfhRequests,
    this.searchQuery,
    this.statusFilter,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.withdrawnCount = 0,
    this.selectedScope = RequestAudienceScope.allUsers,
  });

  @override
  List<Object> get props => [
        wfhRequests,
        filteredWfhRequests,
        searchQuery ?? '',
        statusFilter ?? '',
        isLoadingMore,
        hasMore,
        currentPage,
        totalCount,
        pendingCount,
        approvedCount,
        rejectedCount,
        withdrawnCount,
        selectedScope,
      ];

  WfhRequestLoaded copyWith({
    List<WfhRequestModel>? wfhRequests,
    List<WfhRequestModel>? filteredWfhRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
    int? withdrawnCount,
    RequestAudienceScope? selectedScope,
  }) {
    return WfhRequestLoaded(
      wfhRequests: wfhRequests ?? this.wfhRequests,
      filteredWfhRequests: filteredWfhRequests ?? this.filteredWfhRequests,
      searchQuery:
      identical(searchQuery, _unset) ? this.searchQuery : searchQuery as String?,
      statusFilter:
      identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as WfhStatus?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      withdrawnCount: withdrawnCount ?? this.withdrawnCount,
      selectedScope: selectedScope ?? this.selectedScope,
    );
  }
}

/// Error state
class WfhRequestError extends WfhRequestState {
  final String message;

  const WfhRequestError(this.message);

  @override
  List<Object> get props => [message];
}
