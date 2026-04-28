import 'package:equatable/equatable.dart';

import '../../domain/models/employee_directory_model.dart';

const _employeeDirectorySentinel = Object();

class EmployeeDirectoryState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final List<EmployeeDirectoryModel> employees;
  final int totalCount;
  final int currentPage;
  final int? selectedEmployeeDetailUserId;
  final List<int> loadingEmployeeDetailUserIds;
  final Map<int, EmployeeDirectoryDetailModel> employeeDetailsByUserId;
  final String? error;
  final String? employeeDetailError;

  const EmployeeDirectoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.employees = const [],
    this.totalCount = 0,
    this.currentPage = 0,
    this.selectedEmployeeDetailUserId,
    this.loadingEmployeeDetailUserIds = const [],
    this.employeeDetailsByUserId = const {},
    this.error,
    this.employeeDetailError,
  });

  bool get hasReachedMax => totalCount > 0 && employees.length >= totalCount;

  EmployeeDirectoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<EmployeeDirectoryModel>? employees,
    int? totalCount,
    int? currentPage,
    Object? selectedEmployeeDetailUserId = _employeeDirectorySentinel,
    List<int>? loadingEmployeeDetailUserIds,
    Map<int, EmployeeDirectoryDetailModel>? employeeDetailsByUserId,
    Object? error = _employeeDirectorySentinel,
    Object? employeeDetailError = _employeeDirectorySentinel,
  }) {
    return EmployeeDirectoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      employees: employees ?? this.employees,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      selectedEmployeeDetailUserId:
          identical(selectedEmployeeDetailUserId, _employeeDirectorySentinel)
              ? this.selectedEmployeeDetailUserId
              : selectedEmployeeDetailUserId as int?,
      loadingEmployeeDetailUserIds:
          loadingEmployeeDetailUserIds ?? this.loadingEmployeeDetailUserIds,
      employeeDetailsByUserId:
          employeeDetailsByUserId ?? this.employeeDetailsByUserId,
      error:
          identical(error, _employeeDirectorySentinel)
              ? this.error
              : error as String?,
      employeeDetailError:
          identical(employeeDetailError, _employeeDirectorySentinel)
              ? this.employeeDetailError
              : employeeDetailError as String?,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    employees,
    totalCount,
    currentPage,
    selectedEmployeeDetailUserId,
    loadingEmployeeDetailUserIds,
    employeeDetailsByUserId,
    error,
    employeeDetailError,
  ];
}
