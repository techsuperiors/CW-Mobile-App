import 'package:equatable/equatable.dart';

import '../models/wfh_request_model.dart';

/// WFH request events
abstract class WfhRequestEvent extends Equatable {
  const WfhRequestEvent();

  @override
  List<Object> get props => [];
}

/// Load WFH requests event
class LoadWfhRequests extends WfhRequestEvent {
  const LoadWfhRequests();
}

class LoadTeamWfhRequests extends WfhRequestEvent {
  final int page;
  final int limit;
  final String requestType;

  const LoadTeamWfhRequests({
    this.page = 1,
    this.limit = 50,
    this.requestType = 'All',
  });

  @override
  List<Object> get props => [page, limit, requestType];
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
