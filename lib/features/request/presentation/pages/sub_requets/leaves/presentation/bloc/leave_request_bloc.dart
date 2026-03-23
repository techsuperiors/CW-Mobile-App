import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collectivWork/core/usecase/usecase.dart';
import '../../domain/entities/leave_entity.dart';
import '../../domain/entities/apply_leave_entity.dart';
import '../../domain/usecases/get_leaves_usecase.dart';
import '../../domain/usecases/get_team_leave_requests_usecase.dart';
import '../../domain/usecases/apply_leave_usecase.dart';
import 'leave_request_event.dart';
import 'leave_request_state.dart';

/// Leave request BLoC — fetches leave requests using GetLeavesUseCase.
class LeaveRequestBloc extends Bloc<LeaveRequestEvent, LeaveRequestState> {
  final GetLeavesUseCase getLeavesUseCase;
  final GetTeamLeaveRequestsUseCase? getTeamLeaveRequestsUseCase;
  final ApplyLeaveUseCase applyLeaveUseCase;

  LeaveRequestBloc({
    required this.getLeavesUseCase,
    this.getTeamLeaveRequestsUseCase,
    required this.applyLeaveUseCase,
  }) : super(const LeaveRequestInitial()) {
    on<LoadLeaveRequests>(_onLoadLeaveRequests);
    on<LoadTeamLeaveRequests>(_onLoadTeamLeaveRequests);
    on<SearchLeaveRequests>(_onSearchLeaveRequests);
    on<FilterLeaveRequestsByStatus>(_onFilterLeaveRequestsByStatus);
    on<FilterLeaveRequestsByType>(_onFilterLeaveRequestsByType);
    on<ClearFilters>(_onClearFilters);
    on<ApplyLeave>(_onApplyLeave);
  }

  Future<void> _onLoadTeamLeaveRequests(
    LoadTeamLeaveRequests event,
    Emitter<LeaveRequestState> emit,
  ) async {
    final teamUseCase = getTeamLeaveRequestsUseCase;
    if (teamUseCase == null) {
      emit(const LeaveRequestError('Team leave requests are not configured'));
      return;
    }

    emit(const LeaveRequestLoading());

    final failureOrLeaves = await teamUseCase(
      GetTeamLeaveRequestsParams(
        clientId: event.clientId,
        page: event.page,
        limit: event.limit,
      ),
    );

    failureOrLeaves.fold(
      (failure) => emit(LeaveRequestError(failure.message)),
      (leaveRequests) => emit(
        LeaveRequestLoaded(
          leaveRequests: leaveRequests,
          filteredLeaveRequests: leaveRequests,
        ),
      ),
    );
  }

  /// Load leave requests from UseCase.
  Future<void> _onLoadLeaveRequests(
    LoadLeaveRequests event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(const LeaveRequestLoading());

    final failureOrLeaves = await getLeavesUseCase(NoParams());

    failureOrLeaves.fold(
      (failure) => emit(LeaveRequestError(failure.message)),
      (leaveRequests) => emit(
        LeaveRequestLoaded(
          leaveRequests: leaveRequests,
          filteredLeaveRequests: leaveRequests,
        ),
      ),
    );
  }

  /// Handle ApplyLeave event.
  Future<void> _onApplyLeave(
    ApplyLeave event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(const LeaveRequestApplying());

    final requestEntity = ApplyLeaveRequestEntity(
      leaveType: event.leaveType,
      clubing: event.clubing,
      isClubbing: event.isClubbing,
      startDate: event.startDate,
      endDate: event.endDate,
      subject: event.subject,
      reason: event.reason,
      startHalf: event.startHalf,
      endHalf: event.endHalf,
      dayType: event.dayType,
      description: event.description,
      shortCode: event.shortCode,
      requestTo: event.requestTo,
      rHDates: event.rHDates,
    );

    final failureOrSuccess = await applyLeaveUseCase(requestEntity);

    failureOrSuccess.fold(
      (failure) => emit(LeaveRequestError(failure.message)),
      (result) => emit(LeaveRequestApplied(result: result)),
    );
  }

  /// Search through already-loaded leave requests locally.
  void _onSearchLeaveRequests(
    SearchLeaveRequests event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      final query = event.query.trim().toLowerCase();

      if (query.isEmpty) {
        // If search is cleared, apply only status/type filters
        final filtered = _applyFilters(
          currentState.leaveRequests,
          currentState.statusFilter,
          currentState.typeFilter,
        );
        emit(
          currentState.copyWith(
            filteredLeaveRequests: filtered,
            searchQuery: null,
          ),
        );
      } else {
        // Search in loaded data, then apply filters
        final searched =
            currentState.leaveRequests
                .where(
                  (request) =>
                      request.reason.toLowerCase().contains(query) ||
                      request.leaveType.toLowerCase().contains(query) ||
                      (request.subject?.toLowerCase().contains(query) ?? false),
                )
                .toList();
        final filtered = _applyFilters(
          searched,
          currentState.statusFilter,
          currentState.typeFilter,
        );
        emit(
          currentState.copyWith(
            filteredLeaveRequests: filtered,
            searchQuery: query,
          ),
        );
      }
    }
  }

  void _onFilterLeaveRequestsByStatus(
    FilterLeaveRequestsByStatus event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      final baseList =
          currentState.searchQuery != null
              ? currentState.leaveRequests
                  .where(
                    (r) =>
                        r.reason.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        r.leaveType.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        (r.subject?.toLowerCase().contains(
                              currentState.searchQuery!,
                            ) ??
                            false),
                  )
                  .toList()
              : currentState.leaveRequests;
      final filtered = _applyFilters(
        baseList,
        event.status,
        currentState.typeFilter,
      );
      emit(
        currentState.copyWith(
          filteredLeaveRequests: filtered,
          statusFilter: event.status,
        ),
      );
    }
  }

  void _onFilterLeaveRequestsByType(
    FilterLeaveRequestsByType event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      final baseList =
          currentState.searchQuery != null
              ? currentState.leaveRequests
                  .where(
                    (r) =>
                        r.reason.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        r.leaveType.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        (r.subject?.toLowerCase().contains(
                              currentState.searchQuery!,
                            ) ??
                            false),
                  )
                  .toList()
              : currentState.leaveRequests;
      final filtered = _applyFilters(
        baseList,
        currentState.statusFilter,
        event.leaveType,
      );
      emit(
        currentState.copyWith(
          filteredLeaveRequests: filtered,
          typeFilter: event.leaveType,
        ),
      );
    }
  }

  void _onClearFilters(ClearFilters event, Emitter<LeaveRequestState> emit) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      final filtered =
          currentState.searchQuery != null
              ? currentState.leaveRequests
                  .where(
                    (r) =>
                        r.reason.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        r.leaveType.toLowerCase().contains(
                          currentState.searchQuery!,
                        ) ||
                        (r.subject?.toLowerCase().contains(
                              currentState.searchQuery!,
                            ) ??
                            false),
                  )
                  .toList()
              : currentState.leaveRequests;
      emit(
        currentState.copyWith(
          filteredLeaveRequests: filtered,
          statusFilter: null,
          typeFilter: null,
        ),
      );
    }
  }

  List<LeaveEntity> _applyFilters(
    List<LeaveEntity> requests,
    LeaveStatus? statusFilter,
    String? typeFilter,
  ) {
    var filtered = requests;

    if (statusFilter != null) {
      filtered = filtered.where((r) => r.status == statusFilter).toList();
    }

    if (typeFilter != null) {
      filtered = filtered.where((r) => r.leaveType == typeFilter).toList();
    }

    return filtered;
  }
}
