import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/create_comp_off_request.dart';
import '../domain/usecases/update_comp_off_request.dart';
import 'apply_comp_off_event.dart';
import 'apply_comp_off_state.dart';

class ApplyCompOffBloc extends Bloc<ApplyCompOffEvent, ApplyCompOffState> {
  final CreateCompOffRequestUseCase createCompOffRequestUseCase;
  final UpdateCompOffRequestUseCase updateCompOffRequestUseCase;

  ApplyCompOffBloc({
    required this.createCompOffRequestUseCase,
    required this.updateCompOffRequestUseCase,
  }) : super(const ApplyCompOffInitial()) {
    on<CreateCompOffEvent>(_onCreate);
    on<UpdateCompOffEvent>(_onUpdate);
  }

  Future<void> _onCreate(
    CreateCompOffEvent event,
    Emitter<ApplyCompOffState> emit,
  ) async {
    emit(const ApplyCompOffSubmitting());
    final result = await createCompOffRequestUseCase(
      type: event.type,
      date: event.date,
      duration: event.duration,
      reason: event.reason,
      subject: event.subject,
      requestTo: event.requestTo,
      userId: event.userId,
    );
    result.fold(
      (failure) => emit(ApplyCompOffError(failure.message)),
      (message) => emit(ApplyCompOffSuccess(message)),
    );
  }

  Future<void> _onUpdate(
    UpdateCompOffEvent event,
    Emitter<ApplyCompOffState> emit,
  ) async {
    emit(const ApplyCompOffSubmitting());
    final result = await updateCompOffRequestUseCase(
      compOffId: event.compOffId,
      subject: event.subject,
      date: event.date,
      duration: event.duration,
      reason: event.reason,
    );
    result.fold(
      (failure) => emit(ApplyCompOffError(failure.message)),
      (message) => emit(ApplyCompOffSuccess(message)),
    );
  }
}
