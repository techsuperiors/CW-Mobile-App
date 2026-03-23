import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_leave_history_usecase.dart';
import 'leave_history_event.dart';
import 'leave_history_state.dart';

class LeaveHistoryBloc extends Bloc<LeaveHistoryEvent, LeaveHistoryState> {
  final GetLeaveHistoryUseCase getLeaveHistoryUseCase;

  LeaveHistoryBloc({required this.getLeaveHistoryUseCase})
    : super(LeaveHistoryInitial()) {
    on<FetchLeaveHistory>(_onFetchLeaveHistory);
  }

  Future<void> _onFetchLeaveHistory(
    FetchLeaveHistory event,
    Emitter<LeaveHistoryState> emit,
  ) async {
    emit(LeaveHistoryLoading());
    final result = await getLeaveHistoryUseCase(event.leaveType);

    result.fold(
      (failure) => emit(LeaveHistoryError(message: failure.message)),
      (history) => emit(LeaveHistoryLoaded(history: history)),
    );
  }
}
