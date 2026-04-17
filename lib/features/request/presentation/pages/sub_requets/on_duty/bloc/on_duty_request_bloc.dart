import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
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
  final Map<String, OnDutyRequestLoaded> _selfOnDutyRequestsCache = {};
  final Map<String, OnDutyRequestLoaded> _teamOnDutyRequestsCache = {};
  int _latestSelfRequestSequence = 0;
  String? _activeSelfRequestKey;
  int _latestTeamRequestSequence = 0;
  String? _activeTeamRequestKey;

  OnDutyRequestBloc({
    required this.getOnDutyRequestsUseCase,
    this.getOnDutyRequestStatsUseCase,
    this.getTeamOnDutyRequestsUseCase,
  })
      : super(const OnDutyRequestInitial()) {
    on<LoadOnDutyRequests>(_onLoadOnDutyRequests);
    on<LoadMoreOnDutyRequests>(_onLoadMoreOnDutyRequests);
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
    final previousLoadedState =
        state is OnDutyRequestLoaded &&
                !(state as OnDutyRequestLoaded).isTeamRequestMode
            ? state as OnDutyRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _selfOnDutyRequestsCache.clear();
    }

    final cacheKey = _selfOnDutyCacheKey(event.status);
    final requestSequence = ++_latestSelfRequestSequence;
    _activeSelfRequestKey = cacheKey;
    final cachedState = _selfOnDutyRequestsCache[cacheKey];

    if (event.page == 1 && !event.forceRefresh && cachedState != null) {
      emit(
        _buildLoadedState(
          cachedState.copyWith(
            searchQuery: previousLoadedState?.searchQuery,
            isRefreshing: false,
            isLoadingMore: false,
            contentErrorMessage: null,
          ),
        ),
      );
      return;
    }

    if (previousLoadedState != null) {
      emit(
        previousLoadedState.copyWith(
          isRefreshing: true,
          isLoadingMore: false,
          statusFilter: event.status,
          contentErrorMessage: null,
        ),
      );
    } else {
      emit(const OnDutyRequestLoading());
    }

    final result = await getOnDutyRequestsUseCase(
      GetOnDutyRequestsParams(
        clientId: event.clientId,
        page: event.page,
        limit: event.limit,
        status: event.status,
      ),
    );
    final statsUseCase = getOnDutyRequestStatsUseCase;
    final statsResult =
        statsUseCase == null
            ? null
            : await statsUseCase(
              GetOnDutyRequestStatsParams(
                clientId: event.clientId,
                requestType: 'User',
              ),
            );
    result.fold(
      (failure) {
        if (requestSequence != _latestSelfRequestSequence ||
            _activeSelfRequestKey != cacheKey) {
          return;
        }

        if (previousLoadedState != null) {
          emit(
            previousLoadedState.copyWith(
              onDutyRequests: const [],
              filteredOnDutyRequests: const [],
              isRefreshing: false,
              isLoadingMore: false,
              hasMore: false,
              currentPage: event.page,
              statusFilter: event.status,
              contentErrorMessage: failure.message,
            ),
          );
          return;
        }

        emit(OnDutyRequestError(failure.message));
      },
      (onDutyRequests) {
        if (requestSequence != _latestSelfRequestSequence ||
            _activeSelfRequestKey != cacheKey) {
          return;
        }

        var loadedState = OnDutyRequestLoaded(
          onDutyRequests: onDutyRequests,
          filteredOnDutyRequests: onDutyRequests,
          searchQuery: previousLoadedState?.searchQuery,
          statusFilter: event.status,
          currentPage: event.page,
          isRefreshing: false,
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
            );
          },
        );

        loadedState = loadedState.copyWith(
          hasMore: _hasMoreForStatus(
            loadedCount: onDutyRequests.length,
            pageSize: event.limit,
            status: event.status,
            state: loadedState,
          ),
        );

        _selfOnDutyRequestsCache[cacheKey] = loadedState;
        emit(_buildLoadedState(loadedState));
      },
    );
  }

  Future<void> _onLoadMoreOnDutyRequests(
    LoadMoreOnDutyRequests event,
    Emitter<OnDutyRequestState> emit,
  ) async {
    if (state is! OnDutyRequestLoaded) return;

    final currentState = state as OnDutyRequestLoaded;
    final requestKey = _selfOnDutyCacheKey(currentState.statusFilter);
    if (currentState.isTeamRequestMode ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        _activeSelfRequestKey != requestKey) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getOnDutyRequestsUseCase(
      GetOnDutyRequestsParams(
        clientId: event.clientId,
        page: currentState.currentPage + 1,
        limit: event.limit,
        status: currentState.statusFilter,
      ),
    );

    result.fold(
      (_) {
        if (_activeSelfRequestKey != requestKey ||
            state is! OnDutyRequestLoaded) {
          return;
        }

        final latestState = state as OnDutyRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
      },
      (pageItems) {
        if (_activeSelfRequestKey != requestKey ||
            state is! OnDutyRequestLoaded) {
          return;
        }

        final latestState = state as OnDutyRequestLoaded;
        final merged = _mergeUniqueById(
          latestState.onDutyRequests,
          pageItems,
        );

        final nextState = _buildLoadedState(
          latestState.copyWith(
            onDutyRequests: merged,
            isLoadingMore: false,
            currentPage: latestState.currentPage + 1,
            hasMore: _hasMoreForStatus(
              loadedCount: merged.length,
              pageSize: event.limit,
              status: latestState.statusFilter,
              state: latestState,
            ),
          ),
        );

        emit(nextState);
        _selfOnDutyRequestsCache[requestKey] = nextState;
      },
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

    final previousLoadedState =
        state is OnDutyRequestLoaded && (state as OnDutyRequestLoaded).isTeamRequestMode
            ? state as OnDutyRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _teamOnDutyRequestsCache.clear();
    }

    final cacheKey = _teamOnDutyCacheKey(event.scope, event.status);
    final requestSequence = ++_latestTeamRequestSequence;
    _activeTeamRequestKey = cacheKey;
    final cachedState = _teamOnDutyRequestsCache[cacheKey];

    if (event.page == 1 && !event.forceRefresh && cachedState != null) {
      emit(
        _buildLoadedState(
          cachedState.copyWith(
            searchQuery: previousLoadedState?.searchQuery,
            isRefreshing: false,
            isLoadingMore: false,
            contentErrorMessage: null,
          ),
        ),
      );
      return;
    }

    if (previousLoadedState != null) {
      emit(
        previousLoadedState.copyWith(
          isRefreshing: true,
          isLoadingMore: false,
          statusFilter: event.status,
          selectedScope: event.scope,
          contentErrorMessage: null,
        ),
      );
    } else {
      emit(const OnDutyRequestLoading());
    }

    final result = await teamUseCase(
      GetTeamOnDutyRequestsParams(
        clientId: event.clientId,
        page: event.page,
        limit: event.limit,
        scope: event.scope,
        status: event.status,
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
      (failure) {
        if (requestSequence != _latestTeamRequestSequence ||
            _activeTeamRequestKey != cacheKey) {
          return;
        }

        if (previousLoadedState != null) {
          emit(
            previousLoadedState.copyWith(
              onDutyRequests: const [],
              filteredOnDutyRequests: const [],
              isRefreshing: false,
              isLoadingMore: false,
              hasMore: false,
              currentPage: event.page,
              statusFilter: event.status,
              selectedScope: event.scope,
              contentErrorMessage: failure.message,
            ),
          );
          return;
        }

        emit(OnDutyRequestError(failure.message));
      },
      (onDutyRequests) {
        if (requestSequence != _latestTeamRequestSequence ||
            _activeTeamRequestKey != cacheKey) {
          return;
        }

        var loadedState = OnDutyRequestLoaded(
          onDutyRequests: onDutyRequests,
          filteredOnDutyRequests: onDutyRequests,
          isTeamRequestMode: true,
          statusFilter: event.status,
          selectedScope: event.scope,
          currentPage: event.page,
          isRefreshing: false,
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
            );
          },
        );

        loadedState = loadedState.copyWith(
          hasMore: _hasMoreForStatus(
            loadedCount: onDutyRequests.length,
            pageSize: event.limit,
            status: event.status,
            state: loadedState,
          ),
        );

        _teamOnDutyRequestsCache[cacheKey] = loadedState;
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
    final requestKey = _teamOnDutyCacheKey(
      currentState.selectedScope,
      currentState.statusFilter,
    );
    if (teamUseCase == null ||
        !currentState.isTeamRequestMode ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        _activeTeamRequestKey != requestKey) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await teamUseCase(
      GetTeamOnDutyRequestsParams(
        clientId: event.clientId,
        page: currentState.currentPage + 1,
        limit: event.limit,
        scope: currentState.selectedScope,
        status: currentState.statusFilter,
      ),
    );

    result.fold(
      (_) {
        if (_activeTeamRequestKey != requestKey || state is! OnDutyRequestLoaded) {
          return;
        }

        final latestState = state as OnDutyRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
      },
      (pageItems) {
        if (_activeTeamRequestKey != requestKey || state is! OnDutyRequestLoaded) {
          return;
        }

        final latestState = state as OnDutyRequestLoaded;
        final merged = _mergeUniqueById(latestState.onDutyRequests, pageItems);

        final nextState = _buildLoadedState(
          latestState.copyWith(
            onDutyRequests: merged,
            isLoadingMore: false,
            currentPage: latestState.currentPage + 1,
            hasMore: _hasMoreForStatus(
              loadedCount: merged.length,
              pageSize: event.limit,
              status: latestState.statusFilter,
              state: latestState,
            ),
          ),
        );

        emit(nextState);
        _teamOnDutyRequestsCache[requestKey] = nextState;
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

  OnDutyRequestLoaded buildTeamOnDutyViewState({
    required OnDutyRequestLoaded baseState,
    String? searchQuery,
  }) {
    return _buildLoadedState(
      baseState.copyWith(searchQuery: searchQuery),
    );
  }

  OnDutyRequestLoaded? getCachedOnDutyRequests({
    required OnDutyStatus? status,
  }) {
    return _selfOnDutyRequestsCache[_selfOnDutyCacheKey(status)];
  }

  OnDutyRequestLoaded buildOnDutyViewState({
    required OnDutyRequestLoaded baseState,
    String? searchQuery,
  }) {
    return _buildLoadedState(
      baseState.copyWith(searchQuery: searchQuery),
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

  String _teamOnDutyCacheKey(
    RequestAudienceScope scope,
    OnDutyStatus? status,
  ) => '${scope.name}:${status?.name ?? 'all'}';

  String _selfOnDutyCacheKey(
    OnDutyStatus? status,
  ) => status?.name ?? 'all';

  OnDutyRequestLoaded? getCachedTeamOnDutyRequests({
    required RequestAudienceScope scope,
    required OnDutyStatus? status,
  }) {
    return _teamOnDutyRequestsCache[_teamOnDutyCacheKey(scope, status)];
  }

  int _countForStatus(OnDutyStatus? status, OnDutyRequestLoaded state) {
    switch (status) {
      case OnDutyStatus.pending:
        return state.pendingCount;
      case OnDutyStatus.approved:
        return state.approvedCount;
      case OnDutyStatus.rejected:
        return state.rejectedCount;
      case OnDutyStatus.withdrawn:
        return state.withdrawnCount;
      case null:
        return state.totalCount;
    }
  }

  bool _hasMoreForStatus({
    required int loadedCount,
    required int pageSize,
    required OnDutyStatus? status,
    required OnDutyRequestLoaded state,
  }) {
    final totalForStatus = _countForStatus(status, state);
    if (totalForStatus > 0) {
      return loadedCount < totalForStatus;
    }

    return loadedCount >= pageSize;
  }
}
