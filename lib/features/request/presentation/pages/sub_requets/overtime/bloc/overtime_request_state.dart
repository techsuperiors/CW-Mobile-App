import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../models/overtime_request_model.dart';

abstract class OvertimeRequestState extends Equatable {
  const OvertimeRequestState();

  @override
  List<Object?> get props => [];
}

class OvertimeRequestInitial extends OvertimeRequestState {
  const OvertimeRequestInitial();
}

class OvertimeRequestLoading extends OvertimeRequestState {
  const OvertimeRequestLoading();
}

class OvertimeRequestLoaded extends OvertimeRequestState {
  static const Object _unset = Object();

  final List<OvertimeRequestModel> requests;
  final List<OvertimeRequestModel> filteredRequests;
  final String? searchQuery;
  final OvertimeStatus? statusFilter;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int withdrawnCount;
  final RequestAudienceScope selectedScope;

  const OvertimeRequestLoaded({
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
    this.withdrawnCount = 0,
    this.selectedScope = RequestAudienceScope.allUsers,
  });

  OvertimeRequestLoaded copyWith({
    List<OvertimeRequestModel>? requests,
    List<OvertimeRequestModel>? filteredRequests,
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
    return OvertimeRequestLoaded(
      requests: requests ?? this.requests,
      filteredRequests: filteredRequests ?? this.filteredRequests,
      searchQuery:
          identical(searchQuery, _unset)
              ? this.searchQuery
              : searchQuery as String?,
      statusFilter:
          identical(statusFilter, _unset)
              ? this.statusFilter
              : statusFilter as OvertimeStatus?,
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
    withdrawnCount,
    selectedScope,
  ];
}

class OvertimeRequestError extends OvertimeRequestState {
  final String message;

  const OvertimeRequestError(this.message);

  @override
  List<Object?> get props => [message];
}
