import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/on_duty_request_model.dart';
import '../domain/usecases/get_on_duty_requests.dart';
import '../domain/usecases/get_team_on_duty_requests.dart';
import 'on_duty_request_event.dart';
import 'on_duty_request_state.dart';

/// On-Duty request BLoC — fetches On-Duty requests from API.
class OnDutyRequestBloc extends Bloc<OnDutyRequestEvent, OnDutyRequestState> {
  final GetOnDutyRequestsUseCase getOnDutyRequestsUseCase;
  final GetTeamOnDutyRequestsUseCase? getTeamOnDutyRequestsUseCase;

  OnDutyRequestBloc({
    required this.getOnDutyRequestsUseCase,
    this.getTeamOnDutyRequestsUseCase,
  })
      : super(const OnDutyRequestInitial()) {
    on<LoadOnDutyRequests>(_onLoadOnDutyRequests);
    on<LoadTeamOnDutyRequests>(_onLoadTeamOnDutyRequests);
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
        page: event.page,
        limit: event.limit,
        requestType: event.requestType,
      ),
    );
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

  /// Search through already-loaded requests locally.
  void _onSearchOnDutyRequests(
    SearchOnDutyRequests event,
    Emitter<OnDutyRequestState> emit,
  ) {
    if (state is OnDutyRequestLoaded) {
      final currentState = state as OnDutyRequestLoaded;
      final query = event.query.trim().toLowerCase();

      if (query.isEmpty) {
        final filtered = _applyFilters(
          currentState.onDutyRequests,
          currentState.statusFilter,
        );
        emit(
          currentState.copyWith(
            filteredOnDutyRequests: filtered,
            searchQuery: null,
          ),
        );
      } else {
        final searched =
            currentState.onDutyRequests
                .where(
                  (request) =>
                      request.reason.toLowerCase().contains(query) ||
                      (request.subject?.toLowerCase().contains(query) ?? false),
                )
                .toList();
        final filtered = _applyFilters(searched, currentState.statusFilter);
        emit(
          currentState.copyWith(
            filteredOnDutyRequests: filtered,
            searchQuery: query,
          ),
        );
      }
    }
  }

  void _onFilterOnDutyRequestsByStatus(
    FilterOnDutyRequestsByStatus event,
    Emitter<OnDutyRequestState> emit,
  ) {
    if (state is OnDutyRequestLoaded) {
      final currentState = state as OnDutyRequestLoaded;
      final baseList =
          currentState.searchQuery != null
              ? currentState.onDutyRequests
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
              : currentState.onDutyRequests;
      final filtered = _applyFilters(baseList, event.status);
      emit(
        currentState.copyWith(
          filteredOnDutyRequests: filtered,
          statusFilter: event.status,
        ),
      );
    }
  }

  void _onClearFilters(
    ClearOnDutyFilters event,
    Emitter<OnDutyRequestState> emit,
  ) {
    if (state is OnDutyRequestLoaded) {
      final currentState = state as OnDutyRequestLoaded;
      final filtered =
          currentState.searchQuery != null
              ? currentState.onDutyRequests
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
              : currentState.onDutyRequests;
      emit(
        currentState.copyWith(
          filteredOnDutyRequests: filtered,
          statusFilter: null,
        ),
      );
    }
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
}
