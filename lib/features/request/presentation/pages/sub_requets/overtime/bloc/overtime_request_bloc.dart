import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/get_overtime_requests.dart';
import '../domain/usecases/get_team_overtime_requests.dart';
import '../models/overtime_request_model.dart';
import 'overtime_request_event.dart';
import 'overtime_request_state.dart';

class OvertimeRequestBloc
    extends Bloc<OvertimeRequestEvent, OvertimeRequestState> {
  final GetOvertimeRequestsUseCase getOvertimeRequestsUseCase;
  final GetTeamOvertimeRequestsUseCase? getTeamOvertimeRequestsUseCase;

  OvertimeRequestBloc({
    required this.getOvertimeRequestsUseCase,
    this.getTeamOvertimeRequestsUseCase,
  })
      : super(const OvertimeRequestInitial()) {
    on<LoadOvertimeRequests>(_onLoadOvertimeRequests);
    on<LoadTeamOvertimeRequests>(_onLoadTeamOvertimeRequests);
    on<SearchOvertimeRequests>(_onSearchOvertimeRequests);
    on<FilterOvertimeRequestsByStatus>(_onFilterOvertimeRequestsByStatus);
  }

  Future<void> _onLoadOvertimeRequests(
    LoadOvertimeRequests event,
    Emitter<OvertimeRequestState> emit,
  ) async {
    emit(const OvertimeRequestLoading());
    final result = await getOvertimeRequestsUseCase();
    result.fold(
      (failure) => emit(OvertimeRequestError(failure.message)),
      (requests) => emit(
        OvertimeRequestLoaded(requests: requests, filteredRequests: requests),
      ),
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

    emit(const OvertimeRequestLoading());
    final result = await teamUseCase(
      page: event.page,
      limit: event.limit,
      requestType: event.requestType,
    );
    result.fold(
      (failure) => emit(OvertimeRequestError(failure.message)),
      (requests) => emit(
        OvertimeRequestLoaded(requests: requests, filteredRequests: requests),
      ),
    );
  }

  void _onSearchOvertimeRequests(
    SearchOvertimeRequests event,
    Emitter<OvertimeRequestState> emit,
  ) {
    if (state is! OvertimeRequestLoaded) return;
    final current = state as OvertimeRequestLoaded;
    final query = event.query.trim().toLowerCase();
    final searched = query.isEmpty
        ? current.requests
        : current.requests
            .where((request) => request.subject.toLowerCase().contains(query))
            .toList();
    emit(
      current.copyWith(
        filteredRequests: _applyFilters(searched, current.statusFilter),
        searchQuery: query.isEmpty ? null : query,
      ),
    );
  }

  void _onFilterOvertimeRequestsByStatus(
    FilterOvertimeRequestsByStatus event,
    Emitter<OvertimeRequestState> emit,
  ) {
    if (state is! OvertimeRequestLoaded) return;
    final current = state as OvertimeRequestLoaded;
    final baseList = current.searchQuery == null
        ? current.requests
        : current.requests
            .where(
              (request) =>
                  request.subject.toLowerCase().contains(current.searchQuery!),
            )
            .toList();
    emit(
      current.copyWith(
        filteredRequests: _applyFilters(baseList, event.status),
        statusFilter: event.status,
      ),
    );
  }

  List<OvertimeRequestModel> _applyFilters(
    List<OvertimeRequestModel> requests,
    OvertimeStatus? statusFilter,
  ) {
    if (statusFilter == null) return requests;
    return requests.where((request) => request.status == statusFilter).toList();
  }
}
