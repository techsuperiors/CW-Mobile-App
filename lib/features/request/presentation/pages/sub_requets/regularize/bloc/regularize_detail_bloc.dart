import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../../../../../attendance/domain/entities/attendance_regularize_detail.dart';
import '../../../../../../attendance/domain/usecases/add_attendance_request_comment_usecase.dart';
import '../../../../../../attendance/domain/usecases/get_attendance_request_comments_usecase.dart';
import '../../../../../../attendance/domain/usecases/get_regularize_request_detail_usecase.dart';
import '../../../../../../attendance/domain/usecases/update_regularize_request_status_usecase.dart';
import 'regularize_detail_event.dart';
import 'regularize_detail_state.dart';

class RegularizeDetailBloc
    extends Bloc<RegularizeDetailEvent, RegularizeDetailState> {
  final GetRegularizeRequestDetailUseCase getRegularizeRequestDetailUseCase;
  final UpdateRegularizeRequestStatusUseCase
      updateRegularizeRequestStatusUseCase;
  final GetAttendanceRequestCommentsUseCase
      getAttendanceRequestCommentsUseCase;
  final AddAttendanceRequestCommentUseCase addAttendanceRequestCommentUseCase;

  RegularizeDetailBloc({
    required this.getRegularizeRequestDetailUseCase,
    required this.updateRegularizeRequestStatusUseCase,
    required this.getAttendanceRequestCommentsUseCase,
    required this.addAttendanceRequestCommentUseCase,
  }) : super(const RegularizeDetailInitial()) {
    on<LoadRegularizeDetail>(_onLoadRegularizeDetail);
    on<UpdateRegularizeRequestStatus>(_onUpdateRegularizeRequestStatus);
    on<AddRegularizeComment>(_onAddRegularizeComment);
  }

  Future<void> _onLoadRegularizeDetail(
    LoadRegularizeDetail event,
    Emitter<RegularizeDetailState> emit,
  ) async {
    emit(const RegularizeDetailLoading());

    final detailResult = await getRegularizeRequestDetailUseCase(event.requestId);
    final commentsResult = await getAttendanceRequestCommentsUseCase(
      clientId: event.clientId,
      requestId: event.requestId,
    );

    detailResult.fold(
      (failure) => emit(RegularizeDetailError(failure.message)),
      (detail) {
        commentsResult.fold(
          (_) => emit(RegularizeDetailLoaded(detail: detail, comments: const [])),
          (comments) => emit(
            RegularizeDetailLoaded(detail: detail, comments: comments),
          ),
        );
      },
    );
  }

  Future<void> _onUpdateRegularizeRequestStatus(
    UpdateRegularizeRequestStatus event,
    Emitter<RegularizeDetailState> emit,
  ) async {
    final currentState = state;
    AttendanceRegularizeDetail? currentDetail;
    List<AttendanceRequestComment> currentComments = const [];
    if (currentState is RegularizeDetailLoaded) {
      currentDetail = currentState.detail;
      currentComments = currentState.comments;
      emit(
        RegularizeDetailStatusUpdating(
          detail: currentState.detail,
          comments: currentState.comments,
          status: event.status,
        ),
      );
    }

    final result = await updateRegularizeRequestStatusUseCase(
      requestId: event.requestId,
      status: event.status,
    );

    await result.fold(
      (failure) async {
        emit(
          RegularizeDetailError(
            failure.message,
            detail: currentDetail,
            comments: currentComments,
          ),
        );
        if (currentDetail != null) {
          emit(
            RegularizeDetailLoaded(
              detail: currentDetail,
              comments: currentComments,
            ),
          );
        }
      },
      (message) async {
        emit(RegularizeDetailStatusUpdated(message));
        add(
          LoadRegularizeDetail(
            requestId: event.requestId,
            clientId: event.clientId,
          ),
        );
      },
    );
  }

  Future<void> _onAddRegularizeComment(
    AddRegularizeComment event,
    Emitter<RegularizeDetailState> emit,
  ) async {
    final currentState = state;
    AttendanceRegularizeDetail? currentDetail;
    List<AttendanceRequestComment> currentComments = const [];
    if (currentState is RegularizeDetailLoaded) {
      currentDetail = currentState.detail;
      currentComments = currentState.comments;
      emit(
        RegularizeCommentSubmitting(
          detail: currentState.detail,
          comments: currentState.comments,
        ),
      );
    }

    final result = await addAttendanceRequestCommentUseCase(
      requestId: event.requestId,
      comment: event.comment,
    );

    await result.fold(
      (failure) async {
        emit(
          RegularizeDetailError(
            failure.message,
            detail: currentDetail,
            comments: currentComments,
          ),
        );
        if (currentDetail != null) {
          emit(
            RegularizeDetailLoaded(
              detail: currentDetail,
              comments: currentComments,
            ),
          );
        }
      },
      (message) async {
        emit(RegularizeDetailStatusUpdated(message));
        add(
          LoadRegularizeDetail(
            requestId: event.requestId,
            clientId: event.clientId,
          ),
        );
      },
    );
  }
}
