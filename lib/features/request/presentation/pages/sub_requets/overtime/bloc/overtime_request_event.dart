import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../models/overtime_request_model.dart';

abstract class OvertimeRequestEvent extends Equatable {
  const OvertimeRequestEvent();

  @override
  List<Object?> get props => [];
}

class LoadOvertimeRequests extends OvertimeRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final OvertimeStatus? status;
  final bool forceRefresh;

  const LoadOvertimeRequests({
    required this.clientId,
    this.page = 1,
    this.limit = 5,
    this.status,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [
    clientId,
    page,
    limit,
    status ?? '',
    forceRefresh,
  ];
}

class LoadMoreOvertimeRequests extends OvertimeRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreOvertimeRequests({
    required this.clientId,
    this.limit = 5,
  });

  @override
  List<Object?> get props => [clientId, limit];
}

class LoadTeamOvertimeRequests extends OvertimeRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;
  final OvertimeStatus? status;
  final bool forceRefresh;

  const LoadTeamOvertimeRequests({
    required this.clientId,
    this.page = 1,
    this.limit = 50,
    this.scope = RequestAudienceScope.allUsers,
    this.status,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [
    clientId,
    page,
    limit,
    scope,
    status ?? '',
    forceRefresh,
  ];
}

class LoadMoreTeamOvertimeRequests extends OvertimeRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreTeamOvertimeRequests({
    required this.clientId,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [clientId, limit];
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
