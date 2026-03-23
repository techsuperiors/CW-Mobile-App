import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../attendance/domain/usecases/apply_attendance_regularize_usecase.dart';
import '../../../../../../attendance/domain/usecases/update_attendance_regularize_usecase.dart';
import 'apply_regularize_event.dart';
import 'apply_regularize_state.dart';

/// Apply Regularize BLoC
class ApplyRegularizeBloc
    extends Bloc<ApplyRegularizeEvent, ApplyRegularizeState> {
  final ApplyAttendanceRegularizeUseCase applyRegularizeUseCase;
  final UpdateAttendanceRegularizeUseCase updateRegularizeUseCase;

  ApplyRegularizeBloc({
    required this.applyRegularizeUseCase,
    required this.updateRegularizeUseCase,
  }) : super(const ApplyRegularizeInitial()) {
    on<ApplyRegularize>(_onApplyRegularize);
    on<UpdateRegularize>(_onUpdateRegularize);
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

  Future<void> _onUpdateRegularize(
    UpdateRegularize event,
    Emitter<ApplyRegularizeState> emit,
  ) async {
    emit(const ApplyRegularizeApplying());

    final result = await updateRegularizeUseCase(
      id: event.id,
      requestDate: event.requestDate,
      requestFor: event.requestFor,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      statusUpdatedBy: event.statusUpdatedBy,
      description: event.description,
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
