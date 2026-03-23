import 'package:equatable/equatable.dart';

import '../models/overtime_request_model.dart';

abstract class OvertimeRequestEvent extends Equatable {
  const OvertimeRequestEvent();

  @override
  List<Object?> get props => [];
}

class LoadOvertimeRequests extends OvertimeRequestEvent {
  const LoadOvertimeRequests();
}

class LoadTeamOvertimeRequests extends OvertimeRequestEvent {
  final int page;
  final int limit;
  final String requestType;

  const LoadTeamOvertimeRequests({
    this.page = 1,
    this.limit = 20,
    this.requestType = 'All',
  });

  @override
  List<Object?> get props => [page, limit, requestType];
}

class SearchOvertimeRequests extends OvertimeRequestEvent {
  final String query;

  const SearchOvertimeRequests(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterOvertimeRequestsByStatus extends OvertimeRequestEvent {
  final OvertimeStatus? status;

  const FilterOvertimeRequestsByStatus(this.status);

  @override
  List<Object?> get props => [status];
}
