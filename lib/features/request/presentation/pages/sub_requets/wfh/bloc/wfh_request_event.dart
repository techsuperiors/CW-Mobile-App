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
