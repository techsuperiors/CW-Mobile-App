import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../domain/entities/comp_off_detail.dart';
import '../domain/usecases/add_comp_off_comment.dart';
import '../domain/usecases/get_comp_off_comments.dart';
import '../domain/usecases/get_comp_off_detail.dart';
import '../domain/usecases/update_comp_off_status.dart';
import '../domain/usecases/upload_comp_off_file.dart';
import 'comp_off_detail_event.dart';
import 'comp_off_detail_state.dart';

class CompOffDetailBloc extends Bloc<CompOffDetailEvent, CompOffDetailState> {
  final GetCompOffDetailUseCase getCompOffDetailUseCase;
  final GetCompOffCommentsUseCase getCompOffCommentsUseCase;
  final AddCompOffCommentUseCase addCompOffCommentUseCase;
  final UploadCompOffFileUseCase uploadCompOffFileUseCase;
  final UpdateCompOffStatusUseCase updateCompOffStatusUseCase;

  CompOffDetailBloc({
    required this.getCompOffDetailUseCase,
    required this.getCompOffCommentsUseCase,
    required this.addCompOffCommentUseCase,
    required this.uploadCompOffFileUseCase,
    required this.updateCompOffStatusUseCase,
  }) : super(const CompOffDetailInitial()) {
    on<LoadCompOffDetail>(_onLoadDetail);
    on<AddCompOffCommentEvent>(_onAddComment);
    on<UploadCompOffFileEvent>(_onUploadFile);
    on<UpdateCompOffRequestStatus>(_onUpdateStatus);
  }

  Future<void> _onLoadDetail(
    LoadCompOffDetail event,
    Emitter<CompOffDetailState> emit,
  ) async {
    emit(const CompOffDetailLoading());
    final detailResult = await getCompOffDetailUseCase(event.compOffId);
    final commentsResult = await getCompOffCommentsUseCase(compOffId: event.compOffId);
    detailResult.fold(
      (failure) => emit(CompOffDetailError(failure.message)),
      (detail) {
        commentsResult.fold(
          (_) => emit(CompOffDetailLoaded(detail: detail, comments: const [])),
          (comments) => emit(
            CompOffDetailLoaded(detail: detail, comments: comments),
          ),
        );
      },
    );
  }

  Future<void> _onAddComment(
    AddCompOffCommentEvent event,
    Emitter<CompOffDetailState> emit,
  ) async {
    final current = state;
    CompOffDetail? detail;
    List<AttendanceRequestComment> comments = const [];
    if (current is CompOffDetailLoaded) {
      detail = current.detail;
      comments = current.comments;
      emit(CompOffDetailSubmitting(detail: detail, comments: comments));
    }
    final result = await addCompOffCommentUseCase(
      compOffId: event.compOffId,
      comment: event.comment,
    );
    await result.fold(
      (failure) async {
        emit(CompOffDetailError(failure.message, detail: detail, comments: comments));
        if (detail != null) {
          emit(CompOffDetailLoaded(detail: detail, comments: comments));
        }
      },
      (message) async {
        emit(CompOffDetailStatus(message));
        add(LoadCompOffDetail(event.compOffId));
      },
    );
  }

  Future<void> _onUploadFile(
    UploadCompOffFileEvent event,
    Emitter<CompOffDetailState> emit,
  ) async {
    final current = state;
    CompOffDetail? detail;
    List<AttendanceRequestComment> comments = const [];
    if (current is CompOffDetailLoaded) {
      detail = current.detail;
      comments = current.comments;
      emit(CompOffDetailSubmitting(detail: detail, comments: comments));
    }
    final result = await uploadCompOffFileUseCase(
      compOffId: event.compOffId,
      filePath: event.filePath,
    );
    result.fold(
      (failure) {
        emit(CompOffDetailError(failure.message, detail: detail, comments: comments));
        if (detail != null) {
          emit(CompOffDetailLoaded(detail: detail, comments: comments));
        }
      },
      (message) {
        emit(CompOffDetailStatus(message));
        add(LoadCompOffDetail(event.compOffId));
      },
    );
  }

  Future<void> _onUpdateStatus(
    UpdateCompOffRequestStatus event,
    Emitter<CompOffDetailState> emit,
  ) async {
    final current = state;
    CompOffDetail? detail;
    List<AttendanceRequestComment> comments = const [];
    if (current is CompOffDetailLoaded) {
      detail = current.detail;
      comments = current.comments;
      emit(CompOffDetailStatusUpdating(detail: detail, comments: comments));
    }

    final result = await updateCompOffStatusUseCase(
      compOffId: event.compOffId,
      status: event.status,
      type: event.type,
    );
    await result.fold(
      (failure) async {
        emit(CompOffDetailError(failure.message, detail: detail, comments: comments));
        if (detail != null) {
          emit(CompOffDetailLoaded(detail: detail, comments: comments));
        }
      },
      (message) async {
        emit(CompOffDetailStatus(message));
        add(LoadCompOffDetail(event.compOffId));
      },
    );
  }
}
