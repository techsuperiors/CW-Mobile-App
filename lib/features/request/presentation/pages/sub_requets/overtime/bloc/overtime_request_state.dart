import 'package:equatable/equatable.dart';

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

  const OvertimeRequestLoaded({
    required this.requests,
    required this.filteredRequests,
    this.searchQuery,
    this.statusFilter,
  });

  OvertimeRequestLoaded copyWith({
    List<OvertimeRequestModel>? requests,
    List<OvertimeRequestModel>? filteredRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
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
    );
  }

  @override
  List<Object?> get props => [
    requests,
    filteredRequests,
    searchQuery,
    statusFilter,
  ];
}

class OvertimeRequestError extends OvertimeRequestState {
  final String message;

  const OvertimeRequestError(this.message);

  @override
  List<Object?> get props => [message];
}
