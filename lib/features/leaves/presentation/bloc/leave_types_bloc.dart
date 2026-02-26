import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_leave_types_usecase.dart';
import 'leave_types_event.dart';
import 'leave_types_state.dart';

/// Bloc for shared leave types data (loaded from dashboard, used by Apply Leave)
class LeaveTypesBloc extends Bloc<LeaveTypesEvent, LeaveTypesState> {
  final GetLeaveTypesUseCase getLeaveTypesUseCase;

  LeaveTypesBloc({
    required this.getLeaveTypesUseCase,
  }) : super(const LeaveTypesInitial()) {
    on<LoadLeaveTypes>(_onLoadLeaveTypes);
  }

  Future<void> _onLoadLeaveTypes(
    LoadLeaveTypes event,
    Emitter<LeaveTypesState> emit,
  ) async {
    emit(const LeaveTypesLoading());

    final result = await getLeaveTypesUseCase(event.userId);

    result.fold(
      (failure) => emit(LeaveTypesError(failure.message)),
      (leaveTypes) => emit(LeaveTypesLoaded(leaveTypes)),
    );
  }
}
