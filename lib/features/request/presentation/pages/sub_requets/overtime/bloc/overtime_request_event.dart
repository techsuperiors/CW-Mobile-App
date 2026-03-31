import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

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
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;

  const LoadTeamOvertimeRequests({
    required this.clientId,
    this.page = 1,
    this.limit = 50,
    this.scope = RequestAudienceScope.allUsers,
  });

  @override
  List<Object?> get props => [clientId, page, limit, scope];
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
