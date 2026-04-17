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
  final List<VisitModel> myVisits;
  final List<VisitModel> teamVisits;
  final int myVisitCount;
  final int teamVisitCount;
  final List<VisitEmployeeModel> employees;
  final List<VisitCustomerModel> customers;
  final List<VisitAddressModel> addresses;
  final String? myVisitsError;
  final String? teamVisitsError;
  final String? employeesError;
  final String? customersError;
  final String? addressesError;
  final String? actionError;
  final String? successMessage;

  const VisitState({
    this.isMyVisitsLoading = false,
    this.isTeamVisitsLoading = false,
    this.isEmployeesLoading = false,
    this.isCustomersLoading = false,
    this.isAddressesLoading = false,
    this.isCreatingVisit = false,
    this.isCreatingVisitActivity = false,
    this.myVisits = const [],
    this.teamVisits = const [],
    this.myVisitCount = 0,
    this.teamVisitCount = 0,
    this.employees = const [],
    this.customers = const [],
    this.addresses = const [],
    this.myVisitsError,
    this.teamVisitsError,
    this.employeesError,
    this.customersError,
    this.addressesError,
    this.actionError,
    this.successMessage,
  });

  VisitState copyWith({
    bool? isMyVisitsLoading,
    bool? isTeamVisitsLoading,
    bool? isEmployeesLoading,
    bool? isCustomersLoading,
    bool? isAddressesLoading,
    bool? isCreatingVisit,
    bool? isCreatingVisitActivity,
    List<VisitModel>? myVisits,
    List<VisitModel>? teamVisits,
    int? myVisitCount,
    int? teamVisitCount,
    List<VisitEmployeeModel>? employees,
    List<VisitCustomerModel>? customers,
    List<VisitAddressModel>? addresses,
    Object? myVisitsError = _sentinel,
    Object? teamVisitsError = _sentinel,
    Object? employeesError = _sentinel,
    Object? customersError = _sentinel,
    Object? addressesError = _sentinel,
    Object? actionError = _sentinel,
    Object? successMessage = _sentinel,
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
      myVisits: myVisits ?? this.myVisits,
      teamVisits: teamVisits ?? this.teamVisits,
      myVisitCount: myVisitCount ?? this.myVisitCount,
      teamVisitCount: teamVisitCount ?? this.teamVisitCount,
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
      actionError:
          identical(actionError, _sentinel)
              ? this.actionError
              : actionError as String?,
      successMessage:
          identical(successMessage, _sentinel)
              ? this.successMessage
              : successMessage as String?,
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
    myVisits,
    teamVisits,
    myVisitCount,
    teamVisitCount,
    employees,
    customers,
    addresses,
    myVisitsError,
    teamVisitsError,
    employeesError,
    customersError,
    addressesError,
    actionError,
    successMessage,
  ];
}

const Object _sentinel = Object();
