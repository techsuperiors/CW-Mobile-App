import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
  final GetVisitDetailsUseCase getVisitDetailsUseCase;
  final GetVisitActivityDetailsUseCase getVisitActivityDetailsUseCase;
  final CreateVisitUseCase createVisitUseCase;
  final CreateVisitActivityUseCase createVisitActivityUseCase;
  final UpdateVisitActivityUseCase updateVisitActivityUseCase;
  final StartVisitActivityUseCase startVisitActivityUseCase;
  final CompleteVisitActivityUseCase completeVisitActivityUseCase;
  final DeleteVisitActivityUseCase deleteVisitActivityUseCase;
  final int currentUserId;

  VisitBloc({
    required this.getVisitsUseCase,
    required this.getVisitTotalCountUseCase,
    required this.getVisitEmployeesUseCase,
    required this.getVisitCustomersUseCase,
    required this.getVisitAddressesUseCase,
    required this.getVisitDetailsUseCase,
    required this.getVisitActivityDetailsUseCase,
    required this.createVisitUseCase,
    required this.createVisitActivityUseCase,
    required this.updateVisitActivityUseCase,
    required this.startVisitActivityUseCase,
    required this.completeVisitActivityUseCase,
    required this.deleteVisitActivityUseCase,
    required this.currentUserId,
  }) : super(const VisitState()) {
    on<LoadMyVisits>(_onLoadMyVisits);
    on<LoadTeamVisits>(_onLoadTeamVisits);
    on<LoadVisitEmployees>(_onLoadVisitEmployees);
    on<LoadVisitCustomers>(_onLoadVisitCustomers);
    on<LoadVisitAddresses>(_onLoadVisitAddresses);
    on<LoadVisitDetails>(_onLoadVisitDetails);
    on<LoadVisitActivityDetails>(_onLoadVisitActivityDetails);
    on<CreateVisitRequested>(_onCreateVisitRequested);
    on<CreateVisitActivityRequested>(_onCreateVisitActivityRequested);
    on<UpdateVisitActivityRequested>(_onUpdateVisitActivityRequested);
    on<StartVisitActivityRequested>(_onStartVisitActivityRequested);
    on<CompleteVisitActivityRequested>(_onCompleteVisitActivityRequested);
    on<DeleteVisitActivityRequested>(_onDeleteVisitActivityRequested);
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

  Future<void> _onLoadVisitDetails(
    LoadVisitDetails event,
    Emitter<VisitState> emit,
  ) async {
    if (state.isVisitDetailLoading &&
        state.selectedVisitDetailId == event.visitId) {
      return;
    }

    emit(
      state.copyWith(
        isVisitDetailLoading: true,
        selectedVisitDetailId: event.visitId,
        visitDetailError: null,
      ),
    );

    final result = await getVisitDetailsUseCase(event.visitId);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isVisitDetailLoading: false,
            visitDetailError: failure.message,
          ),
        );
      },
      (detail) {
        emit(
          state.copyWith(
            isVisitDetailLoading: false,
            visitDetail: detail,
            visitDetailError: null,
          ),
        );
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

  Future<void> _onLoadVisitActivityDetails(
    LoadVisitActivityDetails event,
    Emitter<VisitState> emit,
  ) async {
    final activityId = event.activityId;
    if (state.loadingVisitActivityDetailIds.contains(activityId)) return;
    if (!event.forceRefresh &&
        state.visitActivityDetailsById.containsKey(activityId)) {
      return;
    }

    emit(
      state.copyWith(
        loadingVisitActivityDetailIds: [
          ...state.loadingVisitActivityDetailIds,
          activityId,
        ],
        visitActivityDetailsById:
            event.forceRefresh
                ? ({
                  ...state.visitActivityDetailsById,
                }..remove(activityId))
                : state.visitActivityDetailsById,
        visitActivityDetailErrorsById: {
          ...state.visitActivityDetailErrorsById,
        }..remove(activityId),
      ),
    );

    final result = await getVisitActivityDetailsUseCase(activityId);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            loadingVisitActivityDetailIds:
                state.loadingVisitActivityDetailIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            visitActivityDetailErrorsById: {
              ...state.visitActivityDetailErrorsById,
              activityId: failure.message,
            },
          ),
        );
      },
      (detail) {
        emit(
          state.copyWith(
            loadingVisitActivityDetailIds:
                state.loadingVisitActivityDetailIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            visitActivityDetailsById: {
              ...state.visitActivityDetailsById,
              activityId: detail,
            },
            visitActivityDetailErrorsById: {
              ...state.visitActivityDetailErrorsById,
            }..remove(activityId),
          ),
        );
      },
    );
  }

  Future<void> _onUpdateVisitActivityRequested(
    UpdateVisitActivityRequested event,
    Emitter<VisitState> emit,
  ) async {
    final activityId = event.params.activityId;
    if (state.updatingVisitActivityIds.contains(activityId)) return;

    emit(
      state.copyWith(
        updatingVisitActivityIds: [...state.updatingVisitActivityIds, activityId],
        updateActivityError: null,
        updateActivitySuccessMessage: null,
        lastUpdatedActivityId: null,
      ),
    );

    final result = await updateVisitActivityUseCase(event.params);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            updatingVisitActivityIds:
                state.updatingVisitActivityIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            updateActivityError: failure.message,
            updateActivitySuccessMessage: null,
            lastUpdatedActivityId: activityId,
          ),
        );
      },
      (message) async {
        emit(
          state.copyWith(
            updatingVisitActivityIds:
                state.updatingVisitActivityIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            visitActivityDetailsById: {
              ...state.visitActivityDetailsById,
            }..remove(activityId),
            visitActivityDetailErrorsById: {
              ...state.visitActivityDetailErrorsById,
            }..remove(activityId),
            updateActivityError: null,
            updateActivitySuccessMessage: message,
            lastUpdatedActivityId: activityId,
          ),
        );
        if (state.selectedVisitDetailId != null) {
          add(LoadVisitDetails(state.selectedVisitDetailId!));
        }
        add(LoadVisitActivityDetails(activityId, forceRefresh: true));
      },
    );
  }

  Future<void> _onStartVisitActivityRequested(
    StartVisitActivityRequested event,
    Emitter<VisitState> emit,
  ) async {
    final activityId = event.params.activityId;
    if (state.startingVisitActivityIds.contains(activityId)) return;

    emit(
      state.copyWith(
        startingVisitActivityIds: [
          ...state.startingVisitActivityIds,
          activityId,
        ],
        startActivityError: null,
        startActivitySuccessMessage: null,
        lastStartedActivityId: null,
      ),
    );

    final result = await startVisitActivityUseCase(event.params);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            startingVisitActivityIds:
                state.startingVisitActivityIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            startActivityError: failure.message,
            startActivitySuccessMessage: null,
            lastStartedActivityId: activityId,
          ),
        );
      },
      (message) async {
        final detail = state.visitDetail;
        final updatedDetail = detail?.copyWith(
          activities:
              detail.activities
                  .map(
                    (activity) =>
                        activity.id == activityId
                            ? activity.copyWith(
                              activityStatus: 'STARTED',
                              activityStartTime:
                                  activity.activityStartTime ??
                                  DateFormat('hh:mm a').format(DateTime.now()),
                            )
                            : activity,
                  )
                  .toList(growable: false),
        );

        emit(
          state.copyWith(
            startingVisitActivityIds:
                state.startingVisitActivityIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            visitDetail: updatedDetail,
            visitActivityDetailsById: {
              ...state.visitActivityDetailsById,
            }..remove(activityId),
            startActivityError: null,
            startActivitySuccessMessage: message,
            lastStartedActivityId: activityId,
          ),
        );
        add(LoadVisitActivityDetails(activityId));
      },
    );
  }

  Future<void> _onCompleteVisitActivityRequested(
    CompleteVisitActivityRequested event,
    Emitter<VisitState> emit,
  ) async {
    final activityId = event.params.activityId;
    if (state.completingVisitActivityIds.contains(activityId)) return;

    emit(
      state.copyWith(
        completingVisitActivityIds: [
          ...state.completingVisitActivityIds,
          activityId,
        ],
        completeActivityError: null,
        completeActivitySuccessMessage: null,
        lastCompletedActivityId: null,
      ),
    );

    final result = await completeVisitActivityUseCase(event.params);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            completingVisitActivityIds:
                state.completingVisitActivityIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            completeActivityError: failure.message,
            completeActivitySuccessMessage: null,
            lastCompletedActivityId: activityId,
          ),
        );
      },
      (message) async {
        final detail = state.visitDetail;
        final updatedVisitDetail = detail?.copyWith(
          activities:
              detail.activities
                  .map(
                    (activity) =>
                        activity.id == activityId
                            ? activity.copyWith(
                              activityStatus: 'COMPLETED',
                              activityEndTime:
                                  activity.activityEndTime ??
                                  DateFormat('hh:mm a').format(DateTime.now()),
                            )
                            : activity,
                  )
                  .toList(growable: false),
        );
        final updatedActivityDetailsById = {
          ...state.visitActivityDetailsById,
        }..remove(activityId);

        emit(
          state.copyWith(
            completingVisitActivityIds:
                state.completingVisitActivityIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            visitDetail: updatedVisitDetail,
            visitActivityDetailsById: updatedActivityDetailsById,
            completeActivityError: null,
            completeActivitySuccessMessage: message,
            lastCompletedActivityId: activityId,
          ),
        );
        add(LoadVisitActivityDetails(activityId));
      },
    );
  }

  Future<void> _onDeleteVisitActivityRequested(
    DeleteVisitActivityRequested event,
    Emitter<VisitState> emit,
  ) async {
    final activityId = event.activityId;
    if (state.deletingVisitActivityIds.contains(activityId)) return;

    emit(
      state.copyWith(
        deletingVisitActivityIds: [
          ...state.deletingVisitActivityIds,
          activityId,
        ],
        deleteActivityError: null,
        deleteActivitySuccessMessage: null,
        lastDeletedActivityId: null,
      ),
    );

    final result = await deleteVisitActivityUseCase(activityId);
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            deletingVisitActivityIds:
                state.deletingVisitActivityIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            deleteActivityError: failure.message,
            deleteActivitySuccessMessage: null,
            lastDeletedActivityId: activityId,
          ),
        );
      },
      (message) {
        final detail = state.visitDetail;
        final updatedVisitDetail = detail?.copyWith(
          activities:
              detail.activities
                  .where((activity) => activity.id != activityId)
                  .toList(growable: false),
        );

        emit(
          state.copyWith(
            deletingVisitActivityIds:
                state.deletingVisitActivityIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            visitDetail: updatedVisitDetail,
            visitActivityDetailsById: {
              ...state.visitActivityDetailsById,
            }..remove(activityId),
            visitActivityDetailErrorsById: {
              ...state.visitActivityDetailErrorsById,
            }..remove(activityId),
            loadingVisitActivityDetailIds:
                state.loadingVisitActivityDetailIds
                    .where((id) => id != activityId)
                    .toList(growable: false),
            deleteActivityError: null,
            deleteActivitySuccessMessage: message,
            lastDeletedActivityId: activityId,
          ),
        );
      },
    );
  }

  void _onClearVisitFeedback(
    ClearVisitFeedback event,
    Emitter<VisitState> emit,
  ) {
    emit(
      state.copyWith(
        actionError: null,
        successMessage: null,
        updateActivityError: null,
        updateActivitySuccessMessage: null,
        lastUpdatedActivityId: null,
        startActivityError: null,
        startActivitySuccessMessage: null,
        lastStartedActivityId: null,
        completeActivityError: null,
        completeActivitySuccessMessage: null,
        lastCompletedActivityId: null,
        deleteActivityError: null,
        deleteActivitySuccessMessage: null,
        lastDeletedActivityId: null,
      ),
    );
  }
}
