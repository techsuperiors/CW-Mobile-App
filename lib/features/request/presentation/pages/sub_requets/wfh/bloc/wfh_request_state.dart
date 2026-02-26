import 'package:equatable/equatable.dart';

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
  final List<WfhRequestModel> wfhRequests;
  final List<WfhRequestModel> filteredWfhRequests;
  final String? searchQuery;
  final WfhStatus? statusFilter;

  const WfhRequestLoaded({
    required this.wfhRequests,
    required this.filteredWfhRequests,
    this.searchQuery,
    this.statusFilter,
  });

  @override
  List<Object> get props => [
        wfhRequests,
        filteredWfhRequests,
        searchQuery ?? '',
        statusFilter ?? '',
      ];

  WfhRequestLoaded copyWith({
    List<WfhRequestModel>? wfhRequests,
    List<WfhRequestModel>? filteredWfhRequests,
    String? searchQuery,
    WfhStatus? statusFilter,
  }) {
    return WfhRequestLoaded(
      wfhRequests: wfhRequests ?? this.wfhRequests,
      filteredWfhRequests: filteredWfhRequests ?? this.filteredWfhRequests,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
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
