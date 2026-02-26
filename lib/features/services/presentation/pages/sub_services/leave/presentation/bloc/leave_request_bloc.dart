import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../leaves/domain/usecases/get_leave_types_usecase.dart';
import '../../../../../../../leaves/domain/usecases/apply_leave_usecase.dart';
import 'leave_request_event.dart';
import 'leave_request_state.dart';

/// Leave Request BLoC
class LeaveRequestBloc extends Bloc<LeaveRequestEvent, LeaveRequestState> {
  final GetLeaveTypesUseCase getLeaveTypesUseCase;
  final ApplyLeaveUseCase applyLeaveUseCase;

  LeaveRequestBloc({
    required this.getLeaveTypesUseCase,
    required this.applyLeaveUseCase,
  }) : super(const LeaveRequestInitial()) {
    on<LoadLeaveRequestDetails>(_onLoadLeaveRequestDetails);
    on<ApplyLeave>(_onApplyLeave);
  }

  Future<void> _onLoadLeaveRequestDetails(
    LoadLeaveRequestDetails event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(const LeaveRequestLoading());

    final result = await getLeaveTypesUseCase(event.userId);

    result.fold(
      (failure) {
        emit(LeaveRequestError(failure.message));
      },
      (leaveTypes) {
        emit(LeaveRequestLoaded(leaveTypes: leaveTypes));
      },
    );
  }

  Future<void> _onApplyLeave(
    ApplyLeave event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(const LeaveRequestApplying());

    final result = await applyLeaveUseCase(
      leaveType: event.leaveType,
      clubing: event.clubing,
      isClubbing: event.isClubbing,
      startDate: event.startDate,
      endDate: event.endDate,
      subject: event.subject,
      reason: event.reason,
      startHalf: event.startHalf,
      endHalf: event.endHalf,
      dayType: event.dayType,
      description: event.description,
      shortCode: event.shortCode,
      requestTo: event.requestTo,
      rHDates: event.rHDates,
    );

    result.fold(
      (failure) {
        emit(LeaveRequestError(failure.message));
      },
      (applyResult) {
        emit(LeaveRequestApplied(result: applyResult));
      },
    );
  }
}
