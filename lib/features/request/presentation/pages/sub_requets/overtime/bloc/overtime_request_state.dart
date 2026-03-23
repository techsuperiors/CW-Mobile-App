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
    String? searchQuery,
    OvertimeStatus? statusFilter,
  }) {
    return OvertimeRequestLoaded(
      requests: requests ?? this.requests,
      filteredRequests: filteredRequests ?? this.filteredRequests,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
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
