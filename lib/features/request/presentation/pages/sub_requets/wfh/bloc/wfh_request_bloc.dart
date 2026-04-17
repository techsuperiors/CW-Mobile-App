import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
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
  final Map<String, WfhRequestLoaded> _selfWfhRequestsCache = {};
  final Map<String, WfhRequestLoaded> _teamWfhRequestsCache = {};
  int _latestSelfRequestSequence = 0;
  String? _activeSelfRequestKey;
  int _latestTeamRequestSequence = 0;
  String? _activeTeamRequestKey;

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
    final previousLoadedState =
        state is WfhRequestLoaded && !(state as WfhRequestLoaded).isTeamRequestMode
            ? state as WfhRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _selfWfhRequestsCache.clear();
    }

    final cacheKey = _selfWfhCacheKey(event.status);
    final requestSequence = ++_latestSelfRequestSequence;
    _activeSelfRequestKey = cacheKey;
    final cachedState = _selfWfhRequestsCache[cacheKey];

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
      emit(const WfhRequestLoading());
    }

    final statsResult = await getWfhRequestStatsUseCase(
      GetWfhRequestStatsParams(
        clientId: event.clientId,
        requestType: 'User',
      ),
    );
    final result = await getWfhRequestsUseCase(
      GetWfhRequestsParams(
        clientId: event.clientId,
        page: event.page,
        limit: event.limit,
        status: event.status,
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
              wfhRequests: const [],
              filteredWfhRequests: const [],
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

        emit(WfhRequestError(failure.message));
      },
      (pageData) {
        if (requestSequence != _latestSelfRequestSequence ||
            _activeSelfRequestKey != cacheKey) {
          return;
        }

        var loadedState = WfhRequestLoaded(
          wfhRequests: pageData.requests,
          filteredWfhRequests: pageData.requests,
          searchQuery: previousLoadedState?.searchQuery,
          statusFilter: event.status,
          currentPage: event.page,
          isRefreshing: false,
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
            );
          },
        );

        loadedState = loadedState.copyWith(
          hasMore: _hasMoreForStatus(
            loadedCount: pageData.requests.length,
            pageSize: event.limit,
            status: event.status,
            state: loadedState,
          ),
        );

        _selfWfhRequestsCache[cacheKey] = loadedState;
        emit(_buildLoadedState(loadedState));
      },
    );
  }

  Future<void> _onLoadMoreWfhRequests(
    LoadMoreWfhRequests event,
    Emitter<WfhRequestState> emit,
  ) async {
    if (state is! WfhRequestLoaded) return;

    final currentState = state as WfhRequestLoaded;
    final requestKey = _selfWfhCacheKey(currentState.statusFilter);
    if (currentState.isTeamRequestMode ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        _activeSelfRequestKey != requestKey) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getWfhRequestsUseCase(
      GetWfhRequestsParams(
        clientId: event.clientId,
        page: currentState.currentPage + 1,
        limit: event.limit,
        status: currentState.statusFilter,
      ),
    );

    result.fold(
      (_) {
        if (_activeSelfRequestKey != requestKey || state is! WfhRequestLoaded) {
          return;
        }

        final latestState = state as WfhRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
      },
      (pageData) {
        if (_activeSelfRequestKey != requestKey || state is! WfhRequestLoaded) {
          return;
        }

        final latestState = state as WfhRequestLoaded;
        final merged = _mergeUniqueById(
          latestState.wfhRequests,
          pageData.requests,
        );

        final nextState = _buildLoadedState(
          latestState.copyWith(
            wfhRequests: merged,
            isLoadingMore: false,
            hasMore: _hasMoreForStatus(
              loadedCount: merged.length,
              pageSize: event.limit,
              status: latestState.statusFilter,
              state: latestState,
            ),
            currentPage: latestState.currentPage + 1,
          ),
        );

        emit(nextState);
        _selfWfhRequestsCache[requestKey] = nextState;
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

    final previousLoadedState =
        state is WfhRequestLoaded && (state as WfhRequestLoaded).isTeamRequestMode
            ? state as WfhRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _teamWfhRequestsCache.clear();
    }

    final cacheKey = _teamWfhCacheKey(event.scope, event.status);
    final requestSequence = ++_latestTeamRequestSequence;
    _activeTeamRequestKey = cacheKey;
    final cachedState = _teamWfhRequestsCache[cacheKey];

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
      emit(const WfhRequestLoading());
    }

    final result = await teamUseCase(
      GetTeamWfhRequestsParams(
        clientId: event.clientId,
        page: event.page,
        limit: event.limit,
        scope: event.scope,
        status: event.status,
      ),
    );

    final statsResult = await getWfhRequestStatsUseCase(
      GetWfhRequestStatsParams(
        clientId: event.clientId,
        requestType: _statsRequestTypeForScope(event.scope),
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
              wfhRequests: const [],
              filteredWfhRequests: const [],
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

        emit(WfhRequestError(failure.message));
      },
      (wfhRequests) {
        if (requestSequence != _latestTeamRequestSequence ||
            _activeTeamRequestKey != cacheKey) {
          return;
        }

        var loadedState = WfhRequestLoaded(
          wfhRequests: wfhRequests,
          filteredWfhRequests: wfhRequests,
          searchQuery: previousLoadedState?.searchQuery,
          isTeamRequestMode: true,
          statusFilter: event.status,
          selectedScope: event.scope,
          currentPage: event.page,
          isRefreshing: false,
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
            );
          },
        );

        loadedState = loadedState.copyWith(
          hasMore: _hasMoreForStatus(
            loadedCount: wfhRequests.length,
            pageSize: event.limit,
            status: event.status,
            state: loadedState,
          ),
        );

        _teamWfhRequestsCache[cacheKey] = loadedState;
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
    final requestKey = _teamWfhCacheKey(
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
      GetTeamWfhRequestsParams(
        clientId: event.clientId,
        page: currentState.currentPage + 1,
        limit: event.limit,
        scope: currentState.selectedScope,
        status: currentState.statusFilter,
      ),
    );

    result.fold(
      (_) {
        if (_activeTeamRequestKey != requestKey || state is! WfhRequestLoaded) {
          return;
        }

        final latestState = state as WfhRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
      },
      (pageItems) {
        if (_activeTeamRequestKey != requestKey || state is! WfhRequestLoaded) {
          return;
        }

        final latestState = state as WfhRequestLoaded;
        final merged = _mergeUniqueById(currentState.wfhRequests, pageItems);

        final nextState = _buildLoadedState(
          latestState.copyWith(
            wfhRequests: merged,
            isLoadingMore: false,
            hasMore: _hasMoreForStatus(
              loadedCount: merged.length,
              pageSize: event.limit,
              status: latestState.statusFilter,
              state: latestState,
            ),
            currentPage: latestState.currentPage + 1,
          ),
        );

        emit(nextState);
        _teamWfhRequestsCache[requestKey] = nextState;
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

  WfhRequestLoaded buildTeamWfhViewState({
    required WfhRequestLoaded baseState,
    String? searchQuery,
  }) {
    return _buildLoadedState(
      baseState.copyWith(searchQuery: searchQuery),
    );
  }

  WfhRequestLoaded? getCachedWfhRequests({
    required WfhStatus? status,
  }) {
    return _selfWfhRequestsCache[_selfWfhCacheKey(status)];
  }

  WfhRequestLoaded buildWfhViewState({
    required WfhRequestLoaded baseState,
    String? searchQuery,
  }) {
    return _buildLoadedState(
      baseState.copyWith(searchQuery: searchQuery),
    );
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

  String _teamWfhCacheKey(
    RequestAudienceScope scope,
    WfhStatus? status,
  ) => '${scope.name}:${status?.name ?? 'all'}';

  String _selfWfhCacheKey(
    WfhStatus? status,
  ) => status?.name ?? 'all';

  WfhRequestLoaded? getCachedTeamWfhRequests({
    required RequestAudienceScope scope,
    required WfhStatus? status,
  }) {
    return _teamWfhRequestsCache[_teamWfhCacheKey(scope, status)];
  }

  String _statsRequestTypeForScope(RequestAudienceScope scope) {
    if (scope == RequestAudienceScope.allUsers) {
      return '';
    }
    return scope.attendanceRequestType;
  }

  int _countForStatus(WfhStatus? status, WfhRequestLoaded state) {
    switch (status) {
      case WfhStatus.pending:
        return state.pendingCount;
      case WfhStatus.approved:
        return state.approvedCount;
      case WfhStatus.rejected:
        return state.rejectedCount;
      case WfhStatus.withdrawn:
        return state.withdrawnCount;
      case null:
        return state.totalCount;
    }
  }

  bool _hasMoreForStatus({
    required int loadedCount,
    required int pageSize,
    required WfhStatus? status,
    required WfhRequestLoaded state,
  }) {
    final totalForStatus = _countForStatus(status, state);
    if (totalForStatus > 0) {
      return loadedCount < totalForStatus;
    }

    return loadedCount >= pageSize;
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
