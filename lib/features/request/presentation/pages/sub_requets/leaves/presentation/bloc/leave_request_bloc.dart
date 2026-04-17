import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collectivWork/core/usecase/usecase.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
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
  final Map<String, LeaveRequestLoaded> _teamLeaveRequestsCache = {};
  int _latestTeamRequestSequence = 0;
  String? _activeTeamRequestKey;

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

    final previousLoadedState =
        state is LeaveRequestLoaded && (state as LeaveRequestLoaded).isTeamRequestMode
            ? state as LeaveRequestLoaded
            : null;

    if (event.forceRefresh && event.page == 1) {
      _teamLeaveRequestsCache.clear();
    }

    final cacheKey = _teamLeaveCacheKey(event.scope, event.status);
    final requestSequence = ++_latestTeamRequestSequence;
    _activeTeamRequestKey = cacheKey;
    final cachedState = _teamLeaveRequestsCache[cacheKey];

    if (event.page == 1 && !event.forceRefresh && cachedState != null) {
      emit(
        _buildLoadedState(
          cachedState.copyWith(
            searchQuery: previousLoadedState?.searchQuery,
            typeFilter: previousLoadedState?.typeFilter,
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
      emit(const LeaveRequestLoading());
    }

    final failureOrLeaves = await teamUseCase(
      GetTeamLeaveRequestsParams(
        clientId: event.clientId,
        scope: event.scope,
        status: event.status,
        page: event.page,
        limit: event.limit,
      ),
    );

    failureOrLeaves.fold(
      (failure) {
        if (requestSequence != _latestTeamRequestSequence ||
            _activeTeamRequestKey != cacheKey) {
          return;
        }

        if (previousLoadedState != null) {
          emit(
            previousLoadedState.copyWith(
              leaveRequests: const [],
              filteredLeaveRequests: const [],
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

        emit(LeaveRequestError(failure.message));
      },
      (pageData) {
        if (requestSequence != _latestTeamRequestSequence ||
            _activeTeamRequestKey != cacheKey) {
          return;
        }

        final loadedState = LeaveRequestLoaded(
          leaveRequests: pageData.requests,
          filteredLeaveRequests: pageData.requests,
          isTeamRequestMode: true,
          statusFilter: event.status,
          isRefreshing: false,
          hasMore: pageData.requests.length < pageData.totalLeaveRequest,
          currentPage: event.page,
          totalLeaveRequest: pageData.totalLeaveRequest,
          approvedListCount: pageData.approvedListCount,
          pendingListCount: pageData.pendingListCount,
          rejectListCount: pageData.rejectListCount,
          selectedScope: event.scope,
        );

        _teamLeaveRequestsCache[cacheKey] = loadedState;
        emit(loadedState);
      },
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
    final requestKey = _teamLeaveCacheKey(
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

    final failureOrLeaves = await teamUseCase(
      GetTeamLeaveRequestsParams(
        clientId: event.clientId,
        scope: currentState.selectedScope,
        status: currentState.statusFilter,
        page: currentState.currentPage + 1,
        limit: event.limit,
      ),
    );

    failureOrLeaves.fold(
      (_) {
        if (_activeTeamRequestKey != requestKey || state is! LeaveRequestLoaded) {
          return;
        }

        final latestState = state as LeaveRequestLoaded;
        emit(latestState.copyWith(isLoadingMore: false));
      },
      (pageData) {
        if (_activeTeamRequestKey != requestKey || state is! LeaveRequestLoaded) {
          return;
        }

        final latestState = state as LeaveRequestLoaded;
        final merged = _mergeUniqueById(
          latestState.leaveRequests,
          pageData.requests,
        );

        final nextState = _buildLoadedState(
          latestState.copyWith(
            leaveRequests: merged,
            isLoadingMore: false,
            hasMore: merged.length < pageData.totalLeaveRequest,
            currentPage: latestState.currentPage + 1,
            totalLeaveRequest: pageData.totalLeaveRequest,
            approvedListCount: pageData.approvedListCount,
            pendingListCount: pageData.pendingListCount,
            rejectListCount: pageData.rejectListCount,
          ),
        );

        emit(nextState);
        _teamLeaveRequestsCache[requestKey] = nextState;
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

  LeaveRequestLoaded buildTeamLeaveViewState({
    required LeaveRequestLoaded baseState,
    String? searchQuery,
    String? typeFilter,
  }) {
    return _buildLoadedState(
      baseState.copyWith(
        searchQuery: searchQuery,
        typeFilter: typeFilter,
      ),
    );
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

  String _teamLeaveCacheKey(
    RequestAudienceScope scope,
    LeaveStatus? status,
  ) => '${scope.name}:${status?.name ?? 'all'}';

  LeaveRequestLoaded? getCachedTeamLeaveRequests({
    required RequestAudienceScope scope,
    required LeaveStatus? status,
  }) {
    return _teamLeaveRequestsCache[_teamLeaveCacheKey(scope, status)];
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
