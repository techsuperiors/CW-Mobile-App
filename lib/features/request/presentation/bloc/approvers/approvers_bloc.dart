import 'package:flutter_bloc/flutter_bloc.dart';
import '../../pages/sub_requets/leaves/domain/usecases/get_approvers.dart';
import '../../pages/sub_requets/leaves/data/models/approver_model.dart';
import 'approvers_event.dart';
import 'approvers_state.dart';

class ApproversBloc extends Bloc<ApproversEvent, ApproversState> {
  final GetApprovers getApprovers;

  ApproversBloc({required this.getApprovers}) : super(ApproversInitial()) {
    on<FetchApprovers>(_onFetchApprovers);
  }

  Future<void> _onFetchApprovers(
    FetchApprovers event,
    Emitter<ApproversState> emit,
  ) async {
    emit(ApproversLoading());

    final result = await getApprovers(
      GetApproversParams(endpoint: event.endpoint, payload: event.payload),
    );

    result.fold(
      (failure) => emit(ApproversError(failure.message ?? 'Unknown Error')),
      (data) {
        final approversList =
            (data['approvers'] as List<dynamic>?)
                ?.map(
                  (e) => ApproverLevelModel.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [];

        emit(ApproversLoaded(approversList, data));
      },
    );
  }
}
