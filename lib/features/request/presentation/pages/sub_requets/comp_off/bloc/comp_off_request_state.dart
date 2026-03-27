import 'package:equatable/equatable.dart';

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

  const CompOffRequestLoaded({
    required this.requests,
    required this.filteredRequests,
    this.searchQuery,
    this.statusFilter,
  });

  CompOffRequestLoaded copyWith({
    List<CompOffRequestModel>? requests,
    List<CompOffRequestModel>? filteredRequests,
    Object? searchQuery = _unset,
    Object? statusFilter = _unset,
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
    );
  }

  @override
  List<Object?> get props => [requests, filteredRequests, searchQuery, statusFilter];
}

class CompOffRequestError extends CompOffRequestState {
  final String message;
  const CompOffRequestError(this.message);
  @override
  List<Object?> get props => [message];
}
