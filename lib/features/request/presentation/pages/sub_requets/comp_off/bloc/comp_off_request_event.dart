import 'package:equatable/equatable.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

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
  final int userId;
  final int page;
  final int limit;
  final RequestAudienceScope scope;

  const LoadTeamCompOffRequests({
    required this.userId,
    this.page = 1,
    this.limit = 50,
    this.scope = RequestAudienceScope.allUsers,
  });

  @override
  List<Object?> get props => [userId, page, limit, scope];
}

class LoadMoreTeamCompOffRequests extends CompOffRequestEvent {
  final int userId;
  final int limit;

  const LoadMoreTeamCompOffRequests({
    required this.userId,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [userId, limit];
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
