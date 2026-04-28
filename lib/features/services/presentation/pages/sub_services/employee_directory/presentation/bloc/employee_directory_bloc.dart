import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../../core/constants/app_strings.dart';
import '../../domain/models/employee_directory_model.dart';
import '../../domain/usecases/get_employee_directory_usecase.dart';
import 'employee_directory_event.dart';
import 'employee_directory_state.dart';

class EmployeeDirectoryBloc
    extends Bloc<EmployeeDirectoryEvent, EmployeeDirectoryState> {
  final GetEmployeeDirectoryUseCase getEmployeeDirectoryUseCase;
  final GetEmployeeDirectoryDetailUseCase getEmployeeDirectoryDetailUseCase;
  final int clientId;

  static const int pageSize = 16;

  EmployeeDirectoryBloc({
    required this.getEmployeeDirectoryUseCase,
    required this.getEmployeeDirectoryDetailUseCase,
    required this.clientId,
  }) : super(const EmployeeDirectoryState()) {
    on<LoadEmployeeDirectory>(_onLoadEmployeeDirectory);
    on<LoadMoreEmployeeDirectory>(_onLoadMoreEmployeeDirectory);
    on<LoadEmployeeDirectoryDetail>(_onLoadEmployeeDirectoryDetail);
    on<ClearEmployeeDirectoryDetail>(_onClearEmployeeDirectoryDetail);
  }

  Future<void> _onLoadEmployeeDirectory(
    LoadEmployeeDirectory event,
    Emitter<EmployeeDirectoryState> emit,
  ) async {
    if (state.isLoading) return;
    if (!event.forceRefresh && state.employees.isNotEmpty) return;

    if (clientId <= 0) {
      emit(
        state.copyWith(
          error: 'Unable to resolve employee directory context.',
          isLoading: false,
          isLoadingMore: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        isLoadingMore: false,
        error: null,
        currentPage: event.forceRefresh ? 0 : state.currentPage,
      ),
    );

    final result = await getEmployeeDirectoryUseCase(
      clientId: clientId,
      page: 1,
      limit: pageSize,
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoading: false,
            employees: event.forceRefresh ? const [] : state.employees,
            totalCount: event.forceRefresh ? 0 : state.totalCount,
            currentPage: event.forceRefresh ? 0 : state.currentPage,
            error: failure.message,
          ),
        );
      },
      (pageData) {
        emit(
          state.copyWith(
            isLoading: false,
            employees: pageData.employees,
            totalCount: pageData.totalCount,
            currentPage: 1,
            error: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadMoreEmployeeDirectory(
    LoadMoreEmployeeDirectory event,
    Emitter<EmployeeDirectoryState> emit,
  ) async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.employees.isEmpty ||
        state.hasReachedMax) {
      return;
    }

    if (clientId <= 0) {
      emit(state.copyWith(error: AppStrings.unexpectedError));
      return;
    }

    emit(state.copyWith(isLoadingMore: true, error: null));
    final nextPage = state.currentPage + 1;
    final result = await getEmployeeDirectoryUseCase(
      clientId: clientId,
      page: nextPage,
      limit: pageSize,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoadingMore: false, error: failure.message));
      },
      (pageData) {
        emit(
          state.copyWith(
            isLoadingMore: false,
            employees: [...state.employees, ...pageData.employees],
            totalCount: pageData.totalCount,
            currentPage: nextPage,
            error: null,
          ),
        );
      },
    );
  }

  Future<void> _onLoadEmployeeDirectoryDetail(
    LoadEmployeeDirectoryDetail event,
    Emitter<EmployeeDirectoryState> emit,
  ) async {
    final cachedDetail = state.employeeDetailsByUserId[event.userId];
    final isAlreadyLoading = state.loadingEmployeeDetailUserIds.contains(
      event.userId,
    );

    emit(
      state.copyWith(
        selectedEmployeeDetailUserId: event.userId,
        employeeDetailError: null,
      ),
    );

    if (cachedDetail != null && !event.forceRefresh) {
      return;
    }
    if (isAlreadyLoading) {
      return;
    }

    emit(
      state.copyWith(
        loadingEmployeeDetailUserIds: [
          ...state.loadingEmployeeDetailUserIds,
          event.userId,
        ],
        employeeDetailError: null,
      ),
    );

    final result = await getEmployeeDirectoryDetailUseCase(
      userId: event.userId,
    );
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            loadingEmployeeDetailUserIds: state.loadingEmployeeDetailUserIds
                .where((id) => id != event.userId)
                .toList(growable: false),
            employeeDetailError: failure.message,
          ),
        );
      },
      (detail) {
        final updatedDetails = Map<int, EmployeeDirectoryDetailModel>.from(
          state.employeeDetailsByUserId,
        )..[event.userId] = detail;

        emit(
          state.copyWith(
            loadingEmployeeDetailUserIds: state.loadingEmployeeDetailUserIds
                .where((id) => id != event.userId)
                .toList(growable: false),
            employeeDetailsByUserId: updatedDetails,
            employeeDetailError: null,
          ),
        );
      },
    );
  }

  void _onClearEmployeeDirectoryDetail(
    ClearEmployeeDirectoryDetail event,
    Emitter<EmployeeDirectoryState> emit,
  ) {
    emit(
      state.copyWith(
        selectedEmployeeDetailUserId: null,
        employeeDetailError: null,
      ),
    );
  }
}
