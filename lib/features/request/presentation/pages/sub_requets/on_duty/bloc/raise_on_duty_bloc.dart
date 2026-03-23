import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/usecases/raise_on_duty_request.dart';
import 'raise_on_duty_event.dart';
import 'raise_on_duty_state.dart';

class RaiseOnDutyRequestBloc
    extends Bloc<RaiseOnDutyRequestEvent, RaiseOnDutyRequestState> {
  final RaiseOnDutyRequestUseCase raiseOnDutyRequestUseCase;

  RaiseOnDutyRequestBloc({required this.raiseOnDutyRequestUseCase})
      : super(const RaiseOnDutyRequestInitial()) {
    on<SubmitOnDutyRequest>(_onSubmitOnDutyRequest);
  }

  Future<void> _onSubmitOnDutyRequest(
    SubmitOnDutyRequest event,
    Emitter<RaiseOnDutyRequestState> emit,
  ) async {
    emit(const RaiseOnDutyRequestSubmitting());

    final result = await raiseOnDutyRequestUseCase(
      RaiseOnDutyRequestParams(
        subject: event.subject,
        requestType: event.requestType,
        description: event.description,
        startDate: event.startDate,
        endDate: event.endDate,
        startHalf: event.startHalf,
        endHalf: event.endHalf,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(RaiseOnDutyRequestFailure(failure.message)),
      (message) => emit(RaiseOnDutyRequestSuccess(message)),
    );
  }
}
