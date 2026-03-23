import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/create_overtime_request.dart';
import '../domain/usecases/update_overtime_request.dart';
import 'apply_overtime_event.dart';
import 'apply_overtime_state.dart';

class ApplyOvertimeBloc extends Bloc<ApplyOvertimeEvent, ApplyOvertimeState> {
  final CreateOvertimeRequestUseCase createOvertimeRequestUseCase;
  final UpdateOvertimeRequestUseCase updateOvertimeRequestUseCase;

  ApplyOvertimeBloc({
    required this.createOvertimeRequestUseCase,
    required this.updateOvertimeRequestUseCase,
  }) : super(const ApplyOvertimeInitial()) {
    on<CreateOvertime>(_onCreateOvertime);
    on<UpdateOvertime>(_onUpdateOvertime);
  }

  Future<void> _onCreateOvertime(
    CreateOvertime event,
    Emitter<ApplyOvertimeState> emit,
  ) async {
    emit(const ApplyOvertimeSubmitting());
    final result = await createOvertimeRequestUseCase(
      requestDate: event.requestDate,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      subject: event.subject,
      description: event.description,
      userId: event.userId,
    );
    result.fold(
      (failure) => emit(ApplyOvertimeError(failure.message)),
      (message) => emit(ApplyOvertimeSuccess(message)),
    );
  }

  Future<void> _onUpdateOvertime(
    UpdateOvertime event,
    Emitter<ApplyOvertimeState> emit,
  ) async {
    emit(const ApplyOvertimeSubmitting());
    final result = await updateOvertimeRequestUseCase(
      requestId: event.requestId,
      requestDate: event.requestDate,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      userId: event.userId,
      description: event.description,
    );
    result.fold(
      (failure) => emit(ApplyOvertimeError(failure.message)),
      (message) => emit(ApplyOvertimeSuccess(message)),
    );
  }
}
