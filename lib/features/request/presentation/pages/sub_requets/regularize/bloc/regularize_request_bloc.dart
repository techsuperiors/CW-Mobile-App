import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/regularize_requests_data.dart';
import '../models/regularize_request_model.dart';
import 'regularize_request_event.dart';
import 'regularize_request_state.dart';

/// Regularize request BLoC
class RegularizeRequestBloc extends Bloc<RegularizeRequestEvent, RegularizeRequestState> {
  RegularizeRequestBloc() : super(const RegularizeRequestInitial()) {
    on<LoadRegularizeRequests>(_onLoadRegularizeRequests);
    on<SearchRegularizeRequests>(_onSearchRegularizeRequests);
    on<FilterRegularizeRequestsByStatus>(_onFilterRegularizeRequestsByStatus);
    on<ClearFilters>(_onClearFilters);
  }

  void _onLoadRegularizeRequests(
    LoadRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) {
    emit(const RegularizeRequestLoading());
    
    try {
      final regularizeRequests = RegularizeRequestsData.getRegularizeRequests();
      emit(RegularizeRequestLoaded(
        regularizeRequests: regularizeRequests,
        filteredRegularizeRequests: regularizeRequests,
      ));
    } catch (e) {
      emit(RegularizeRequestError(e.toString()));
    }
  }

  void _onSearchRegularizeRequests(
    SearchRegularizeRequests event,
    Emitter<RegularizeRequestState> emit,
  ) {
    if (state is RegularizeRequestLoaded) {
      final currentState = state as RegularizeRequestLoaded;
      final query = event.query.trim();

      if (query.isEmpty) {
        // If search is cleared, apply only status filter
        final filtered = _applyFilters(
          currentState.regularizeRequests,
          currentState.statusFilter,
        );
        emit(currentState.copyWith(
          filteredRegularizeRequests: filtered,
          searchQuery: null,
        ));
      } else {
        // Apply search and existing filters
        final searched = RegularizeRequestsData.searchRegularizeRequests(query);
        final filtered = _applyFilters(
          searched,
          currentState.statusFilter,
        );
        emit(currentState.copyWith(
          filteredRegularizeRequests: filtered,
          searchQuery: query,
        ));
      }
    }
  }

  void _onFilterRegularizeRequestsByStatus(
    FilterRegularizeRequestsByStatus event,
    Emitter<RegularizeRequestState> emit,
  ) {
    if (state is RegularizeRequestLoaded) {
      final currentState = state as RegularizeRequestLoaded;
      final filtered = _applyFilters(
        currentState.searchQuery != null
            ? RegularizeRequestsData.searchRegularizeRequests(currentState.searchQuery!)
            : currentState.regularizeRequests,
        event.status,
      );
      emit(currentState.copyWith(
        filteredRegularizeRequests: filtered,
        statusFilter: event.status,
      ));
    }
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<RegularizeRequestState> emit,
  ) {
    if (state is RegularizeRequestLoaded) {
      final currentState = state as RegularizeRequestLoaded;
      final filtered = currentState.searchQuery != null
          ? RegularizeRequestsData.searchRegularizeRequests(currentState.searchQuery!)
          : currentState.regularizeRequests;
      emit(currentState.copyWith(
        filteredRegularizeRequests: filtered,
        statusFilter: null,
      ));
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

    return filtered;
  }
}
