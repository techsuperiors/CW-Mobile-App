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
    String? searchQuery,
    CompOffStatus? statusFilter,
  }) {
    return CompOffRequestLoaded(
      requests: requests ?? this.requests,
      filteredRequests: filteredRequests ?? this.filteredRequests,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
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
