import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collectivWork/core/usecase/usecase.dart';
import '../../domain/entities/leave_entity.dart';
import '../../domain/entities/apply_leave_entity.dart';
import '../../domain/usecases/apply_leave_usecase.dart';
import '../../domain/usecases/get_leaves_usecase.dart';
import '../../domain/usecases/get_team_leave_requests_usecase.dart';
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
    on<LoadMoreTeamLeaveRequests>(_onLoadMoreTeamLeaveRequests);
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
        scope: event.scope,
        page: event.page,
        limit: event.limit,
      ),
    );

    failureOrLeaves.fold(
      (failure) => emit(LeaveRequestError(failure.message)),
      (pageData) => emit(
        LeaveRequestLoaded(
          leaveRequests: pageData.requests,
          filteredLeaveRequests: pageData.requests,
          isTeamRequestMode: true,
          hasMore: pageData.requests.length < pageData.totalLeaveRequest,
          currentPage: event.page,
          totalLeaveRequest: pageData.totalLeaveRequest,
          approvedListCount: pageData.approvedListCount,
          pendingListCount: pageData.pendingListCount,
          rejectListCount: pageData.rejectListCount,
          selectedScope: event.scope,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreTeamLeaveRequests(
    LoadMoreTeamLeaveRequests event,
    Emitter<LeaveRequestState> emit,
  ) async {
    final teamUseCase = getTeamLeaveRequestsUseCase;
    if (teamUseCase == null || state is! LeaveRequestLoaded) {
      return;
    }

    final currentState = state as LeaveRequestLoaded;
    if (!currentState.isTeamRequestMode ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final failureOrLeaves = await teamUseCase(
      GetTeamLeaveRequestsParams(
        clientId: event.clientId,
        scope: currentState.selectedScope,
        page: currentState.currentPage + 1,
        limit: event.limit,
      ),
    );

    failureOrLeaves.fold(
      (_) => emit(currentState.copyWith(isLoadingMore: false)),
      (pageData) {
        final merged = _mergeUniqueById(
          currentState.leaveRequests,
          pageData.requests,
        );

        emit(
          _buildLoadedState(
            currentState.copyWith(
              leaveRequests: merged,
              isLoadingMore: false,
              hasMore: merged.length < pageData.totalLeaveRequest,
              currentPage: currentState.currentPage + 1,
              totalLeaveRequest: pageData.totalLeaveRequest,
              approvedListCount: pageData.approvedListCount,
              pendingListCount: pageData.pendingListCount,
              rejectListCount: pageData.rejectListCount,
            ),
          ),
        );
      },
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
        emit(_buildLoadedState(currentState.copyWith(searchQuery: null)));
      } else {
        emit(_buildLoadedState(currentState.copyWith(searchQuery: query)));
      }
    }
  }

  void _onFilterLeaveRequestsByStatus(
    FilterLeaveRequestsByStatus event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      emit(_buildLoadedState(currentState.copyWith(statusFilter: event.status)));
    }
  }

  void _onFilterLeaveRequestsByType(
    FilterLeaveRequestsByType event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      emit(_buildLoadedState(currentState.copyWith(typeFilter: event.leaveType)));
    }
  }

  void _onClearFilters(ClearFilters event, Emitter<LeaveRequestState> emit) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      emit(
        _buildLoadedState(
          currentState.copyWith(statusFilter: null, typeFilter: null),
        ),
      );
    }
  }

  LeaveRequestLoaded _buildLoadedState(LeaveRequestLoaded state) {
    final searchedList = _applySearch(state.leaveRequests, state.searchQuery);
    final filtered = _applyFilters(
      searchedList,
      state.statusFilter,
      state.typeFilter,
    );

    return state.copyWith(filteredLeaveRequests: filtered);
  }

  List<LeaveEntity> _applySearch(List<LeaveEntity> requests, String? query) {
    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery == null || normalizedQuery.isEmpty) {
      return requests;
    }

    return requests
        .where(
          (request) =>
              request.reason.toLowerCase().contains(normalizedQuery) ||
              request.leaveType.toLowerCase().contains(normalizedQuery) ||
              (request.subject?.toLowerCase().contains(normalizedQuery) ??
                  false),
        )
        .toList();
  }

  List<LeaveEntity> _mergeUniqueById(
    List<LeaveEntity> existing,
    List<LeaveEntity> incoming,
  ) {
    final merged = <LeaveEntity>[...existing];
    final seenIds = existing.map((item) => item.id).toSet();

    for (final item in incoming) {
      if (seenIds.add(item.id)) {
        merged.add(item);
      }
    }

    return merged;
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
