import 'package:equatable/equatable.dart';

import '../../../../widgets/request_listing/request_audience_scope.dart';
import '../models/wfh_request_model.dart';

/// WFH request events
abstract class WfhRequestEvent extends Equatable {
  const WfhRequestEvent();

  @override
  List<Object> get props => [];
}

/// Load WFH requests event
class LoadWfhRequests extends WfhRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final WfhStatus? status;
  final bool forceRefresh;

  const LoadWfhRequests({
    required this.clientId,
    this.page = 1,
    this.limit = 5,
    this.status,
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [
    clientId,
    page,
    limit,
    status ?? '',
    forceRefresh,
  ];
}

class LoadMoreWfhRequests extends WfhRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreWfhRequests({
    required this.clientId,
    this.limit = 5,
  });

  @override
  List<Object> get props => [clientId, limit];
}

class LoadTeamWfhRequests extends WfhRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;
  final WfhStatus? status;
  final bool forceRefresh;

  const LoadTeamWfhRequests({
    required this.clientId,
    this.page = 1,
    this.limit = 50,
    this.scope = RequestAudienceScope.allUsers,
    this.status,
    this.forceRefresh = false,
  });

  @override
  List<Object> get props => [
    clientId,
    page,
    limit,
    scope,
    status ?? '',
    forceRefresh,
  ];
}

class LoadMoreTeamWfhRequests extends WfhRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreTeamWfhRequests({
    required this.clientId,
    this.limit = 50,
  });

  @override
  List<Object> get props => [clientId, limit];
}

/// Search WFH requests event
class SearchWfhRequests extends WfhRequestEvent {
  final String query;

  const SearchWfhRequests(this.query);

  @override
  List<Object> get props => [query];
}

/// Filter WFH requests by status event
class FilterWfhRequestsByStatus extends WfhRequestEvent {
  final WfhStatus? status;

  const FilterWfhRequestsByStatus(this.status);

  @override
  List<Object> get props => [status ?? ''];
}

/// Clear filters event
class ClearFilters extends WfhRequestEvent {
  const ClearFilters();
}
