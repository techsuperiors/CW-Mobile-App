import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../attendance/domain/usecases/apply_attendance_regularize_usecase.dart';
import 'apply_regularize_event.dart';
import 'apply_regularize_state.dart';

/// Apply Regularize BLoC
class ApplyRegularizeBloc
    extends Bloc<ApplyRegularizeEvent, ApplyRegularizeState> {
  final ApplyAttendanceRegularizeUseCase applyRegularizeUseCase;

  ApplyRegularizeBloc({
    required this.applyRegularizeUseCase,
  }) : super(const ApplyRegularizeInitial()) {
    on<ApplyRegularize>(_onApplyRegularize);
  }

  Future<void> _onApplyRegularize(
    ApplyRegularize event,
    Emitter<ApplyRegularizeState> emit,
  ) async {
    emit(const ApplyRegularizeApplying());

    final result = await applyRegularizeUseCase(
      requestDate: event.requestDate,
      requestTo: event.requestTo,
      requestFor: event.requestFor,
      modeType: event.modeType,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      reason: event.reason,
      description: event.description,
      userId: event.userId,
      isOther: event.isOther,
      statusUpdatedBy: event.statusUpdatedBy,
    );

    result.fold(
      (failure) {
        emit(ApplyRegularizeError(failure.message));
      },
      (applyResult) {
        emit(ApplyRegularizeApplied(result: applyResult));
      },
    );
  }
}
