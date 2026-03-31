import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/get_comp_off_requests.dart';
import '../domain/usecases/get_comp_off_request_stats.dart';
import '../domain/usecases/get_team_comp_off_requests.dart';
import '../models/comp_off_request_model.dart';
import 'comp_off_request_event.dart';
import 'comp_off_request_state.dart';

class CompOffRequestBloc extends Bloc<CompOffRequestEvent, CompOffRequestState> {
  final GetCompOffRequestsUseCase getCompOffRequestsUseCase;
  final GetCompOffRequestStatsUseCase? getCompOffRequestStatsUseCase;
  final GetTeamCompOffRequestsUseCase? getTeamCompOffRequestsUseCase;

  CompOffRequestBloc({
    required this.getCompOffRequestsUseCase,
    this.getCompOffRequestStatsUseCase,
    this.getTeamCompOffRequestsUseCase,
  })
      : super(const CompOffRequestInitial()) {
    on<LoadCompOffRequests>(_onLoad);
    on<LoadTeamCompOffRequests>(_onLoadTeam);
    on<LoadMoreTeamCompOffRequests>(_onLoadMoreTeam);
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
      GetTeamCompOffRequestsParams(
        page: event.page,
        limit: event.limit,
        scope: event.scope,
      ),
    );
    final statsUseCase = getCompOffRequestStatsUseCase;
    final statsResult =
        statsUseCase == null
            ? null
            : await statsUseCase(
              GetCompOffRequestStatsParams(userId: event.userId),
            );
    result.fold(
      (failure) => emit(CompOffRequestError(failure.message)),
      (list) {
        final totalCount = statsResult == null ? list.length : 0;
        var loadedState = CompOffRequestLoaded(
          requests: list,
          filteredRequests: list,
          selectedScope: event.scope,
          currentPage: event.page,
          totalCount: totalCount,
          hasMore: list.length == event.limit,
        );

        statsResult?.fold(
          (_) {},
          (stats) {
            loadedState = loadedState.copyWith(
              totalCount: stats.total,
              pendingCount: stats.pending,
              approvedCount: stats.approved,
              rejectedCount: stats.rejected,
              hasMore: list.length < stats.total,
            );
          },
        );

        emit(loadedState);
      },
    );
  }

  Future<void> _onLoadMoreTeam(
    LoadMoreTeamCompOffRequests event,
    Emitter<CompOffRequestState> emit,
  ) async {
    if (state is! CompOffRequestLoaded) return;

    final current = state as CompOffRequestLoaded;
    final teamUseCase = getTeamCompOffRequestsUseCase;
    if (teamUseCase == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    final result = await teamUseCase(
      GetTeamCompOffRequestsParams(
        page: current.currentPage + 1,
        limit: event.limit,
        scope: current.selectedScope,
      ),
    );

    result.fold(
      (_) => emit(current.copyWith(isLoadingMore: false)),
      (pageItems) {
        final merged = _mergeUniqueById(current.requests, pageItems);
        emit(
          _buildLoadedState(
            current.copyWith(
              requests: merged,
              isLoadingMore: false,
              currentPage: current.currentPage + 1,
              hasMore:
                  current.totalCount > 0
                      ? merged.length < current.totalCount
                      : pageItems.length == event.limit,
            ),
          ),
        );
      },
    );
  }

  void _onSearch(
    SearchCompOffRequests event,
    Emitter<CompOffRequestState> emit,
  ) {
    if (state is! CompOffRequestLoaded) return;
    final current = state as CompOffRequestLoaded;
    final query = event.query.trim().toLowerCase();
    emit(
      _buildLoadedState(
        current.copyWith(searchQuery: query.isEmpty ? null : query),
      ),
    );
  }

  void _onFilter(
    FilterCompOffRequestsByStatus event,
    Emitter<CompOffRequestState> emit,
  ) {
    if (state is! CompOffRequestLoaded) return;
    final current = state as CompOffRequestLoaded;
    emit(
      _buildLoadedState(current.copyWith(statusFilter: event.status)),
    );
  }

  CompOffRequestLoaded _buildLoadedState(CompOffRequestLoaded state) {
    final searched = _applySearch(state.requests, state.searchQuery);
    return state.copyWith(
      filteredRequests: _applyFilters(searched, state.statusFilter),
    );
  }

  List<CompOffRequestModel> _applySearch(
    List<CompOffRequestModel> requests,
    String? query,
  ) {
    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return requests;
    }

    return requests
        .where(
          (r) =>
              r.subject.toLowerCase().contains(normalizedQuery) ||
              r.reason.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  List<CompOffRequestModel> _applyFilters(
    List<CompOffRequestModel> requests,
    CompOffStatus? status,
  ) {
    if (status == null) return requests;
    return requests.where((r) => r.status == status).toList();
  }

  List<CompOffRequestModel> _mergeUniqueById(
    List<CompOffRequestModel> existing,
    List<CompOffRequestModel> incoming,
  ) {
    final merged = <CompOffRequestModel>[...existing];
    final seenIds = existing.map((item) => item.id).toSet();

    for (final item in incoming) {
      if (seenIds.add(item.id)) {
        merged.add(item);
      }
    }

    return merged;
  }
}
