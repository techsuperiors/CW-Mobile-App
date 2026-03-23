import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../domain/entities/overtime_detail.dart';
import '../domain/usecases/add_overtime_request_comment.dart';
import '../domain/usecases/get_overtime_request_comments.dart';
import '../domain/usecases/get_overtime_request_detail.dart';
import '../domain/usecases/withdraw_overtime_request.dart';
import 'overtime_detail_event.dart';
import 'overtime_detail_state.dart';

class OvertimeDetailBloc extends Bloc<OvertimeDetailEvent, OvertimeDetailState> {
  final GetOvertimeRequestDetailUseCase getOvertimeRequestDetailUseCase;
  final WithdrawOvertimeRequestUseCase withdrawOvertimeRequestUseCase;
  final GetOvertimeRequestCommentsUseCase getOvertimeRequestCommentsUseCase;
  final AddOvertimeRequestCommentUseCase addOvertimeRequestCommentUseCase;

  OvertimeDetailBloc({
    required this.getOvertimeRequestDetailUseCase,
    required this.withdrawOvertimeRequestUseCase,
    required this.getOvertimeRequestCommentsUseCase,
    required this.addOvertimeRequestCommentUseCase,
  }) : super(const OvertimeDetailInitial()) {
    on<LoadOvertimeDetail>(_onLoadOvertimeDetail);
    on<UpdateOvertimeRequestStatus>(_onUpdateOvertimeRequestStatus);
    on<AddOvertimeComment>(_onAddOvertimeComment);
  }

  Future<void> _onLoadOvertimeDetail(
    LoadOvertimeDetail event,
    Emitter<OvertimeDetailState> emit,
  ) async {
    emit(const OvertimeDetailLoading());
    final detailResult = await getOvertimeRequestDetailUseCase(event.requestId);
    final commentsResult = await getOvertimeRequestCommentsUseCase(
      clientId: event.clientId,
      requestId: event.requestId,
    );

    detailResult.fold(
      (failure) => emit(OvertimeDetailError(failure.message)),
      (detail) {
        commentsResult.fold(
          (_) => emit(OvertimeDetailLoaded(detail: detail, comments: const [])),
          (comments) =>
              emit(OvertimeDetailLoaded(detail: detail, comments: comments)),
        );
      },
    );
  }

  Future<void> _onUpdateOvertimeRequestStatus(
    UpdateOvertimeRequestStatus event,
    Emitter<OvertimeDetailState> emit,
  ) async {
    final currentState = state;
    OvertimeDetail? currentDetail;
    List<AttendanceRequestComment> currentComments = const [];
    if (currentState is OvertimeDetailLoaded) {
      currentDetail = currentState.detail;
      currentComments = currentState.comments;
      emit(
        OvertimeDetailStatusUpdating(
          detail: currentState.detail,
          comments: currentState.comments,
        ),
      );
    }

    final result = await withdrawOvertimeRequestUseCase(
      requestId: event.requestId,
      status: event.status,
    );
    await result.fold(
      (failure) async {
        emit(
          OvertimeDetailError(
            failure.message,
            detail: currentDetail,
            comments: currentComments,
          ),
        );
        if (currentDetail != null) {
          emit(OvertimeDetailLoaded(detail: currentDetail, comments: currentComments));
        }
      },
      (message) async {
        emit(OvertimeDetailStatusUpdated(message));
        add(LoadOvertimeDetail(requestId: event.requestId, clientId: event.clientId));
      },
    );
  }

  Future<void> _onAddOvertimeComment(
    AddOvertimeComment event,
    Emitter<OvertimeDetailState> emit,
  ) async {
    final currentState = state;
    OvertimeDetail? currentDetail;
    List<AttendanceRequestComment> currentComments = const [];
    if (currentState is OvertimeDetailLoaded) {
      currentDetail = currentState.detail;
      currentComments = currentState.comments;
      emit(
        OvertimeCommentSubmitting(
          detail: currentState.detail,
          comments: currentState.comments,
        ),
      );
    }
    final result = await addOvertimeRequestCommentUseCase(
      requestId: event.requestId,
      comment: event.comment,
    );
    await result.fold(
      (failure) async {
        emit(
          OvertimeDetailError(
            failure.message,
            detail: currentDetail,
            comments: currentComments,
          ),
        );
        if (currentDetail != null) {
          emit(OvertimeDetailLoaded(detail: currentDetail, comments: currentComments));
        }
      },
      (message) async {
        emit(OvertimeDetailStatusUpdated(message));
        add(LoadOvertimeDetail(requestId: event.requestId, clientId: event.clientId));
      },
    );
  }
}
