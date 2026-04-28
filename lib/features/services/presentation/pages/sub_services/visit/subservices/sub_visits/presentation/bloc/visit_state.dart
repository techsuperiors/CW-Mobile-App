import 'package:equatable/equatable.dart';

import '../../domain/models/visit_model.dart';

class VisitState extends Equatable {
  final bool isMyVisitsLoading;
  final bool isTeamVisitsLoading;
  final bool isEmployeesLoading;
  final bool isCustomersLoading;
  final bool isAddressesLoading;
  final bool isCreatingVisit;
  final bool isCreatingVisitActivity;
  final bool isVisitDetailLoading;
  final List<int> updatingVisitActivityIds;
  final List<int> startingVisitActivityIds;
  final List<int> completingVisitActivityIds;
  final List<int> deletingVisitActivityIds;
  final List<int> loadingVisitActivityDetailIds;
  final List<VisitModel> myVisits;
  final List<VisitModel> teamVisits;
  final int myVisitCount;
  final int teamVisitCount;
  final int? selectedVisitDetailId;
  final VisitDetailModel? visitDetail;
  final Map<int, VisitActivityDetailModel> visitActivityDetailsById;
  final List<VisitEmployeeModel> employees;
  final List<VisitCustomerModel> customers;
  final List<VisitAddressModel> addresses;
  final String? myVisitsError;
  final String? teamVisitsError;
  final String? employeesError;
  final String? customersError;
  final String? addressesError;
  final String? visitDetailError;
  final String? actionError;
  final String? successMessage;
  final String? updateActivityError;
  final String? updateActivitySuccessMessage;
  final int? lastUpdatedActivityId;
  final String? startActivityError;
  final String? startActivitySuccessMessage;
  final int? lastStartedActivityId;
  final Map<int, String> visitActivityDetailErrorsById;
  final String? completeActivityError;
  final String? completeActivitySuccessMessage;
  final int? lastCompletedActivityId;
  final String? deleteActivityError;
  final String? deleteActivitySuccessMessage;
  final int? lastDeletedActivityId;

  const VisitState({
    this.isMyVisitsLoading = false,
    this.isTeamVisitsLoading = false,
    this.isEmployeesLoading = false,
    this.isCustomersLoading = false,
    this.isAddressesLoading = false,
    this.isCreatingVisit = false,
    this.isCreatingVisitActivity = false,
    this.isVisitDetailLoading = false,
    this.updatingVisitActivityIds = const [],
    this.startingVisitActivityIds = const [],
    this.completingVisitActivityIds = const [],
    this.deletingVisitActivityIds = const [],
    this.loadingVisitActivityDetailIds = const [],
    this.myVisits = const [],
    this.teamVisits = const [],
    this.myVisitCount = 0,
    this.teamVisitCount = 0,
    this.selectedVisitDetailId,
    this.visitDetail,
    this.visitActivityDetailsById = const {},
    this.employees = const [],
    this.customers = const [],
    this.addresses = const [],
    this.myVisitsError,
    this.teamVisitsError,
    this.employeesError,
    this.customersError,
    this.addressesError,
    this.visitDetailError,
    this.actionError,
    this.successMessage,
    this.updateActivityError,
    this.updateActivitySuccessMessage,
    this.lastUpdatedActivityId,
    this.startActivityError,
    this.startActivitySuccessMessage,
    this.lastStartedActivityId,
    this.visitActivityDetailErrorsById = const {},
    this.completeActivityError,
    this.completeActivitySuccessMessage,
    this.lastCompletedActivityId,
    this.deleteActivityError,
    this.deleteActivitySuccessMessage,
    this.lastDeletedActivityId,
  });

  VisitState copyWith({
    bool? isMyVisitsLoading,
    bool? isTeamVisitsLoading,
    bool? isEmployeesLoading,
    bool? isCustomersLoading,
    bool? isAddressesLoading,
    bool? isCreatingVisit,
    bool? isCreatingVisitActivity,
    bool? isVisitDetailLoading,
    List<int>? updatingVisitActivityIds,
    List<int>? startingVisitActivityIds,
    List<int>? completingVisitActivityIds,
    List<int>? deletingVisitActivityIds,
    List<int>? loadingVisitActivityDetailIds,
    List<VisitModel>? myVisits,
    List<VisitModel>? teamVisits,
    int? myVisitCount,
    int? teamVisitCount,
    Object? selectedVisitDetailId = _sentinel,
    Object? visitDetail = _sentinel,
    Map<int, VisitActivityDetailModel>? visitActivityDetailsById,
    List<VisitEmployeeModel>? employees,
    List<VisitCustomerModel>? customers,
    List<VisitAddressModel>? addresses,
    Object? myVisitsError = _sentinel,
    Object? teamVisitsError = _sentinel,
    Object? employeesError = _sentinel,
    Object? customersError = _sentinel,
    Object? addressesError = _sentinel,
    Object? visitDetailError = _sentinel,
    Object? actionError = _sentinel,
    Object? successMessage = _sentinel,
    Object? updateActivityError = _sentinel,
    Object? updateActivitySuccessMessage = _sentinel,
    Object? lastUpdatedActivityId = _sentinel,
    Object? startActivityError = _sentinel,
    Object? startActivitySuccessMessage = _sentinel,
    Object? lastStartedActivityId = _sentinel,
    Map<int, String>? visitActivityDetailErrorsById,
    Object? completeActivityError = _sentinel,
    Object? completeActivitySuccessMessage = _sentinel,
    Object? lastCompletedActivityId = _sentinel,
    Object? deleteActivityError = _sentinel,
    Object? deleteActivitySuccessMessage = _sentinel,
    Object? lastDeletedActivityId = _sentinel,
  }) {
    return VisitState(
      isMyVisitsLoading: isMyVisitsLoading ?? this.isMyVisitsLoading,
      isTeamVisitsLoading: isTeamVisitsLoading ?? this.isTeamVisitsLoading,
      isEmployeesLoading: isEmployeesLoading ?? this.isEmployeesLoading,
      isCustomersLoading: isCustomersLoading ?? this.isCustomersLoading,
      isAddressesLoading: isAddressesLoading ?? this.isAddressesLoading,
      isCreatingVisit: isCreatingVisit ?? this.isCreatingVisit,
      isCreatingVisitActivity:
          isCreatingVisitActivity ?? this.isCreatingVisitActivity,
      isVisitDetailLoading:
          isVisitDetailLoading ?? this.isVisitDetailLoading,
      updatingVisitActivityIds:
          updatingVisitActivityIds ?? this.updatingVisitActivityIds,
      startingVisitActivityIds:
          startingVisitActivityIds ?? this.startingVisitActivityIds,
      completingVisitActivityIds:
          completingVisitActivityIds ?? this.completingVisitActivityIds,
      deletingVisitActivityIds:
          deletingVisitActivityIds ?? this.deletingVisitActivityIds,
      loadingVisitActivityDetailIds:
          loadingVisitActivityDetailIds ?? this.loadingVisitActivityDetailIds,
      myVisits: myVisits ?? this.myVisits,
      teamVisits: teamVisits ?? this.teamVisits,
      myVisitCount: myVisitCount ?? this.myVisitCount,
      teamVisitCount: teamVisitCount ?? this.teamVisitCount,
      selectedVisitDetailId:
          identical(selectedVisitDetailId, _sentinel)
              ? this.selectedVisitDetailId
              : selectedVisitDetailId as int?,
      visitDetail:
          identical(visitDetail, _sentinel)
              ? this.visitDetail
              : visitDetail as VisitDetailModel?,
      visitActivityDetailsById:
          visitActivityDetailsById ?? this.visitActivityDetailsById,
      employees: employees ?? this.employees,
      customers: customers ?? this.customers,
      addresses: addresses ?? this.addresses,
      myVisitsError:
          identical(myVisitsError, _sentinel)
              ? this.myVisitsError
              : myVisitsError as String?,
      teamVisitsError:
          identical(teamVisitsError, _sentinel)
              ? this.teamVisitsError
              : teamVisitsError as String?,
      employeesError:
          identical(employeesError, _sentinel)
              ? this.employeesError
              : employeesError as String?,
      customersError:
          identical(customersError, _sentinel)
              ? this.customersError
              : customersError as String?,
      addressesError:
          identical(addressesError, _sentinel)
              ? this.addressesError
              : addressesError as String?,
      visitDetailError:
          identical(visitDetailError, _sentinel)
              ? this.visitDetailError
              : visitDetailError as String?,
      actionError:
          identical(actionError, _sentinel)
              ? this.actionError
              : actionError as String?,
      successMessage:
          identical(successMessage, _sentinel)
              ? this.successMessage
              : successMessage as String?,
      updateActivityError:
          identical(updateActivityError, _sentinel)
              ? this.updateActivityError
              : updateActivityError as String?,
      updateActivitySuccessMessage:
          identical(updateActivitySuccessMessage, _sentinel)
              ? this.updateActivitySuccessMessage
              : updateActivitySuccessMessage as String?,
      lastUpdatedActivityId:
          identical(lastUpdatedActivityId, _sentinel)
              ? this.lastUpdatedActivityId
              : lastUpdatedActivityId as int?,
      startActivityError:
          identical(startActivityError, _sentinel)
              ? this.startActivityError
              : startActivityError as String?,
      startActivitySuccessMessage:
          identical(startActivitySuccessMessage, _sentinel)
              ? this.startActivitySuccessMessage
              : startActivitySuccessMessage as String?,
      lastStartedActivityId:
          identical(lastStartedActivityId, _sentinel)
              ? this.lastStartedActivityId
              : lastStartedActivityId as int?,
      visitActivityDetailErrorsById:
          visitActivityDetailErrorsById ?? this.visitActivityDetailErrorsById,
      completeActivityError:
          identical(completeActivityError, _sentinel)
              ? this.completeActivityError
              : completeActivityError as String?,
      completeActivitySuccessMessage:
          identical(completeActivitySuccessMessage, _sentinel)
              ? this.completeActivitySuccessMessage
              : completeActivitySuccessMessage as String?,
      lastCompletedActivityId:
          identical(lastCompletedActivityId, _sentinel)
              ? this.lastCompletedActivityId
              : lastCompletedActivityId as int?,
      deleteActivityError:
          identical(deleteActivityError, _sentinel)
              ? this.deleteActivityError
              : deleteActivityError as String?,
      deleteActivitySuccessMessage:
          identical(deleteActivitySuccessMessage, _sentinel)
              ? this.deleteActivitySuccessMessage
              : deleteActivitySuccessMessage as String?,
      lastDeletedActivityId:
          identical(lastDeletedActivityId, _sentinel)
              ? this.lastDeletedActivityId
              : lastDeletedActivityId as int?,
    );
  }

  @override
  List<Object?> get props => [
    isMyVisitsLoading,
    isTeamVisitsLoading,
    isEmployeesLoading,
    isCustomersLoading,
    isAddressesLoading,
    isCreatingVisit,
    isCreatingVisitActivity,
    isVisitDetailLoading,
    updatingVisitActivityIds,
    startingVisitActivityIds,
    completingVisitActivityIds,
    deletingVisitActivityIds,
    loadingVisitActivityDetailIds,
    myVisits,
    teamVisits,
    myVisitCount,
    teamVisitCount,
    selectedVisitDetailId,
    visitDetail,
    visitActivityDetailsById,
    employees,
    customers,
    addresses,
    myVisitsError,
    teamVisitsError,
    employeesError,
    customersError,
    addressesError,
    visitDetailError,
    actionError,
    successMessage,
    updateActivityError,
    updateActivitySuccessMessage,
    lastUpdatedActivityId,
    startActivityError,
    startActivitySuccessMessage,
    lastStartedActivityId,
    visitActivityDetailErrorsById,
    completeActivityError,
    completeActivitySuccessMessage,
    lastCompletedActivityId,
    deleteActivityError,
    deleteActivitySuccessMessage,
    lastDeletedActivityId,
  ];
}

const Object _sentinel = Object();
