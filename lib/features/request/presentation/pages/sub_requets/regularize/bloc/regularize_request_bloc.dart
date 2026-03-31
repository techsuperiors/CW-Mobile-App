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
  RegularizeRequestBloc() : super(const RegularizeRequestInitial()) {
    on<LoadRegularizeRequests>(_onLoadRegularizeRequests);
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
    await _loadRegularizeRequests(
      emit,
      endpoint: AppUrls.regularizeList,
    );
  }

  Future<void> _onLoadTeamRegularizeRequests(
    LoadTeamRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) async {
    final payload = encodeData({
      'request_type': event.scope.attendanceRequestType,
      'page': event.page,
      'limit': event.limit,
    });

    await _loadRegularizeRequests(
      emit,
      endpoint: '${AppUrls.regularizeTeamList}?payload=$payload',
      clientId: event.clientId,
      statsRequestType: event.scope.attendanceRequestType,
      selectedScope: event.scope,
      currentPage: event.page,
      limit: event.limit,
    );
  }

  Future<void> _onLoadMoreTeamRegularizeRequests(
    LoadMoreTeamRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) async {
    if (state is! RegularizeRequestLoaded) return;

    final currentState = state as RegularizeRequestLoaded;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

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
        emit(currentState.copyWith(isLoadingMore: false));
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

      final merged = _mergeUniqueById(
        currentState.regularizeRequests,
        incoming,
      );

      emit(
        _buildLoadedState(
          currentState.copyWith(
            regularizeRequests: merged,
            filteredRegularizeRequests: merged,
            isLoadingMore: false,
            currentPage: currentState.currentPage + 1,
            hasMore:
                incoming.length == event.limit &&
                merged.length > currentState.regularizeRequests.length,
          ),
        ),
      );
    } on ServerException {
      emit(currentState.copyWith(isLoadingMore: false));
    } catch (_) {
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _loadRegularizeRequests(
    Emitter<RegularizeRequestState> emit, {
    required String endpoint,
    int? clientId,
    String? statsRequestType,
    RequestAudienceScope selectedScope = RequestAudienceScope.allUsers,
    int currentPage = 1,
    int? limit,
  }) async {
    emit(const RegularizeRequestLoading());

    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);

      if (!await networkInfo.isConnected) {
        emit(const RegularizeRequestError('No internet connection'));
        return;
      }

      final stats =
          clientId != null
              ? await _fetchRegularizeStats(
                apiClient,
                clientId: clientId,
                requestType: statsRequestType ?? '',
              )
              : null;

      final response = await apiClient.get(
        endpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        emit(
          RegularizeRequestError(
            data['message'] as String? ?? 'Failed to load regularize requests',
          ),
        );
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

      emit(
        RegularizeRequestLoaded(
          regularizeRequests: regularizeRequests,
          filteredRegularizeRequests: regularizeRequests,
          selectedScope: selectedScope,
          currentPage: currentPage,
          hasMore: limit != null && regularizeRequests.length == limit,
          totalCount: stats?['total'] ?? 0,
          pendingCount: stats?['pending'] ?? 0,
          approvedCount: stats?['approved'] ?? 0,
          rejectedCount: stats?['rejected'] ?? 0,
          withdrawnCount: stats?['withdrawn'] ?? 0,
        ),
      );
    } on ServerException catch (e) {
      emit(RegularizeRequestError(e.message));
    } catch (e) {
      emit(RegularizeRequestError('Failed to load regularize requests'));
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

  Future<Map<String, int>?> _fetchRegularizeStats(
    ApiClient apiClient, {
    required int clientId,
    required String requestType,
  }) async {
    final payload = encodeData({
      'client_id': clientId,
      'users': <dynamic>[],
      'status': <dynamic>[],
      'date': '',
      'approved_by': <dynamic>[],
      'rejected_by': <dynamic>[],
      'request_type': requestType,
    });

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
