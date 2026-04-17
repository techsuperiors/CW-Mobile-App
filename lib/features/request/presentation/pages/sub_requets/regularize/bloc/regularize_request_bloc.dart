import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../models/regularize_request_model.dart';
import 'regularize_request_event.dart';
import 'regularize_request_state.dart';

/// Regularize request BLoC — fetches regularize requests from API.
class RegularizeRequestBloc
    extends Bloc<RegularizeRequestEvent, RegularizeRequestState> {
  final Map<String, RegularizeRequestLoaded> _selfRegularizeRequestsCache = {};
  final Map<String, RegularizeRequestLoaded> _teamRegularizeRequestsCache = {};
  int _latestSelfRequestSequence = 0;
  String? _activeSelfRequestKey;
  int _latestTeamRequestSequence = 0;
  String? _activeTeamRequestKey;

  RegularizeRequestBloc() : super(const RegularizeRequestInitial()) {
    on<LoadRegularizeRequests>(_onLoadRegularizeRequests);
    on<LoadMoreRegularizeRequests>(_onLoadMoreRegularizeRequests);
    on<LoadTeamRegularizeRequests>(_onLoadTeamRegularizeRequests);
    on<LoadMoreTeamRegularizeRequests>(_onLoadMoreTeamRegularizeRequests);
    on<SearchRegularizeRequests>(_onSearchRegularizeRequests);
    on<FilterRegularizeRequestsByStatus>(_onFilterRegularizeRequestsByStatus);
    on<ClearFilters>(_onClearFilters);
  }

  /// Load regularize requests from API.
  Future<void> _onLoadRegularizeRequests(
    LoadRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) async {
    final previousLoadedState =
        state is RegularizeRequestLoaded &&
                !(state as RegularizeRequestLoaded).isTeamRequestMode
            ? state as RegularizeRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _selfRegularizeRequestsCache.clear();
    }

    final cacheKey = _selfRegularizeCacheKey(event.status);
    final requestSequence = ++_latestSelfRequestSequence;
    _activeSelfRequestKey = cacheKey;
    final cachedState = _selfRegularizeRequestsCache[cacheKey];

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
      emit(const RegularizeRequestLoading());
    }

    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);

      if (!await networkInfo.isConnected) {
        if (previousLoadedState != null) {
          emit(
            previousLoadedState.copyWith(
              regularizeRequests: const [],
              filteredRegularizeRequests: const [],
              isRefreshing: false,
              isLoadingMore: false,
              hasMore: false,
              currentPage: event.page,
              statusFilter: event.status,
              contentErrorMessage: 'No internet connection',
            ),
          );
        } else {
          emit(const RegularizeRequestError('No internet connection'));
        }
        return;
      }

      final stats = await _fetchRegularizeStats(
        apiClient,
        requestType: 'User',
      );

      final payload = encodeData({
        'client_id': event.clientId,
        'users': <dynamic>[],
        'status':
            event.status == null
                ? <dynamic>[]
                : <String>[event.status!.displayName],
        'date': '',
        'approved_by': <dynamic>[],
        'rejected_by': <dynamic>[],
        'request_type': '',
        'page': event.page,
        'limit': event.limit,
      });

      final response = await apiClient.get(
        '${AppUrls.attendanceRequest}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load regularize requests',
        );
      }

      if (requestSequence != _latestSelfRequestSequence ||
          _activeSelfRequestKey != cacheKey) {
        return;
      }

      final List<dynamic> requestsList = data['data'] as List<dynamic>? ?? [];
      final regularizeRequests =
          requestsList
              .map(
                (item) => RegularizeRequestModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();

      var loadedState = RegularizeRequestLoaded(
        regularizeRequests: regularizeRequests,
        filteredRegularizeRequests: regularizeRequests,
        searchQuery: previousLoadedState?.searchQuery,
        statusFilter: event.status,
        currentPage: event.page,
        isRefreshing: false,
        totalCount: stats?['total'] ?? 0,
        pendingCount: stats?['pending'] ?? 0,
        approvedCount: stats?['approved'] ?? 0,
        rejectedCount: stats?['rejected'] ?? 0,
        withdrawnCount: stats?['withdrawn'] ?? 0,
      );

      loadedState = loadedState.copyWith(
        hasMore: _hasMoreForStatus(
          loadedCount: regularizeRequests.length,
          pageSize: event.limit,
          status: event.status,
          state: loadedState,
        ),
      );

      _selfRegularizeRequestsCache[cacheKey] = loadedState;
      emit(loadedState);
    } on ServerException catch (e) {
      if (requestSequence != _latestSelfRequestSequence ||
          _activeSelfRequestKey != cacheKey) {
        return;
      }

      if (previousLoadedState != null) {
        emit(
          previousLoadedState.copyWith(
            regularizeRequests: const [],
            filteredRegularizeRequests: const [],
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: false,
            currentPage: event.page,
            statusFilter: event.status,
            contentErrorMessage: e.message,
          ),
        );
        return;
      }

      emit(RegularizeRequestError(e.message));
    } catch (_) {
      if (requestSequence != _latestSelfRequestSequence ||
          _activeSelfRequestKey != cacheKey) {
        return;
      }

      if (previousLoadedState != null) {
        emit(
          previousLoadedState.copyWith(
            regularizeRequests: const [],
            filteredRegularizeRequests: const [],
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: false,
            currentPage: event.page,
            statusFilter: event.status,
            contentErrorMessage: 'Failed to load regularize requests',
          ),
        );
        return;
      }

      emit(const RegularizeRequestError('Failed to load regularize requests'));
    }
  }

  Future<void> _onLoadMoreRegularizeRequests(
    LoadMoreRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) async {
    if (state is! RegularizeRequestLoaded) return;

    final currentState = state as RegularizeRequestLoaded;
    final requestKey = _selfRegularizeCacheKey(currentState.statusFilter);
    if (currentState.isTeamRequestMode ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        _activeSelfRequestKey != requestKey) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);

      if (!await networkInfo.isConnected) {
        emit(currentState.copyWith(isLoadingMore: false));
        return;
      }

      final payload = encodeData({
        'client_id': event.clientId,
        'users': <dynamic>[],
        'status':
            currentState.statusFilter == null
                ? <dynamic>[]
                : <String>[currentState.statusFilter!.displayName],
        'date': '',
        'approved_by': <dynamic>[],
        'rejected_by': <dynamic>[],
        'request_type': '',
        'page': currentState.currentPage + 1,
        'limit': event.limit,
      });

      final response = await apiClient.get(
        '${AppUrls.attendanceRequest}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        if (_activeSelfRequestKey != requestKey ||
            state is! RegularizeRequestLoaded) {
          return;
        }
        final latestState = state as RegularizeRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
        return;
      }

      final List<dynamic> requestsList = data['data'] as List<dynamic>? ?? [];
      final incoming =
          requestsList
              .map(
                (item) => RegularizeRequestModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();

      if (_activeSelfRequestKey != requestKey ||
          state is! RegularizeRequestLoaded) {
        return;
      }

      final latestState = state as RegularizeRequestLoaded;
      final merged = _mergeUniqueById(
        latestState.regularizeRequests,
        incoming,
      );

      final nextState = _buildLoadedState(
        latestState.copyWith(
          regularizeRequests: merged,
          filteredRegularizeRequests: merged,
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
      _selfRegularizeRequestsCache[requestKey] = nextState;
    } on ServerException {
      if (_activeSelfRequestKey != requestKey ||
          state is! RegularizeRequestLoaded) {
        return;
      }
      final latestState = state as RegularizeRequestLoaded;
      emit(latestState.copyWith(isLoadingMore: false));
    } catch (_) {
      if (_activeSelfRequestKey != requestKey ||
          state is! RegularizeRequestLoaded) {
        return;
      }
      final latestState = state as RegularizeRequestLoaded;
      emit(latestState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onLoadTeamRegularizeRequests(
    LoadTeamRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) async {
    final previousLoadedState =
        state is RegularizeRequestLoaded &&
                (state as RegularizeRequestLoaded).isTeamRequestMode
            ? state as RegularizeRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _teamRegularizeRequestsCache.clear();
    }

    final cacheKey = _teamRegularizeCacheKey(event.scope, event.status);
    final requestSequence = ++_latestTeamRequestSequence;
    _activeTeamRequestKey = cacheKey;
    final cachedState = _teamRegularizeRequestsCache[cacheKey];

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
      emit(const RegularizeRequestLoading());
    }

    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);

      if (!await networkInfo.isConnected) {
        if (previousLoadedState != null) {
          emit(
            previousLoadedState.copyWith(
              regularizeRequests: const [],
              filteredRegularizeRequests: const [],
              isRefreshing: false,
              isLoadingMore: false,
              hasMore: false,
              currentPage: event.page,
              statusFilter: event.status,
              selectedScope: event.scope,
              contentErrorMessage: 'No internet connection',
            ),
          );
        } else {
          emit(const RegularizeRequestError('No internet connection'));
        }
        return;
      }

      final stats = await _fetchRegularizeStats(
        apiClient,
        clientId: event.clientId,
        requestType: event.scope.attendanceRequestType,
      );

      final payload = encodeData({
        'client_id': event.clientId,
        'users': <dynamic>[],
        'status':
            event.status == null ? <dynamic>[] : <String>[event.status!.displayName],
        'date': '',
        'approved_by': <dynamic>[],
        'rejected_by': <dynamic>[],
        'request_type': event.scope.attendanceRequestType,
        'page': event.page,
        'limit': event.limit,
      });

      final response = await apiClient.get(
        '${AppUrls.regularizeTeamList}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Failed to load regularize requests',
        );
      }

      if (requestSequence != _latestTeamRequestSequence ||
          _activeTeamRequestKey != cacheKey) {
        return;
      }

      final List<dynamic> requestsList = data['data'] as List<dynamic>? ?? [];
      final regularizeRequests =
          requestsList
              .map(
                (item) => RegularizeRequestModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();

      var loadedState = RegularizeRequestLoaded(
        regularizeRequests: regularizeRequests,
        filteredRegularizeRequests: regularizeRequests,
        searchQuery: previousLoadedState?.searchQuery,
        selectedScope: event.scope,
        statusFilter: event.status,
        isTeamRequestMode: true,
        currentPage: event.page,
        isRefreshing: false,
        totalCount: stats?['total'] ?? 0,
        pendingCount: stats?['pending'] ?? 0,
        approvedCount: stats?['approved'] ?? 0,
        rejectedCount: stats?['rejected'] ?? 0,
        withdrawnCount: stats?['withdrawn'] ?? 0,
      );

      loadedState = loadedState.copyWith(
        hasMore: _hasMoreForStatus(
          loadedCount: regularizeRequests.length,
          pageSize: event.limit,
          status: event.status,
          state: loadedState,
        ),
      );

      _teamRegularizeRequestsCache[cacheKey] = loadedState;
      emit(loadedState);
    } on ServerException catch (e) {
      if (requestSequence != _latestTeamRequestSequence ||
          _activeTeamRequestKey != cacheKey) {
        return;
      }

      if (previousLoadedState != null) {
        emit(
          previousLoadedState.copyWith(
            regularizeRequests: const [],
            filteredRegularizeRequests: const [],
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: false,
            currentPage: event.page,
            statusFilter: event.status,
            selectedScope: event.scope,
            contentErrorMessage: e.message,
          ),
        );
        return;
      }
      emit(RegularizeRequestError(e.message));
    } catch (_) {
      if (requestSequence != _latestTeamRequestSequence ||
          _activeTeamRequestKey != cacheKey) {
        return;
      }

      if (previousLoadedState != null) {
        emit(
          previousLoadedState.copyWith(
            regularizeRequests: const [],
            filteredRegularizeRequests: const [],
            isRefreshing: false,
            isLoadingMore: false,
            hasMore: false,
            currentPage: event.page,
            statusFilter: event.status,
            selectedScope: event.scope,
            contentErrorMessage: 'Failed to load regularize requests',
          ),
        );
        return;
      }
      emit(const RegularizeRequestError('Failed to load regularize requests'));
    }
  }

  Future<void> _onLoadMoreTeamRegularizeRequests(
    LoadMoreTeamRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) async {
    if (state is! RegularizeRequestLoaded) return;

    final currentState = state as RegularizeRequestLoaded;
    final requestKey = _teamRegularizeCacheKey(
      currentState.selectedScope,
      currentState.statusFilter,
    );
    if (!currentState.isTeamRequestMode ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        _activeTeamRequestKey != requestKey) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);

      if (!await networkInfo.isConnected) {
        emit(currentState.copyWith(isLoadingMore: false));
        return;
      }

      final payload = encodeData({
        'client_id': event.clientId,
        'users': <dynamic>[],
        'status':
            currentState.statusFilter == null
                ? <dynamic>[]
                : <String>[currentState.statusFilter!.displayName],
        'date': '',
        'approved_by': <dynamic>[],
        'rejected_by': <dynamic>[],
        'request_type': currentState.selectedScope.attendanceRequestType,
        'page': currentState.currentPage + 1,
        'limit': event.limit,
      });

      final response = await apiClient.get(
        '${AppUrls.regularizeTeamList}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        if (_activeTeamRequestKey != requestKey || state is! RegularizeRequestLoaded) {
          return;
        }
        final latestState = state as RegularizeRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
        return;
      }

      final List<dynamic> requestsList = data['data'] as List<dynamic>? ?? [];
      final incoming =
          requestsList
              .map(
                (item) => RegularizeRequestModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();

      if (_activeTeamRequestKey != requestKey || state is! RegularizeRequestLoaded) {
        return;
      }

      final latestState = state as RegularizeRequestLoaded;
      final merged = _mergeUniqueById(
        latestState.regularizeRequests,
        incoming,
      );

      final nextState = _buildLoadedState(
        latestState.copyWith(
          regularizeRequests: merged,
          filteredRegularizeRequests: merged,
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
      _teamRegularizeRequestsCache[requestKey] = nextState;
    } on ServerException {
      if (_activeTeamRequestKey != requestKey || state is! RegularizeRequestLoaded) {
        return;
      }
      final latestState = state as RegularizeRequestLoaded;
      emit(latestState.copyWith(isLoadingMore: false));
    } catch (_) {
      if (_activeTeamRequestKey != requestKey || state is! RegularizeRequestLoaded) {
        return;
      }
      final latestState = state as RegularizeRequestLoaded;
      emit(latestState.copyWith(isLoadingMore: false));
    }
  }

  /// Search through already-loaded requests locally.
  void _onSearchRegularizeRequests(
    SearchRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) {
    if (state is RegularizeRequestLoaded) {
      final currentState = state as RegularizeRequestLoaded;
      final query = event.query.trim().toLowerCase();

      if (query.isEmpty) {
        final filtered = _applyFilters(
          currentState.regularizeRequests,
          currentState.statusFilter,
        );
        emit(
          currentState.copyWith(
            filteredRegularizeRequests: filtered,
            searchQuery: null,
          ),
        );
      } else {
        final searched =
            currentState.regularizeRequests
                .where(
                  (request) =>
                      request.reason.toLowerCase().contains(query) ||
                      request.requestType.displayName.toLowerCase().contains(
                        query,
                      ) ||
                      (request.description?.toLowerCase().contains(query) ??
                          false),
                )
                .toList();
        final filtered = _applyFilters(searched, currentState.statusFilter);
        emit(
          currentState.copyWith(
            filteredRegularizeRequests: filtered,
            searchQuery: query,
          ),
        );
      }
    }
  }

  void _onFilterRegularizeRequestsByStatus(
    FilterRegularizeRequestsByStatus event,
    Emitter<RegularizeRequestState> emit,
  ) {
    if (state is RegularizeRequestLoaded) {
      final currentState = state as RegularizeRequestLoaded;
      final baseList =
          currentState.searchQuery != null
              ? currentState.regularizeRequests
                  .where(
                    (r) =>
                        r.reason.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        r.requestType.displayName.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        (r.description?.toLowerCase().contains(
                              currentState.searchQuery!,
                            ) ??
                            false),
                  )
                  .toList()
              : currentState.regularizeRequests;
      final filtered = _applyFilters(baseList, event.status);
      emit(
        currentState.copyWith(
          filteredRegularizeRequests: filtered,
          statusFilter: event.status,
        ),
      );
    }
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<RegularizeRequestState> emit,
  ) {
    if (state is RegularizeRequestLoaded) {
      final currentState = state as RegularizeRequestLoaded;
      final filtered =
          currentState.searchQuery != null
              ? currentState.regularizeRequests
                  .where(
                    (r) =>
                        r.reason.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        r.requestType.displayName.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        (r.description?.toLowerCase().contains(
                              currentState.searchQuery!,
                            ) ??
                            false),
                  )
                  .toList()
              : currentState.regularizeRequests;
      emit(
        currentState.copyWith(
          filteredRegularizeRequests: filtered,
          statusFilter: null,
        ),
      );
    }
  }

  List<RegularizeRequestModel> _applyFilters(
    List<RegularizeRequestModel> requests,
    RegularizeStatus? statusFilter,
  ) {
    var filtered = requests;

    if (statusFilter != null) {
      filtered = filtered.where((r) => r.status == statusFilter).toList();
    }

    // Sort latest first — by appliedDate (created_at) descending
    filtered = List.of(filtered)
      ..sort((a, b) => b.appliedDate.compareTo(a.appliedDate));

    return filtered;
  }

  RegularizeRequestLoaded _buildLoadedState(RegularizeRequestLoaded state) {
    final searchedList = _applySearch(
      state.regularizeRequests,
      state.searchQuery,
    );
    final filtered = _applyFilters(searchedList, state.statusFilter);
    return state.copyWith(filteredRegularizeRequests: filtered);
  }

  List<RegularizeRequestModel> _applySearch(
    List<RegularizeRequestModel> requests,
    String? query,
  ) {
    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return requests;
    }

    return requests.where((request) {
      return request.reason.toLowerCase().contains(normalizedQuery) ||
          request.requestType.displayName.toLowerCase().contains(
            normalizedQuery,
          ) ||
          (request.description?.toLowerCase().contains(normalizedQuery) ??
              false);
    }).toList();
  }

  List<RegularizeRequestModel> _mergeUniqueById(
    List<RegularizeRequestModel> existing,
    List<RegularizeRequestModel> incoming,
  ) {
    final merged = <RegularizeRequestModel>[...existing];
    final seenIds = existing.map((item) => item.id).toSet();

    for (final item in incoming) {
      if (seenIds.add(item.id)) {
        merged.add(item);
      }
    }

    return merged;
  }

  String _selfRegularizeCacheKey(
    RegularizeStatus? status,
  ) => status?.name ?? 'all';

  RegularizeRequestLoaded? getCachedRegularizeRequests({
    required RegularizeStatus? status,
  }) {
    return _selfRegularizeRequestsCache[_selfRegularizeCacheKey(status)];
  }

  RegularizeRequestLoaded buildRegularizeViewState({
    required RegularizeRequestLoaded baseState,
    String? searchQuery,
  }) {
    return _buildLoadedState(
      baseState.copyWith(searchQuery: searchQuery),
    );
  }

  String _teamRegularizeCacheKey(
    RequestAudienceScope scope,
    RegularizeStatus? status,
  ) => '${scope.name}:${status?.name ?? 'all'}';

  RegularizeRequestLoaded? getCachedTeamRegularizeRequests({
    required RequestAudienceScope scope,
    required RegularizeStatus? status,
  }) {
    return _teamRegularizeRequestsCache[_teamRegularizeCacheKey(scope, status)];
  }

  RegularizeRequestLoaded buildTeamRegularizeViewState({
    required RegularizeRequestLoaded baseState,
    String? searchQuery,
  }) {
    return _buildLoadedState(
      baseState.copyWith(searchQuery: searchQuery),
    );
  }

  int _countForStatus(
    RegularizeStatus? status,
    RegularizeRequestLoaded state,
  ) {
    switch (status) {
      case RegularizeStatus.pending:
        return state.pendingCount;
      case RegularizeStatus.approved:
        return state.approvedCount;
      case RegularizeStatus.rejected:
        return state.rejectedCount;
      case RegularizeStatus.withdrawn:
        return state.withdrawnCount;
      case null:
        return state.totalCount;
    }
  }

  bool _hasMoreForStatus({
    required int loadedCount,
    required int pageSize,
    required RegularizeStatus? status,
    required RegularizeRequestLoaded state,
  }) {
    final totalForStatus = _countForStatus(status, state);
    if (totalForStatus > 0) {
      return loadedCount < totalForStatus;
    }

    return loadedCount >= pageSize;
  }

  Future<Map<String, int>?> _fetchRegularizeStats(
    ApiClient apiClient, {
    required String requestType,
    int? clientId,
  }) async {
    final Map<String, dynamic> rawPayload;
    if (clientId == null) {
      rawPayload = {'request_type': requestType};
    } else {
      rawPayload = {
        'client_id': clientId,
        'users': <dynamic>[],
        'status': <dynamic>[],
        'date': '',
        'approved_by': <dynamic>[],
        'rejected_by': <dynamic>[],
        'request_type': requestType,
      };
    }

    final payload = encodeData(rawPayload);

    try {
      final response = await apiClient.get(
        '${AppUrls.regularizeRequestStats}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        return null;
      }

      final stats = data['data'] as Map<String, dynamic>? ?? const {};
      return {
        'total': (stats['total'] as num?)?.toInt() ?? 0,
        'approved': (stats['approved'] as num?)?.toInt() ?? 0,
        'rejected': (stats['rejected'] as num?)?.toInt() ?? 0,
        'pending': (stats['pending'] as num?)?.toInt() ?? 0,
        'withdrawn': (stats['withdrawn'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return null;
    }
  }
}
