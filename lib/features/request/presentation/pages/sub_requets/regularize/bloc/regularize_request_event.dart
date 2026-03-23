import 'package:equatable/equatable.dart';

import '../models/regularize_request_model.dart';

/// Regularize request events
abstract class RegularizeRequestEvent extends Equatable {
  const RegularizeRequestEvent();

  @override
  List<Object> get props => [];
}

/// Load regularize requests event
class LoadRegularizeRequests extends RegularizeRequestEvent {
  const LoadRegularizeRequests();
}

class LoadTeamRegularizeRequests extends RegularizeRequestEvent {
  final int page;
  final int limit;
  final String requestType;

  const LoadTeamRegularizeRequests({
    this.page = 1,
    this.limit = 50,
    this.requestType = 'All',
  });

  @override
  List<Object> get props => [page, limit, requestType];
}

/// Search regularize requests event
class SearchRegularizeRequests extends RegularizeRequestEvent {
  final String query;

  const SearchRegularizeRequests(this.query);

  @override
  List<Object> get props => [query];
}

/// Filter regularize requests by status event
class FilterRegularizeRequestsByStatus extends RegularizeRequestEvent {
  final RegularizeStatus? status;

  const FilterRegularizeRequestsByStatus(this.status);

  @override
  List<Object> get props => [status ?? ''];
}

/// Clear filters event
class ClearFilters extends RegularizeRequestEvent {
  const ClearFilters();
}
