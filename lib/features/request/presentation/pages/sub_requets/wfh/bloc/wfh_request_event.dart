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

  const LoadWfhRequests({
    required this.clientId,
    this.page = 1,
    this.limit = 5,
  });

  @override
  List<Object> get props => [clientId, page, limit];
}

class LoadMoreWfhRequests extends WfhRequestEvent {
  final int limit;

  const LoadMoreWfhRequests({
    this.limit = 5,
  });

  @override
  List<Object> get props => [limit];
}

class LoadTeamWfhRequests extends WfhRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;

  const LoadTeamWfhRequests({
    required this.clientId,
    this.page = 1,
    this.limit = 50,
    this.scope = RequestAudienceScope.allUsers,
  });

  @override
  List<Object> get props => [clientId, page, limit, scope];
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
