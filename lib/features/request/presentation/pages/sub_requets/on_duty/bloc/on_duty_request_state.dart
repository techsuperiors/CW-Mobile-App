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
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final int withdrawnCount;
  final RequestAudienceScope selectedScope;

  const OnDutyRequestLoaded({
    required this.onDutyRequests,
    required this.filteredOnDutyRequests,
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
  List<Object?> get props => [
    onDutyRequests,
    filteredOnDutyRequests,
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

  OnDutyRequestLoaded copyWith({
    List<OnDutyRequestModel>? onDutyRequests,
    List<OnDutyRequestModel>? filteredOnDutyRequests,
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
class OnDutyRequestError extends OnDutyRequestState {
  final String message;

  const OnDutyRequestError(this.message);

  @override
  List<Object> get props => [message];
}
