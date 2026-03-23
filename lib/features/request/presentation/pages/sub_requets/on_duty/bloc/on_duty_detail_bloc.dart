import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../domain/entities/on_duty_detail.dart';
import '../domain/usecases/add_on_duty_request_comment.dart';
import '../domain/usecases/get_on_duty_request_comments.dart';
import '../domain/usecases/get_on_duty_request_detail.dart';
import '../domain/usecases/update_on_duty_request_status.dart';
import 'on_duty_detail_event.dart';
import 'on_duty_detail_state.dart';

class OnDutyDetailBloc extends Bloc<OnDutyDetailEvent, OnDutyDetailState> {
  final GetOnDutyRequestDetailUseCase getOnDutyRequestDetailUseCase;
  final UpdateOnDutyRequestStatusUseCase updateOnDutyRequestStatusUseCase;
  final GetOnDutyRequestCommentsUseCase getOnDutyRequestCommentsUseCase;
  final AddOnDutyRequestCommentUseCase addOnDutyRequestCommentUseCase;

  OnDutyDetailBloc({
    required this.getOnDutyRequestDetailUseCase,
    required this.updateOnDutyRequestStatusUseCase,
    required this.getOnDutyRequestCommentsUseCase,
    required this.addOnDutyRequestCommentUseCase,
  }) : super(const OnDutyDetailInitial()) {
    on<LoadOnDutyDetail>(_onLoadOnDutyDetail);
    on<UpdateOnDutyRequestStatus>(_onUpdateOnDutyRequestStatus);
    on<AddOnDutyComment>(_onAddOnDutyComment);
  }

  Future<void> _onLoadOnDutyDetail(
    LoadOnDutyDetail event,
    Emitter<OnDutyDetailState> emit,
  ) async {
    emit(const OnDutyDetailLoading());

    final detailResult = await getOnDutyRequestDetailUseCase(event.requestId);
    final commentsResult = await getOnDutyRequestCommentsUseCase(
      clientId: event.clientId,
      requestId: event.requestId,
    );

    detailResult.fold(
      (failure) => emit(OnDutyDetailError(failure.message)),
      (detail) {
        commentsResult.fold(
          (_) => emit(OnDutyDetailLoaded(detail: detail, comments: const [])),
          (comments) =>
              emit(OnDutyDetailLoaded(detail: detail, comments: comments)),
        );
      },
    );
  }

  Future<void> _onUpdateOnDutyRequestStatus(
    UpdateOnDutyRequestStatus event,
    Emitter<OnDutyDetailState> emit,
  ) async {
    final currentState = state;
    OnDutyDetail? currentDetail;
    List<AttendanceRequestComment> currentComments = const [];
    if (currentState is OnDutyDetailLoaded) {
      currentDetail = currentState.detail;
      currentComments = currentState.comments;
      emit(
        OnDutyDetailStatusUpdating(
          detail: currentState.detail,
          comments: currentState.comments,
          status: event.status,
        ),
      );
    }

    final result = await updateOnDutyRequestStatusUseCase(
      requestId: event.requestId,
      status: event.status,
    );

    await result.fold(
      (failure) async {
        emit(
          OnDutyDetailError(
            failure.message,
            detail: currentDetail,
            comments: currentComments,
          ),
        );
        if (currentDetail != null) {
          emit(OnDutyDetailLoaded(detail: currentDetail, comments: currentComments));
        }
      },
      (message) async {
        emit(OnDutyDetailStatusUpdated(message));
        add(LoadOnDutyDetail(requestId: event.requestId, clientId: event.clientId));
      },
    );
  }

  Future<void> _onAddOnDutyComment(
    AddOnDutyComment event,
    Emitter<OnDutyDetailState> emit,
  ) async {
    final currentState = state;
    OnDutyDetail? currentDetail;
    List<AttendanceRequestComment> currentComments = const [];
    if (currentState is OnDutyDetailLoaded) {
      currentDetail = currentState.detail;
      currentComments = currentState.comments;
      emit(
        OnDutyCommentSubmitting(
          detail: currentState.detail,
          comments: currentState.comments,
        ),
      );
    }

    final result = await addOnDutyRequestCommentUseCase(
      requestId: event.requestId,
      comment: event.comment,
    );

    await result.fold(
      (failure) async {
        emit(
          OnDutyDetailError(
            failure.message,
            detail: currentDetail,
            comments: currentComments,
          ),
        );
        if (currentDetail != null) {
          emit(OnDutyDetailLoaded(detail: currentDetail, comments: currentComments));
        }
      },
      (message) async {
        emit(OnDutyDetailStatusUpdated(message));
        add(LoadOnDutyDetail(requestId: event.requestId, clientId: event.clientId));
      },
    );
  }
}
