import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_visit_usecase.dart';
import '../../domain/usecases/get_visits_usecase.dart';
import 'visit_event.dart';
import 'visit_state.dart';

class VisitBloc extends Bloc<VisitEvent, VisitState> {
  final GetVisitsUseCase getVisitsUseCase;
  final GetVisitTotalCountUseCase getVisitTotalCountUseCase;
  final GetVisitEmployeesUseCase getVisitEmployeesUseCase;
  final GetVisitCustomersUseCase getVisitCustomersUseCase;
  final GetVisitAddressesUseCase getVisitAddressesUseCase;
  final CreateVisitUseCase createVisitUseCase;
  final CreateVisitActivityUseCase createVisitActivityUseCase;
  final int currentUserId;

  VisitBloc({
    required this.getVisitsUseCase,
    required this.getVisitTotalCountUseCase,
    required this.getVisitEmployeesUseCase,
    required this.getVisitCustomersUseCase,
    required this.getVisitAddressesUseCase,
    required this.createVisitUseCase,
    required this.createVisitActivityUseCase,
    required this.currentUserId,
  }) : super(const VisitState()) {
    on<LoadMyVisits>(_onLoadMyVisits);
    on<LoadTeamVisits>(_onLoadTeamVisits);
    on<LoadVisitEmployees>(_onLoadVisitEmployees);
    on<LoadVisitCustomers>(_onLoadVisitCustomers);
    on<LoadVisitAddresses>(_onLoadVisitAddresses);
    on<CreateVisitRequested>(_onCreateVisitRequested);
    on<CreateVisitActivityRequested>(_onCreateVisitActivityRequested);
    on<ClearVisitFeedback>(_onClearVisitFeedback);
  }

  Future<void> _onLoadMyVisits(
    LoadMyVisits event,
    Emitter<VisitState> emit,
  ) async {
    if (state.isMyVisitsLoading && !event.forceRefresh) return;

    emit(
      state.copyWith(
        isMyVisitsLoading: true,
        myVisitsError: null,
        actionError: null,
        successMessage: null,
      ),
    );

    final visitsResult = await getVisitsUseCase(
      page: 1,
      limit: 10,
      createdBy: currentUserId,
    );
    final countResult = await getVisitTotalCountUseCase(
      page: 1,
      limit: 10,
      createdBy: currentUserId,
    );

    visitsResult.fold(
      (failure) {
        emit(
          state.copyWith(
            isMyVisitsLoading: false,
            myVisitsError: failure.message,
          ),
        );
      },
      (visits) {
        final total = countResult.fold((_) => visits.length, (count) => count);
        emit(
          state.copyWith(
            isMyVisitsLoading: false,
            myVisits: visits,
            myVisitCount: total,
            myVisitsError: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadTeamVisits(
    LoadTeamVisits event,
    Emitter<VisitState> emit,
  ) async {
    if (state.isTeamVisitsLoading && !event.forceRefresh) return;

    emit(
      state.copyWith(
        isTeamVisitsLoading: true,
        teamVisitsError: null,
        actionError: null,
        successMessage: null,
      ),
    );

    final visitsResult = await getVisitsUseCase(page: 1, limit: 10);
    final countResult = await getVisitTotalCountUseCase(page: 1, limit: 10);

    visitsResult.fold(
      (failure) {
        emit(
          state.copyWith(
            isTeamVisitsLoading: false,
            teamVisitsError: failure.message,
          ),
        );
      },
      (visits) {
        final total = countResult.fold((_) => visits.length, (count) => count);
        emit(
          state.copyWith(
            isTeamVisitsLoading: false,
            teamVisits: visits,
            teamVisitCount: total,
            teamVisitsError: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadVisitEmployees(
    LoadVisitEmployees event,
    Emitter<VisitState> emit,
  ) async {
    if (state.isEmployeesLoading) return;
    if (!event.forceRefresh && state.employees.isNotEmpty) return;

    emit(
      state.copyWith(
        isEmployeesLoading: true,
        employeesError: null,
        actionError: null,
        successMessage: null,
      ),
    );

    final result = await getVisitEmployeesUseCase();
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isEmployeesLoading: false,
            employeesError: failure.message,
          ),
        );
      },
      (employees) {
        emit(
          state.copyWith(
            isEmployeesLoading: false,
            employees: employees,
            employeesError: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadVisitCustomers(
    LoadVisitCustomers event,
    Emitter<VisitState> emit,
  ) async {
    if (state.isCustomersLoading) return;
    if (!event.forceRefresh && state.customers.isNotEmpty) return;

    emit(
      state.copyWith(
        isCustomersLoading: true,
        customersError: null,
        actionError: null,
        successMessage: null,
      ),
    );

    final result = await getVisitCustomersUseCase();
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isCustomersLoading: false,
            customersError: failure.message,
          ),
        );
      },
      (customers) {
        emit(
          state.copyWith(
            isCustomersLoading: false,
            customers: customers,
            customersError: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadVisitAddresses(
    LoadVisitAddresses event,
    Emitter<VisitState> emit,
  ) async {
    if (state.isAddressesLoading) return;
    if (!event.forceRefresh && state.addresses.isNotEmpty) return;

    emit(
      state.copyWith(
        isAddressesLoading: true,
        addressesError: null,
        actionError: null,
        successMessage: null,
      ),
    );

    final result = await getVisitAddressesUseCase();
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isAddressesLoading: false,
            addressesError: failure.message,
          ),
        );
      },
      (addresses) {
        emit(
          state.copyWith(
            isAddressesLoading: false,
            addresses: addresses,
            addressesError: null,
          ),
        );
      },
    );
  }

  Future<void> _onCreateVisitRequested(
    CreateVisitRequested event,
    Emitter<VisitState> emit,
  ) async {
    if (state.isCreatingVisit) return;

    emit(
      state.copyWith(
        isCreatingVisit: true,
        actionError: null,
        successMessage: null,
      ),
    );

    final result = await createVisitUseCase(event.params);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(isCreatingVisit: false, actionError: failure.message),
        );
      },
      (message) async {
        emit(
          state.copyWith(
            isCreatingVisit: false,
            successMessage: message,
            actionError: null,
          ),
        );
        add(const LoadMyVisits(forceRefresh: true));
        if (state.teamVisits.isNotEmpty) {
          add(const LoadTeamVisits(forceRefresh: true));
        }
      },
    );
  }

  Future<void> _onCreateVisitActivityRequested(
    CreateVisitActivityRequested event,
    Emitter<VisitState> emit,
  ) async {
    if (state.isCreatingVisitActivity) return;

    emit(
      state.copyWith(
        isCreatingVisitActivity: true,
        actionError: null,
        successMessage: null,
      ),
    );

    final result = await createVisitActivityUseCase(event.params);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            isCreatingVisitActivity: false,
            actionError: failure.message,
          ),
        );
      },
      (message) async {
        emit(
          state.copyWith(
            isCreatingVisitActivity: false,
            successMessage: message,
            actionError: null,
          ),
        );
        add(const LoadMyVisits(forceRefresh: true));
        if (state.teamVisits.isNotEmpty) {
          add(const LoadTeamVisits(forceRefresh: true));
        }
      },
    );
  }

  void _onClearVisitFeedback(
    ClearVisitFeedback event,
    Emitter<VisitState> emit,
  ) {
    emit(state.copyWith(actionError: null, successMessage: null));
  }
}
