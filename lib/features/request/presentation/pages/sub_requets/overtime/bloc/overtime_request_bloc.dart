import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/get_overtime_requests.dart';
import '../domain/usecases/get_overtime_request_stats.dart';
import '../domain/usecases/get_team_overtime_requests.dart';
import '../models/overtime_request_model.dart';
import 'overtime_request_event.dart';
import 'overtime_request_state.dart';

class OvertimeRequestBloc
    extends Bloc<OvertimeRequestEvent, OvertimeRequestState> {
  final GetOvertimeRequestsUseCase getOvertimeRequestsUseCase;
  final GetOvertimeRequestStatsUseCase? getOvertimeRequestStatsUseCase;
  final GetTeamOvertimeRequestsUseCase? getTeamOvertimeRequestsUseCase;

  OvertimeRequestBloc({
    required this.getOvertimeRequestsUseCase,
    this.getOvertimeRequestStatsUseCase,
    this.getTeamOvertimeRequestsUseCase,
  })
      : super(const OvertimeRequestInitial()) {
    on<LoadOvertimeRequests>(_onLoadOvertimeRequests);
    on<LoadTeamOvertimeRequests>(_onLoadTeamOvertimeRequests);
    on<LoadMoreTeamOvertimeRequests>(_onLoadMoreTeamOvertimeRequests);
    on<SearchOvertimeRequests>(_onSearchOvertimeRequests);
    on<FilterOvertimeRequestsByStatus>(_onFilterOvertimeRequestsByStatus);
  }

  Future<void> _onLoadOvertimeRequests(
    LoadOvertimeRequests event,
    Emitter<OvertimeRequestState> emit,
  ) async {
    emit(const OvertimeRequestLoading());
    final result = await getOvertimeRequestsUseCase();
    result.fold(
      (failure) => emit(OvertimeRequestError(failure.message)),
      (requests) => emit(
        OvertimeRequestLoaded(requests: requests, filteredRequests: requests),
      ),
    );
  }

  Future<void> _onLoadTeamOvertimeRequests(
    LoadTeamOvertimeRequests event,
    Emitter<OvertimeRequestState> emit,
  ) async {
    final teamUseCase = getTeamOvertimeRequestsUseCase;
    if (teamUseCase == null) {
      emit(const OvertimeRequestError('Team overtime requests are not configured'));
      return;
    }

    emit(const OvertimeRequestLoading());
    final result = await teamUseCase(
      GetTeamOvertimeRequestsParams(
        page: event.page,
        limit: event.limit,
        scope: event.scope,
      ),
    );
    final statsUseCase = getOvertimeRequestStatsUseCase;
    final statsResult =
        statsUseCase == null
            ? null
            : await statsUseCase(
              GetOvertimeRequestStatsParams(
                clientId: event.clientId,
                requestType: event.scope.attendanceRequestType,
              ),
            );
    result.fold(
      (failure) => emit(OvertimeRequestError(failure.message)),
      (requests) {
        var loadedState = OvertimeRequestLoaded(
          requests: requests,
          filteredRequests: requests,
          selectedScope: event.scope,
          currentPage: event.page,
          hasMore: requests.length == event.limit,
        );

        statsResult?.fold(
          (_) {},
          (stats) {
            loadedState = loadedState.copyWith(
              totalCount: stats.total,
              pendingCount: stats.pending,
              approvedCount: stats.approved,
              rejectedCount: stats.rejected,
              withdrawnCount: stats.withdrawn,
              hasMore: requests.length < stats.total,
            );
          },
        );

        emit(loadedState);
      },
    );
  }

  Future<void> _onLoadMoreTeamOvertimeRequests(
    LoadMoreTeamOvertimeRequests event,
    Emitter<OvertimeRequestState> emit,
  ) async {
    if (state is! OvertimeRequestLoaded) return;

    final current = state as OvertimeRequestLoaded;
    final teamUseCase = getTeamOvertimeRequestsUseCase;
    if (teamUseCase == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    final result = await teamUseCase(
      GetTeamOvertimeRequestsParams(
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

  void _onSearchOvertimeRequests(
    SearchOvertimeRequests event,
    Emitter<OvertimeRequestState> emit,
  ) {
    if (state is! OvertimeRequestLoaded) return;
    final current = state as OvertimeRequestLoaded;
    final query = event.query.trim().toLowerCase();
    emit(
      _buildLoadedState(
        current.copyWith(searchQuery: query.isEmpty ? null : query),
      ),
    );
  }

  void _onFilterOvertimeRequestsByStatus(
    FilterOvertimeRequestsByStatus event,
    Emitter<OvertimeRequestState> emit,
  ) {
    if (state is! OvertimeRequestLoaded) return;
    final current = state as OvertimeRequestLoaded;
    emit(
      _buildLoadedState(current.copyWith(statusFilter: event.status)),
    );
  }

  OvertimeRequestLoaded _buildLoadedState(OvertimeRequestLoaded state) {
    final searched = _applySearch(state.requests, state.searchQuery);
    return state.copyWith(
      filteredRequests: _applyFilters(searched, state.statusFilter),
    );
  }

  List<OvertimeRequestModel> _applySearch(
    List<OvertimeRequestModel> requests,
    String? query,
  ) {
    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return requests;
    }

    return requests
        .where(
          (request) => request.subject.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  List<OvertimeRequestModel> _applyFilters(
    List<OvertimeRequestModel> requests,
    OvertimeStatus? statusFilter,
  ) {
    if (statusFilter == null) return requests;
    return requests.where((request) => request.status == statusFilter).toList();
  }

  List<OvertimeRequestModel> _mergeUniqueById(
    List<OvertimeRequestModel> existing,
    List<OvertimeRequestModel> incoming,
  ) {
    final merged = <OvertimeRequestModel>[...existing];
    final seenIds = existing.map((item) => item.id).toSet();

    for (final item in incoming) {
      if (seenIds.add(item.id)) {
        merged.add(item);
      }
    }

    return merged;
  }
}
