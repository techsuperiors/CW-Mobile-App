import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecases/get_wfh_requests.dart';
import '../domain/usecases/get_team_wfh_requests.dart';
import '../models/wfh_request_model.dart';
import 'wfh_request_event.dart';
import 'wfh_request_state.dart';

/// WFH request BLoC — fetches WFH requests from API.
class WfhRequestBloc extends Bloc<WfhRequestEvent, WfhRequestState> {
  final GetWfhRequestsUseCase getWfhRequestsUseCase;
  final GetTeamWfhRequestsUseCase? getTeamWfhRequestsUseCase;

  WfhRequestBloc({
    required this.getWfhRequestsUseCase,
    this.getTeamWfhRequestsUseCase,
  })
    : super(const WfhRequestInitial()) {
    on<LoadWfhRequests>(_onLoadWfhRequests);
    on<LoadTeamWfhRequests>(_onLoadTeamWfhRequests);
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

    final result = await getWfhRequestsUseCase();
    result.fold(
      (failure) => emit(WfhRequestError(failure.message)),
      (wfhRequests) => emit(
        WfhRequestLoaded(
          wfhRequests: wfhRequests,
          filteredWfhRequests: wfhRequests,
        ),
      ),
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
        requestType: event.requestType,
      ),
    );
    result.fold(
      (failure) => emit(WfhRequestError(failure.message)),
      (wfhRequests) => emit(
        WfhRequestLoaded(
          wfhRequests: wfhRequests,
          filteredWfhRequests: wfhRequests,
        ),
      ),
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
        final filtered = _applyFilters(
          currentState.wfhRequests,
          currentState.statusFilter,
        );
        emit(
          currentState.copyWith(
            filteredWfhRequests: filtered,
            searchQuery: null,
          ),
        );
      } else {
        final searched =
            currentState.wfhRequests
                .where(
                  (request) =>
                      request.reason.toLowerCase().contains(query) ||
                      (request.subject?.toLowerCase().contains(query) ?? false),
                )
                .toList();
        final filtered = _applyFilters(searched, currentState.statusFilter);
        emit(
          currentState.copyWith(
            filteredWfhRequests: filtered,
            searchQuery: query,
          ),
        );
      }
    }
  }

  void _onFilterWfhRequestsByStatus(
    FilterWfhRequestsByStatus event,
    Emitter<WfhRequestState> emit,
  ) {
    if (state is WfhRequestLoaded) {
      final currentState = state as WfhRequestLoaded;
      final baseList =
          currentState.searchQuery != null
              ? currentState.wfhRequests
                  .where(
                    (r) =>
                        r.reason.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        (r.subject?.toLowerCase().contains(
                              currentState.searchQuery!,
                            ) ??
                            false),
                  )
                  .toList()
              : currentState.wfhRequests;
      final filtered = _applyFilters(baseList, event.status);
      emit(
        currentState.copyWith(
          filteredWfhRequests: filtered,
          statusFilter: event.status,
        ),
      );
    }
  }

  void _onClearFilters(ClearFilters event, Emitter<WfhRequestState> emit) {
    if (state is WfhRequestLoaded) {
      final currentState = state as WfhRequestLoaded;
      final filtered =
          currentState.searchQuery != null
              ? currentState.wfhRequests
                  .where(
                    (r) =>
                        r.reason.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        (r.subject?.toLowerCase().contains(
                              currentState.searchQuery!,
                            ) ??
                            false),
                  )
                  .toList()
              : currentState.wfhRequests;
      emit(
        currentState.copyWith(
          filteredWfhRequests: filtered,
          statusFilter: null,
        ),
      );
    }
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
