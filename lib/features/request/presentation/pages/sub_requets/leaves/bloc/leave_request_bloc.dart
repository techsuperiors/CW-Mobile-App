import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/leave_requests_data.dart';
import '../models/leave_request_model.dart';
import 'leave_request_event.dart';
import 'leave_request_state.dart';

/// Leave request BLoC
class LeaveRequestBloc extends Bloc<LeaveRequestEvent, LeaveRequestState> {
  LeaveRequestBloc() : super(const LeaveRequestInitial()) {
    on<LoadLeaveRequests>(_onLoadLeaveRequests);
    on<SearchLeaveRequests>(_onSearchLeaveRequests);
    on<FilterLeaveRequestsByStatus>(_onFilterLeaveRequestsByStatus);
    on<FilterLeaveRequestsByType>(_onFilterLeaveRequestsByType);
    on<ClearFilters>(_onClearFilters);
  }

  void _onLoadLeaveRequests(
    LoadLeaveRequests event,
    Emitter<LeaveRequestState> emit,
  ) {
    emit(const LeaveRequestLoading());
    
    try {
      final leaveRequests = LeaveRequestsData.getLeaveRequests();
      emit(LeaveRequestLoaded(
        leaveRequests: leaveRequests,
        filteredLeaveRequests: leaveRequests,
      ));
    } catch (e) {
      emit(LeaveRequestError(e.toString()));
    }
  }

  void _onSearchLeaveRequests(
    SearchLeaveRequests event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      final query = event.query.trim();

      if (query.isEmpty) {
        // If search is cleared, apply only status/type filters
        final filtered = _applyFilters(
          currentState.leaveRequests,
          currentState.statusFilter,
          currentState.typeFilter,
        );
        emit(currentState.copyWith(
          filteredLeaveRequests: filtered,
          searchQuery: null,
        ));
      } else {
        // Apply search and existing filters
        final searched = LeaveRequestsData.searchLeaveRequests(query);
        final filtered = _applyFilters(
          searched,
          currentState.statusFilter,
          currentState.typeFilter,
        );
        emit(currentState.copyWith(
          filteredLeaveRequests: filtered,
          searchQuery: query,
        ));
      }
    }
  }

  void _onFilterLeaveRequestsByStatus(
    FilterLeaveRequestsByStatus event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      final filtered = _applyFilters(
        currentState.searchQuery != null
            ? LeaveRequestsData.searchLeaveRequests(currentState.searchQuery!)
            : currentState.leaveRequests,
        event.status,
        currentState.typeFilter,
      );
      emit(currentState.copyWith(
        filteredLeaveRequests: filtered,
        statusFilter: event.status,
      ));
    }
  }

  void _onFilterLeaveRequestsByType(
    FilterLeaveRequestsByType event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      final filtered = _applyFilters(
        currentState.searchQuery != null
            ? LeaveRequestsData.searchLeaveRequests(currentState.searchQuery!)
            : currentState.leaveRequests,
        currentState.statusFilter,
        event.leaveType,
      );
      emit(currentState.copyWith(
        filteredLeaveRequests: filtered,
        typeFilter: event.leaveType,
      ));
    }
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<LeaveRequestState> emit,
  ) {
    if (state is LeaveRequestLoaded) {
      final currentState = state as LeaveRequestLoaded;
      final filtered = currentState.searchQuery != null
          ? LeaveRequestsData.searchLeaveRequests(currentState.searchQuery!)
          : currentState.leaveRequests;
      emit(currentState.copyWith(
        filteredLeaveRequests: filtered,
        statusFilter: null,
        typeFilter: null,
      ));
    }
  }

  List<LeaveRequestModel> _applyFilters(
    List<LeaveRequestModel> requests,
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
