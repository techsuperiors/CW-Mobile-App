import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';

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
  final Map<String, OvertimeRequestLoaded> _selfOvertimeRequestsCache = {};
  final Map<String, OvertimeRequestLoaded> _teamOvertimeRequestsCache = {};
  int _latestSelfRequestSequence = 0;
  String? _activeSelfRequestKey;
  int _latestTeamRequestSequence = 0;
  String? _activeTeamRequestKey;

  OvertimeRequestBloc({
    required this.getOvertimeRequestsUseCase,
    this.getOvertimeRequestStatsUseCase,
    this.getTeamOvertimeRequestsUseCase,
  })
      : super(const OvertimeRequestInitial()) {
    on<LoadOvertimeRequests>(_onLoadOvertimeRequests);
    on<LoadMoreOvertimeRequests>(_onLoadMoreOvertimeRequests);
    on<LoadTeamOvertimeRequests>(_onLoadTeamOvertimeRequests);
    on<LoadMoreTeamOvertimeRequests>(_onLoadMoreTeamOvertimeRequests);
    on<SearchOvertimeRequests>(_onSearchOvertimeRequests);
    on<FilterOvertimeRequestsByStatus>(_onFilterOvertimeRequestsByStatus);
  }

  Future<void> _onLoadOvertimeRequests(
    LoadOvertimeRequests event,
    Emitter<OvertimeRequestState> emit,
  ) async {
    final previousLoadedState =
        state is OvertimeRequestLoaded &&
                !(state as OvertimeRequestLoaded).isTeamRequestMode
            ? state as OvertimeRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _selfOvertimeRequestsCache.clear();
    }

    final cacheKey = _selfOvertimeCacheKey(event.status);
    final requestSequence = ++_latestSelfRequestSequence;
    _activeSelfRequestKey = cacheKey;
    final cachedState = _selfOvertimeRequestsCache[cacheKey];

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
      emit(const OvertimeRequestLoading());
    }

    final result = await getOvertimeRequestsUseCase(
      GetOvertimeRequestsParams(
        clientId: event.clientId,
        page: event.page,
        limit: event.limit,
        status: event.status,
      ),
    );
    final statsUseCase = getOvertimeRequestStatsUseCase;
    final statsResult =
        statsUseCase == null
            ? null
            : await statsUseCase(
              GetOvertimeRequestStatsParams(
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
              requests: const [],
              filteredRequests: const [],
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

        emit(OvertimeRequestError(failure.message));
      },
      (requests) {
        if (requestSequence != _latestSelfRequestSequence ||
            _activeSelfRequestKey != cacheKey) {
          return;
        }

        var loadedState = OvertimeRequestLoaded(
          requests: requests,
          filteredRequests: requests,
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
            loadedCount: requests.length,
            pageSize: event.limit,
            status: event.status,
            state: loadedState,
          ),
        );

        _selfOvertimeRequestsCache[cacheKey] = loadedState;
        emit(_buildLoadedState(loadedState));
      },
    );
  }

  Future<void> _onLoadMoreOvertimeRequests(
    LoadMoreOvertimeRequests event,
    Emitter<OvertimeRequestState> emit,
  ) async {
    if (state is! OvertimeRequestLoaded) return;

    final current = state as OvertimeRequestLoaded;
    final requestKey = _selfOvertimeCacheKey(current.statusFilter);
    if (current.isTeamRequestMode ||
        current.isLoadingMore ||
        !current.hasMore ||
        _activeSelfRequestKey != requestKey) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    final result = await getOvertimeRequestsUseCase(
      GetOvertimeRequestsParams(
        clientId: event.clientId,
        page: current.currentPage + 1,
        limit: event.limit,
        status: current.statusFilter,
      ),
    );

    result.fold(
      (_) {
        if (_activeSelfRequestKey != requestKey ||
            state is! OvertimeRequestLoaded) {
          return;
        }

        final latestState = state as OvertimeRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
      },
      (pageItems) {
        if (_activeSelfRequestKey != requestKey ||
            state is! OvertimeRequestLoaded) {
          return;
        }

        final latestState = state as OvertimeRequestLoaded;
        final merged = _mergeUniqueById(latestState.requests, pageItems);
        final nextState = _buildLoadedState(
          latestState.copyWith(
            requests: merged,
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
        _selfOvertimeRequestsCache[requestKey] = nextState;
      },
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

    final previousLoadedState =
        state is OvertimeRequestLoaded &&
                (state as OvertimeRequestLoaded).isTeamRequestMode
            ? state as OvertimeRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _teamOvertimeRequestsCache.clear();
    }

    final cacheKey = _teamOvertimeCacheKey(event.scope, event.status);
    final requestSequence = ++_latestTeamRequestSequence;
    _activeTeamRequestKey = cacheKey;
    final cachedState = _teamOvertimeRequestsCache[cacheKey];

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
      emit(const OvertimeRequestLoading());
    }
    final result = await teamUseCase(
      GetTeamOvertimeRequestsParams(
        clientId: event.clientId,
        page: event.page,
        limit: event.limit,
        scope: event.scope,
        status: event.status,
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
      (failure) {
        if (requestSequence != _latestTeamRequestSequence ||
            _activeTeamRequestKey != cacheKey) {
          return;
        }

        if (previousLoadedState != null) {
          emit(
            previousLoadedState.copyWith(
              requests: const [],
              filteredRequests: const [],
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

        emit(OvertimeRequestError(failure.message));
      },
      (requests) {
        if (requestSequence != _latestTeamRequestSequence ||
            _activeTeamRequestKey != cacheKey) {
          return;
        }

        var loadedState = OvertimeRequestLoaded(
          requests: requests,
          filteredRequests: requests,
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
            loadedCount: requests.length,
            pageSize: event.limit,
            status: event.status,
            state: loadedState,
          ),
        );

        _teamOvertimeRequestsCache[cacheKey] = loadedState;
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
    final requestKey = _teamOvertimeCacheKey(
      current.selectedScope,
      current.statusFilter,
    );
    if (teamUseCase == null ||
        !current.isTeamRequestMode ||
        current.isLoadingMore ||
        !current.hasMore ||
        _activeTeamRequestKey != requestKey) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    final result = await teamUseCase(
      GetTeamOvertimeRequestsParams(
        clientId: event.clientId,
        page: current.currentPage + 1,
        limit: event.limit,
        scope: current.selectedScope,
        status: current.statusFilter,
      ),
    );

    result.fold(
      (_) {
        if (_activeTeamRequestKey != requestKey || state is! OvertimeRequestLoaded) {
          return;
        }

        final latestState = state as OvertimeRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
      },
      (pageItems) {
        if (_activeTeamRequestKey != requestKey || state is! OvertimeRequestLoaded) {
          return;
        }

        final latestState = state as OvertimeRequestLoaded;
        final merged = _mergeUniqueById(latestState.requests, pageItems);
        final nextState = _buildLoadedState(
          latestState.copyWith(
            requests: merged,
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
        _teamOvertimeRequestsCache[requestKey] = nextState;
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

  OvertimeRequestLoaded buildTeamOvertimeViewState({
    required OvertimeRequestLoaded baseState,
    String? searchQuery,
  }) {
    return _buildLoadedState(
      baseState.copyWith(searchQuery: searchQuery),
    );
  }

  OvertimeRequestLoaded? getCachedOvertimeRequests({
    required OvertimeStatus? status,
  }) {
    return _selfOvertimeRequestsCache[_selfOvertimeCacheKey(status)];
  }

  OvertimeRequestLoaded buildOvertimeViewState({
    required OvertimeRequestLoaded baseState,
    String? searchQuery,
  }) {
    return _buildLoadedState(
      baseState.copyWith(searchQuery: searchQuery),
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

  String _teamOvertimeCacheKey(
    RequestAudienceScope scope,
    OvertimeStatus? status,
  ) => '${scope.name}:${status?.name ?? 'all'}';

  String _selfOvertimeCacheKey(
    OvertimeStatus? status,
  ) => status?.name ?? 'all';

  OvertimeRequestLoaded? getCachedTeamOvertimeRequests({
    required RequestAudienceScope scope,
    required OvertimeStatus? status,
  }) {
    return _teamOvertimeRequestsCache[_teamOvertimeCacheKey(scope, status)];
  }

  int _countForStatus(
    OvertimeStatus? status,
    OvertimeRequestLoaded state,
  ) {
    switch (status) {
      case OvertimeStatus.pending:
        return state.pendingCount;
      case OvertimeStatus.approved:
        return state.approvedCount;
      case OvertimeStatus.rejected:
        return state.rejectedCount;
      case OvertimeStatus.withdrawn:
        return state.withdrawnCount;
      case null:
        return state.totalCount;
    }
  }

  bool _hasMoreForStatus({
    required int loadedCount,
    required int pageSize,
    required OvertimeStatus? status,
    required OvertimeRequestLoaded state,
  }) {
    final totalForStatus = _countForStatus(status, state);
    if (totalForStatus > 0) {
      return loadedCount < totalForStatus;
    }

    return loadedCount >= pageSize;
  }
}
