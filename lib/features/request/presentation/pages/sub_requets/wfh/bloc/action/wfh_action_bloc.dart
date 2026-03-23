import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/update_wfh_status.dart';
import 'wfh_action_event.dart';
import 'wfh_action_state.dart';

class WfhActionBloc extends Bloc<WfhActionEvent, WfhActionState> {
  final UpdateWfhStatusUseCase updateWfhStatusUseCase;

  WfhActionBloc({required this.updateWfhStatusUseCase})
    : super(const WfhActionInitial()) {
    on<UpdateWfhStatus>(_onUpdateWfhStatus);
  }

  Future<void> _onUpdateWfhStatus(
    UpdateWfhStatus event,
    Emitter<WfhActionState> emit,
  ) async {
    emit(const WfhActionInProgress());

    final result = await updateWfhStatusUseCase(
      requestId: event.requestId,
      status: event.status,
    );

    result.fold(
      (failure) => emit(WfhActionFailure(errorMessage: failure.message)),
      (_) => emit(
        WfhActionSuccess(
          message:
              event.status == 'Withdrawn'
                  ? 'WFH Request withdrawn successfully!'
                  : 'Work from home request updated successfully',
        ),
      ),
    );
  }
}
