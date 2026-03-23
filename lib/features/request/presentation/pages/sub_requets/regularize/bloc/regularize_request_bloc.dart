import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
      'request_type': event.requestType,
      'page': event.page,
      'limit': event.limit,
    });

    await _loadRegularizeRequests(
      emit,
      endpoint: '${AppUrls.regularizeTeamList}?payload=$payload',
    );
  }

  Future<void> _loadRegularizeRequests(
    Emitter<RegularizeRequestState> emit, {
    required String endpoint,
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
}
