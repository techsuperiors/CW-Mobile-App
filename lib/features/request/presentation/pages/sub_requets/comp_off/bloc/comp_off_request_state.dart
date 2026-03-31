import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../models/comp_off_request_model.dart';

abstract class CompOffRequestState extends Equatable {
  const CompOffRequestState();

  @override
  List<Object?> get props => [];
}

class CompOffRequestInitial extends CompOffRequestState {
  const CompOffRequestInitial();
}

class CompOffRequestLoading extends CompOffRequestState {
  const CompOffRequestLoading();
}

class CompOffRequestLoaded extends CompOffRequestState {
  static const Object _unset = Object();

  final List<CompOffRequestModel> requests;
  final List<CompOffRequestModel> filteredRequests;
  final String? searchQuery;
  final CompOffStatus? statusFilter;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final RequestAudienceScope selectedScope;

  const CompOffRequestLoaded({
    required this.requests,
    required this.filteredRequests,
    this.searchQuery,
    this.statusFilter,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.totalCount = 0,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.selectedScope = RequestAudienceScope.allUsers,
  });

  CompOffRequestLoaded copyWith({
    List<CompOffRequestModel>? requests,
    List<CompOffRequestModel>? filteredRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    int? pendingCount,
    int? approvedCount,
    int? rejectedCount,
    RequestAudienceScope? selectedScope,
  }) {
    return CompOffRequestLoaded(
      requests: requests ?? this.requests,
      filteredRequests: filteredRequests ?? this.filteredRequests,
      searchQuery:
      identical(searchQuery, _unset)
          ? this.searchQuery
          : searchQuery as String?,
      statusFilter:
      identical(statusFilter, _unset)
          ? this.statusFilter
          : statusFilter as CompOffStatus?,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      pendingCount: pendingCount ?? this.pendingCount,
      approvedCount: approvedCount ?? this.approvedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      selectedScope: selectedScope ?? this.selectedScope,
    );
  }

  @override
  List<Object?> get props => [
    requests,
    filteredRequests,
    searchQuery,
    statusFilter,
    isLoadingMore,
    hasMore,
    currentPage,
    totalCount,
    pendingCount,
    approvedCount,
    rejectedCount,
    selectedScope,
  ];
}

class CompOffRequestError extends CompOffRequestState {
  final String message;
  const CompOffRequestError(this.message);
  @override
  List<Object?> get props => [message];
}
