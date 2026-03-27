import 'package:equatable/equatable.dart';
import '../models/on_duty_request_model.dart';

/// On-Duty request states
abstract class OnDutyRequestState extends Equatable {
  const OnDutyRequestState();

  @override
  List<Object> get props => [];
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

  const OnDutyRequestLoaded({
    required this.onDutyRequests,
    required this.filteredOnDutyRequests,
    this.searchQuery,
    this.statusFilter,
  });

  @override
  List<Object> get props => [
    onDutyRequests,
    filteredOnDutyRequests,
    searchQuery ?? '',
    statusFilter ?? '',
  ];

  OnDutyRequestLoaded copyWith({
    List<OnDutyRequestModel>? onDutyRequests,
    List<OnDutyRequestModel>? filteredOnDutyRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
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
