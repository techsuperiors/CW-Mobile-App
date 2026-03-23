import 'package:equatable/equatable.dart';
import '../models/on_duty_request_model.dart';

/// On-Duty request events
abstract class OnDutyRequestEvent extends Equatable {
  const OnDutyRequestEvent();

  @override
  List<Object> get props => [];
}

/// Load On-Duty requests event
class LoadOnDutyRequests extends OnDutyRequestEvent {
  const LoadOnDutyRequests();
}

class LoadTeamOnDutyRequests extends OnDutyRequestEvent {
  final int page;
  final int limit;
  final String requestType;

  const LoadTeamOnDutyRequests({
    this.page = 1,
    this.limit = 50,
    this.requestType = 'All',
  });

  @override
  List<Object> get props => [page, limit, requestType];
}

/// Search On-Duty requests event
class SearchOnDutyRequests extends OnDutyRequestEvent {
  final String query;

  const SearchOnDutyRequests(this.query);

  @override
  List<Object> get props => [query];
}

/// Filter On-Duty requests by status event
class FilterOnDutyRequestsByStatus extends OnDutyRequestEvent {
  final OnDutyStatus? status;

  const FilterOnDutyRequestsByStatus(this.status);

  @override
  List<Object> get props => [status ?? ''];
}

/// Clear filters event
class ClearOnDutyFilters extends OnDutyRequestEvent {
  const ClearOnDutyFilters();
}
