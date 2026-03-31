import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/on_duty_request_model.dart';
import '../domain/usecases/get_on_duty_requests.dart';
import '../domain/usecases/get_on_duty_request_stats.dart';
import '../domain/usecases/get_team_on_duty_requests.dart';
import 'on_duty_request_event.dart';
import 'on_duty_request_state.dart';

/// On-Duty request BLoC — fetches On-Duty requests from API.
class OnDutyRequestBloc extends Bloc<OnDutyRequestEvent, OnDutyRequestState> {
  final GetOnDutyRequestsUseCase getOnDutyRequestsUseCase;
  final GetOnDutyRequestStatsUseCase? getOnDutyRequestStatsUseCase;
  final GetTeamOnDutyRequestsUseCase? getTeamOnDutyRequestsUseCase;

  OnDutyRequestBloc({
    required this.getOnDutyRequestsUseCase,
    this.getOnDutyRequestStatsUseCase,
    this.getTeamOnDutyRequestsUseCase,
  })
      : super(const OnDutyRequestInitial()) {
    on<LoadOnDutyRequests>(_onLoadOnDutyRequests);
    on<LoadTeamOnDutyRequests>(_onLoadTeamOnDutyRequests);
    on<LoadMoreTeamOnDutyRequests>(_onLoadMoreTeamOnDutyRequests);
    on<SearchOnDutyRequests>(_onSearchOnDutyRequests);
    on<FilterOnDutyRequestsByStatus>(_onFilterOnDutyRequestsByStatus);
    on<ClearOnDutyFilters>(_onClearFilters);
  }

  /// Load On-Duty requests from API.
  Future<void> _onLoadOnDutyRequests(
    LoadOnDutyRequests event,
    Emitter<OnDutyRequestState> emit,
  ) async {
    emit(const OnDutyRequestLoading());

    final result = await getOnDutyRequestsUseCase();
    result.fold(
      (failure) => emit(OnDutyRequestError(failure.message)),
      (onDutyRequests) => emit(
        OnDutyRequestLoaded(
          onDutyRequests: onDutyRequests,
          filteredOnDutyRequests: onDutyRequests,
        ),
      ),
    );
  }

  Future<void> _onLoadTeamOnDutyRequests(
    LoadTeamOnDutyRequests event,
    Emitter<OnDutyRequestState> emit,
  ) async {
    final teamUseCase = getTeamOnDutyRequestsUseCase;
    if (teamUseCase == null) {
      emit(const OnDutyRequestError('Team On-Duty requests are not configured'));
      return;
    }

    emit(const OnDutyRequestLoading());

    final result = await teamUseCase(
      GetTeamOnDutyRequestsParams(
        clientId: event.clientId,
        page: event.page,
        limit: event.limit,
        scope: event.scope,
      ),
    );
    final statsUseCase = getOnDutyRequestStatsUseCase;
    final statsResult =
        statsUseCase == null
            ? null
            : await statsUseCase(
              GetOnDutyRequestStatsParams(
                clientId: event.clientId,
                requestType: event.scope.attendanceRequestType,
              ),
            );
    result.fold(
      (failure) => emit(OnDutyRequestError(failure.message)),
      (onDutyRequests) {
        var loadedState = OnDutyRequestLoaded(
          onDutyRequests: onDutyRequests,
          filteredOnDutyRequests: onDutyRequests,
          selectedScope: event.scope,
          currentPage: event.page,
          hasMore: onDutyRequests.length == event.limit,
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
              hasMore: onDutyRequests.length < stats.total,
            );
          },
        );

        emit(loadedState);
      },
    );
  }

  Future<void> _onLoadMoreTeamOnDutyRequests(
    LoadMoreTeamOnDutyRequests event,
    Emitter<OnDutyRequestState> emit,
  ) async {
    if (state is! OnDutyRequestLoaded) return;

    final currentState = state as OnDutyRequestLoaded;
    final teamUseCase = getTeamOnDutyRequestsUseCase;
    if (teamUseCase == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await teamUseCase(
      GetTeamOnDutyRequestsParams(
        clientId: event.clientId,
        page: currentState.currentPage + 1,
        limit: event.limit,
        scope: currentState.selectedScope,
      ),
    );

    result.fold(
      (_) => emit(currentState.copyWith(isLoadingMore: false)),
      (pageItems) {
        final merged = _mergeUniqueById(currentState.onDutyRequests, pageItems);
        emit(
          _buildLoadedState(
            currentState.copyWith(
              onDutyRequests: merged,
              isLoadingMore: false,
              currentPage: currentState.currentPage + 1,
              hasMore:
                  currentState.totalCount > 0
                      ? merged.length < currentState.totalCount
                      : pageItems.length == event.limit,
            ),
          ),
        );
      },
    );
  }

  /// Search through already-loaded requests locally.
  void _onSearchOnDutyRequests(
    SearchOnDutyRequests event,
    Emitter<OnDutyRequestState> emit,
  ) {
    if (state is OnDutyRequestLoaded) {
      final currentState = state as OnDutyRequestLoaded;
      final query = event.query.trim().toLowerCase();

      if (query.isEmpty) {
        emit(_buildLoadedState(currentState.copyWith(searchQuery: null)));
      } else {
        emit(_buildLoadedState(currentState.copyWith(searchQuery: query)));
      }
    }
  }

  void _onFilterOnDutyRequestsByStatus(
    FilterOnDutyRequestsByStatus event,
    Emitter<OnDutyRequestState> emit,
  ) {
    if (state is OnDutyRequestLoaded) {
      final currentState = state as OnDutyRequestLoaded;
      emit(_buildLoadedState(currentState.copyWith(statusFilter: event.status)));
    }
  }

  void _onClearFilters(
    ClearOnDutyFilters event,
    Emitter<OnDutyRequestState> emit,
  ) {
    if (state is OnDutyRequestLoaded) {
      final currentState = state as OnDutyRequestLoaded;
      emit(_buildLoadedState(currentState.copyWith(statusFilter: null)));
    }
  }

  OnDutyRequestLoaded _buildLoadedState(OnDutyRequestLoaded state) {
    final searched = _applySearch(state.onDutyRequests, state.searchQuery);
    return state.copyWith(
      filteredOnDutyRequests: _applyFilters(searched, state.statusFilter),
    );
  }

  List<OnDutyRequestModel> _applySearch(
    List<OnDutyRequestModel> requests,
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

  List<OnDutyRequestModel> _applyFilters(
    List<OnDutyRequestModel> requests,
    OnDutyStatus? statusFilter,
  ) {
    var filtered = requests;

    if (statusFilter != null) {
      filtered = filtered.where((r) => r.status == statusFilter).toList();
    }

    return filtered;
  }

  List<OnDutyRequestModel> _mergeUniqueById(
    List<OnDutyRequestModel> existing,
    List<OnDutyRequestModel> incoming,
  ) {
    final merged = <OnDutyRequestModel>[...existing];
    final seenIds = existing.map((item) => item.id).toSet();

    for (final item in incoming) {
      if (seenIds.add(item.id)) {
        merged.add(item);
      }
    }

    return merged;
  }
}
