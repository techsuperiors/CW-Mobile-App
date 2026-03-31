import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecases/get_wfh_requests.dart';
import '../domain/usecases/get_wfh_request_stats.dart';
import '../domain/usecases/get_team_wfh_requests.dart';
import '../models/wfh_request_model.dart';
import 'wfh_request_event.dart';
import 'wfh_request_state.dart';

/// WFH request BLoC — fetches WFH requests from API.
class WfhRequestBloc extends Bloc<WfhRequestEvent, WfhRequestState> {
  final GetWfhRequestsUseCase getWfhRequestsUseCase;
  final GetWfhRequestStatsUseCase getWfhRequestStatsUseCase;
  final GetTeamWfhRequestsUseCase? getTeamWfhRequestsUseCase;

  WfhRequestBloc({
    required this.getWfhRequestsUseCase,
    required this.getWfhRequestStatsUseCase,
    this.getTeamWfhRequestsUseCase,
  })
    : super(const WfhRequestInitial()) {
    on<LoadWfhRequests>(_onLoadWfhRequests);
    on<LoadMoreWfhRequests>(_onLoadMoreWfhRequests);
    on<LoadTeamWfhRequests>(_onLoadTeamWfhRequests);
    on<LoadMoreTeamWfhRequests>(_onLoadMoreTeamWfhRequests);
    on<SearchWfhRequests>(_onSearchWfhRequests);
    on<FilterWfhRequestsByStatus>(_onFilterWfhRequestsByStatus);
    on<ClearFilters>(_onClearFilters);
  }

  /// Load WFH requests from API.
  Future<void> _onLoadWfhRequests(
    LoadWfhRequests event,
    Emitter<WfhRequestState> emit,
  ) async {
    emit(const WfhRequestLoading());

    final statsResult = await getWfhRequestStatsUseCase(
      GetWfhRequestStatsParams(clientId: event.clientId),
    );
    final result = await getWfhRequestsUseCase(
      GetWfhRequestsParams(page: event.page, limit: event.limit),
    );
    result.fold(
      (failure) => emit(WfhRequestError(failure.message)),
      (pageData) {
        var loadedState = WfhRequestLoaded(
          wfhRequests: pageData.requests,
          filteredWfhRequests: pageData.requests,
          currentPage: event.page,
          totalCount: pageData.total,
          pendingCount: pageData.pendingCount,
          hasMore: pageData.requests.length < pageData.total,
        );

        statsResult.fold(
          (_) {},
          (stats) {
            loadedState = loadedState.copyWith(
              totalCount: stats.total,
              pendingCount: stats.pending,
              approvedCount: stats.approved,
              rejectedCount: stats.rejected,
              withdrawnCount: stats.withdrawn,
              hasMore: pageData.requests.length < stats.total,
            );
          },
        );

        emit(loadedState);
      },
    );
  }

  Future<void> _onLoadMoreWfhRequests(
    LoadMoreWfhRequests event,
    Emitter<WfhRequestState> emit,
  ) async {
    if (state is! WfhRequestLoaded) return;

    final currentState = state as WfhRequestLoaded;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getWfhRequestsUseCase(
      GetWfhRequestsParams(
        page: currentState.currentPage + 1,
        limit: event.limit,
      ),
    );

    result.fold(
      (_) => emit(currentState.copyWith(isLoadingMore: false)),
      (pageData) {
        final merged = _mergeUniqueById(
          currentState.wfhRequests,
          pageData.requests,
        );
        emit(
          _buildLoadedState(
            currentState.copyWith(
              wfhRequests: merged,
              isLoadingMore: false,
              hasMore: merged.length < pageData.total,
              currentPage: currentState.currentPage + 1,
              totalCount: pageData.total,
              pendingCount: pageData.pendingCount,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onLoadTeamWfhRequests(
    LoadTeamWfhRequests event,
    Emitter<WfhRequestState> emit,
  ) async {
    final teamUseCase = getTeamWfhRequestsUseCase;
    if (teamUseCase == null) {
      emit(const WfhRequestError('Team WFH requests are not configured'));
      return;
    }

    emit(const WfhRequestLoading());

    final result = await teamUseCase(
      GetTeamWfhRequestsParams(
        page: event.page,
        limit: event.limit,
        scope: event.scope,
      ),
    );

    final statsResult = await getWfhRequestStatsUseCase(
      GetWfhRequestStatsParams(
        clientId: event.clientId,
        requestType: event.scope.attendanceRequestType,
      ),
    );

    result.fold(
      (failure) => emit(WfhRequestError(failure.message)),
      (wfhRequests) {
        var loadedState = WfhRequestLoaded(
          wfhRequests: wfhRequests,
          filteredWfhRequests: wfhRequests,
          selectedScope: event.scope,
          currentPage: event.page,
          hasMore: false,
        );

        statsResult.fold(
          (_) {},
          (stats) {
            loadedState = loadedState.copyWith(
              totalCount: stats.total,
              pendingCount: stats.pending,
              approvedCount: stats.approved,
              rejectedCount: stats.rejected,
              withdrawnCount: stats.withdrawn,
              hasMore: wfhRequests.length < stats.total,
            );
          },
        );

        emit(loadedState);
      },
    );
  }

  Future<void> _onLoadMoreTeamWfhRequests(
    LoadMoreTeamWfhRequests event,
    Emitter<WfhRequestState> emit,
  ) async {
    if (state is! WfhRequestLoaded) return;

    final currentState = state as WfhRequestLoaded;
    final teamUseCase = getTeamWfhRequestsUseCase;
    if (teamUseCase == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await teamUseCase(
      GetTeamWfhRequestsParams(
        page: currentState.currentPage + 1,
        limit: event.limit,
        scope: currentState.selectedScope,
      ),
    );

    result.fold(
      (_) => emit(currentState.copyWith(isLoadingMore: false)),
      (pageItems) {
        final merged = _mergeUniqueById(currentState.wfhRequests, pageItems);
        emit(
          _buildLoadedState(
            currentState.copyWith(
              wfhRequests: merged,
              isLoadingMore: false,
              hasMore: merged.length < currentState.totalCount,
              currentPage: currentState.currentPage + 1,
            ),
          ),
        );
      },
    );
  }

  /// Search through already-loaded requests locally.
  void _onSearchWfhRequests(
    SearchWfhRequests event,
    Emitter<WfhRequestState> emit,
  ) {
    if (state is WfhRequestLoaded) {
      final currentState = state as WfhRequestLoaded;
      final query = event.query.trim().toLowerCase();

      if (query.isEmpty) {
        emit(_buildLoadedState(currentState.copyWith(searchQuery: null)));
      } else {
        emit(_buildLoadedState(currentState.copyWith(searchQuery: query)));
      }
    }
  }

  void _onFilterWfhRequestsByStatus(
    FilterWfhRequestsByStatus event,
    Emitter<WfhRequestState> emit,
  ) {
    if (state is WfhRequestLoaded) {
      final currentState = state as WfhRequestLoaded;
      emit(
        _buildLoadedState(currentState.copyWith(statusFilter: event.status)),
      );
    }
  }

  void _onClearFilters(ClearFilters event, Emitter<WfhRequestState> emit) {
    if (state is WfhRequestLoaded) {
      final currentState = state as WfhRequestLoaded;
      emit(
        _buildLoadedState(currentState.copyWith(statusFilter: null)),
      );
    }
  }

  WfhRequestLoaded _buildLoadedState(WfhRequestLoaded state) {
    final searchedList = _applySearch(state.wfhRequests, state.searchQuery);
    final filtered = _applyFilters(searchedList, state.statusFilter);
    return state.copyWith(filteredWfhRequests: filtered);
  }

  List<WfhRequestModel> _applySearch(
    List<WfhRequestModel> requests,
    String? query,
  ) {
    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return requests;
    }

    return requests
        .where(
          (request) =>
              request.reason.toLowerCase().contains(normalizedQuery) ||
              (request.subject?.toLowerCase().contains(normalizedQuery) ??
                  false),
        )
        .toList();
  }

  List<WfhRequestModel> _mergeUniqueById(
    List<WfhRequestModel> existing,
    List<WfhRequestModel> incoming,
  ) {
    final merged = <WfhRequestModel>[...existing];
    final seenIds = existing.map((item) => item.id).toSet();

    for (final item in incoming) {
      if (seenIds.add(item.id)) {
        merged.add(item);
      }
    }

    return merged;
  }

  List<WfhRequestModel> _applyFilters(
    List<WfhRequestModel> requests,
    WfhStatus? statusFilter,
  ) {
    var filtered = requests;

    if (statusFilter != null) {
      filtered = filtered.where((r) => r.status == statusFilter).toList();
    }

    return filtered;
  }
}
