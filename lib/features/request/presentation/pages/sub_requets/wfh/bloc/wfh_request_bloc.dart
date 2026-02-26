import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/wfh_requests_data.dart';
import '../models/wfh_request_model.dart';
import 'wfh_request_event.dart';
import 'wfh_request_state.dart';

/// WFH request BLoC
class WfhRequestBloc extends Bloc<WfhRequestEvent, WfhRequestState> {
  WfhRequestBloc() : super(const WfhRequestInitial()) {
    on<LoadWfhRequests>(_onLoadWfhRequests);
    on<SearchWfhRequests>(_onSearchWfhRequests);
    on<FilterWfhRequestsByStatus>(_onFilterWfhRequestsByStatus);
    on<ClearFilters>(_onClearFilters);
  }

  void _onLoadWfhRequests(
    LoadWfhRequests event,
    Emitter<WfhRequestState> emit,
  ) {
    emit(const WfhRequestLoading());
    
    try {
      final wfhRequests = WfhRequestsData.getWfhRequests();
      emit(WfhRequestLoaded(
        wfhRequests: wfhRequests,
        filteredWfhRequests: wfhRequests,
      ));
    } catch (e) {
      emit(WfhRequestError(e.toString()));
    }
  }

  void _onSearchWfhRequests(
    SearchWfhRequests event,
    Emitter<WfhRequestState> emit,
  ) {
    if (state is WfhRequestLoaded) {
      final currentState = state as WfhRequestLoaded;
      final query = event.query.trim();

      if (query.isEmpty) {
        // If search is cleared, apply only status filter
        final filtered = _applyFilters(
          currentState.wfhRequests,
          currentState.statusFilter,
        );
        emit(currentState.copyWith(
          filteredWfhRequests: filtered,
          searchQuery: null,
        ));
      } else {
        // Apply search and existing filters
        final searched = WfhRequestsData.searchWfhRequests(query);
        final filtered = _applyFilters(
          searched,
          currentState.statusFilter,
        );
        emit(currentState.copyWith(
          filteredWfhRequests: filtered,
          searchQuery: query,
        ));
      }
    }
  }

  void _onFilterWfhRequestsByStatus(
    FilterWfhRequestsByStatus event,
    Emitter<WfhRequestState> emit,
  ) {
    if (state is WfhRequestLoaded) {
      final currentState = state as WfhRequestLoaded;
      final filtered = _applyFilters(
        currentState.searchQuery != null
            ? WfhRequestsData.searchWfhRequests(currentState.searchQuery!)
            : currentState.wfhRequests,
        event.status,
      );
      emit(currentState.copyWith(
        filteredWfhRequests: filtered,
        statusFilter: event.status,
      ));
    }
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<WfhRequestState> emit,
  ) {
    if (state is WfhRequestLoaded) {
      final currentState = state as WfhRequestLoaded;
      final filtered = currentState.searchQuery != null
          ? WfhRequestsData.searchWfhRequests(currentState.searchQuery!)
          : currentState.wfhRequests;
      emit(currentState.copyWith(
        filteredWfhRequests: filtered,
        statusFilter: null,
      ));
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
