import 'package:equatable/equatable.dart';

import '../models/comp_off_request_model.dart';

abstract class CompOffRequestEvent extends Equatable {
  const CompOffRequestEvent();

  @override
  List<Object?> get props => [];
}

class LoadCompOffRequests extends CompOffRequestEvent {
  const LoadCompOffRequests();
}

class LoadTeamCompOffRequests extends CompOffRequestEvent {
  final int page;
  final int limit;
  final String requestType;

  const LoadTeamCompOffRequests({
    this.page = 1,
    this.limit = 20,
    this.requestType = 'All',
  });

  @override
  List<Object?> get props => [page, limit, requestType];
}

class SearchCompOffRequests extends CompOffRequestEvent {
  final String query;
  const SearchCompOffRequests(this.query);
  @override
  List<Object?> get props => [query];
}

class FilterCompOffRequestsByStatus extends CompOffRequestEvent {
  final CompOffStatus? status;
  const FilterCompOffRequestsByStatus(this.status);
  @override
  List<Object?> get props => [status];
}
