import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

import '../models/regularize_request_model.dart';

/// Regularize request events
abstract class RegularizeRequestEvent extends Equatable {
  const RegularizeRequestEvent();

  @override
  List<Object> get props => [];
}

/// Load regularize requests event
class LoadRegularizeRequests extends RegularizeRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final RegularizeStatus? status;
  final bool forceRefresh;

  const LoadRegularizeRequests({
    required this.clientId,
    this.page = 1,
    this.limit = 50,
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

class LoadMoreRegularizeRequests extends RegularizeRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreRegularizeRequests({
    required this.clientId,
    this.limit = 50,
  });

  @override
  List<Object> get props => [clientId, limit];
}

class LoadTeamRegularizeRequests extends RegularizeRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;
  final RegularizeStatus? status;
  final bool forceRefresh;

  const LoadTeamRegularizeRequests({
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

class LoadMoreTeamRegularizeRequests extends RegularizeRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreTeamRegularizeRequests({
    required this.clientId,
    this.limit = 50,
  });

  @override
  List<Object> get props => [clientId, limit];
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
