import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/get_comp_off_requests.dart';
import '../domain/usecases/get_team_comp_off_requests.dart';
import '../models/comp_off_request_model.dart';
import 'comp_off_request_event.dart';
import 'comp_off_request_state.dart';

class CompOffRequestBloc extends Bloc<CompOffRequestEvent, CompOffRequestState> {
  final GetCompOffRequestsUseCase getCompOffRequestsUseCase;
  final GetTeamCompOffRequestsUseCase? getTeamCompOffRequestsUseCase;

  CompOffRequestBloc({
    required this.getCompOffRequestsUseCase,
    this.getTeamCompOffRequestsUseCase,
  })
      : super(const CompOffRequestInitial()) {
    on<LoadCompOffRequests>(_onLoad);
    on<LoadTeamCompOffRequests>(_onLoadTeam);
    on<SearchCompOffRequests>(_onSearch);
    on<FilterCompOffRequestsByStatus>(_onFilter);
  }

  Future<void> _onLoad(
    LoadCompOffRequests event,
    Emitter<CompOffRequestState> emit,
  ) async {
    emit(const CompOffRequestLoading());
    final result = await getCompOffRequestsUseCase();
    result.fold(
      (failure) => emit(CompOffRequestError(failure.message)),
      (list) => emit(
        CompOffRequestLoaded(requests: list, filteredRequests: list),
      ),
    );
  }

  Future<void> _onLoadTeam(
    LoadTeamCompOffRequests event,
    Emitter<CompOffRequestState> emit,
  ) async {
    final teamUseCase = getTeamCompOffRequestsUseCase;
    if (teamUseCase == null) {
      emit(const CompOffRequestError('Team comp-off requests are not configured'));
      return;
    }

    emit(const CompOffRequestLoading());
    final result = await teamUseCase(
      page: event.page,
      limit: event.limit,
      requestType: event.requestType,
    );
    result.fold(
      (failure) => emit(CompOffRequestError(failure.message)),
      (list) => emit(
        CompOffRequestLoaded(requests: list, filteredRequests: list),
      ),
    );
  }

  void _onSearch(
    SearchCompOffRequests event,
    Emitter<CompOffRequestState> emit,
  ) {
    if (state is! CompOffRequestLoaded) return;
    final current = state as CompOffRequestLoaded;
    final query = event.query.trim().toLowerCase();
    final searched = query.isEmpty
        ? current.requests
        : current.requests
            .where(
              (r) =>
                  r.subject.toLowerCase().contains(query) ||
                  r.reason.toLowerCase().contains(query),
            )
            .toList();
    emit(
      current.copyWith(
        filteredRequests: _applyFilters(searched, current.statusFilter),
        searchQuery: query.isEmpty ? null : query,
      ),
    );
  }

  void _onFilter(
    FilterCompOffRequestsByStatus event,
    Emitter<CompOffRequestState> emit,
  ) {
    if (state is! CompOffRequestLoaded) return;
    final current = state as CompOffRequestLoaded;
    final baseList = current.searchQuery == null
        ? current.requests
        : current.requests
            .where((r) => r.subject.toLowerCase().contains(current.searchQuery!))
            .toList();
    emit(
      current.copyWith(
        filteredRequests: _applyFilters(baseList, event.status),
        statusFilter: event.status,
      ),
    );
  }

  List<CompOffRequestModel> _applyFilters(
    List<CompOffRequestModel> requests,
    CompOffStatus? status,
  ) {
    if (status == null) return requests;
    return requests.where((r) => r.status == status).toList();
  }
}
