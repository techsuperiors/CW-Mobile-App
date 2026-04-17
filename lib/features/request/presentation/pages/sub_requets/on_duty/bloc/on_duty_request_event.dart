import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import '../models/on_duty_request_model.dart';

/// On-Duty request events
abstract class OnDutyRequestEvent extends Equatable {
  const OnDutyRequestEvent();

  @override
  List<Object?> get props => [];
}

/// Load On-Duty requests event
class LoadOnDutyRequests extends OnDutyRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final OnDutyStatus? status;
  final bool forceRefresh;

  const LoadOnDutyRequests({
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

class LoadMoreOnDutyRequests extends OnDutyRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreOnDutyRequests({
    required this.clientId,
    this.limit = 5,
  });

  @override
  List<Object?> get props => [clientId, limit];
}

class LoadTeamOnDutyRequests extends OnDutyRequestEvent {
  final int clientId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;
  final OnDutyStatus? status;
  final bool forceRefresh;

  const LoadTeamOnDutyRequests({
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

class LoadMoreTeamOnDutyRequests extends OnDutyRequestEvent {
  final int clientId;
  final int limit;

  const LoadMoreTeamOnDutyRequests({
    required this.clientId,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [clientId, limit];
}

/// Search On-Duty requests event
class SearchOnDutyRequests extends OnDutyRequestEvent {
  final String query;

  const SearchOnDutyRequests(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filter On-Duty requests by status event
class FilterOnDutyRequestsByStatus extends OnDutyRequestEvent {
  final OnDutyStatus? status;

  const FilterOnDutyRequestsByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

/// Clear filters event
class ClearOnDutyFilters extends OnDutyRequestEvent {
  const ClearOnDutyFilters();
}
