import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../leaves/domain/usecases/get_leave_types_usecase.dart';
import '../../../../../../../leaves/domain/usecases/apply_leave_usecase.dart';
import '../../../../../../../leaves/domain/usecases/delete_leave_file_usecase.dart';
import '../../../../../../../leaves/domain/usecases/update_leave_usecase.dart';
import '../../../../../../../leaves/domain/usecases/upload_leave_files_usecase.dart';
import 'leave_request_event.dart';
import 'leave_request_state.dart';

/// Leave Request BLoC
class LeaveRequestBloc extends Bloc<LeaveRequestEvent, LeaveRequestState> {
  final GetLeaveTypesUseCase getLeaveTypesUseCase;
  final ApplyLeaveUseCase applyLeaveUseCase;
  final UpdateLeaveUseCase updateLeaveUseCase;
  final UploadLeaveFilesUseCase uploadLeaveFilesUseCase;
  final DeleteLeaveFileUseCase deleteLeaveFileUseCase;

  LeaveRequestBloc({
    required this.getLeaveTypesUseCase,
    required this.applyLeaveUseCase,
    required this.updateLeaveUseCase,
    required this.uploadLeaveFilesUseCase,
    required this.deleteLeaveFileUseCase,
  }) : super(const LeaveRequestInitial()) {
    on<LoadLeaveRequestDetails>(_onLoadLeaveRequestDetails);
    on<ApplyLeave>(_onApplyLeave);
    on<UpdateLeave>(_onUpdateLeave);
    on<UploadLeaveFiles>(_onUploadLeaveFiles);
    on<DeleteLeaveFile>(_onDeleteLeaveFile);
  }

  Future<void> _onLoadLeaveRequestDetails(
    LoadLeaveRequestDetails event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(const LeaveRequestLoading());

    final result = await getLeaveTypesUseCase(event.userId);

    result.fold(
      (failure) {
        emit(LeaveRequestError(failure.message));
      },
      (leaveTypes) {
        emit(LeaveRequestLoaded(leaveTypes: leaveTypes));
      },
    );
  }

  Future<void> _onApplyLeave(
    ApplyLeave event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(const LeaveRequestApplying());

    final result = await applyLeaveUseCase(
      leaveType: event.leaveType,
      clubing: event.clubing,
      isClubbing: event.isClubbing,
      startDate: event.startDate,
      endDate: event.endDate,
      subject: event.subject,
      reason: event.reason,
      startHalf: event.startHalf,
      endHalf: event.endHalf,
      dayType: event.dayType,
      description: event.description,
      shortCode: event.shortCode,
      requestTo: event.requestTo,
      rHDates: event.rHDates,
      leaveStartTime: event.leaveStartTime,
      leaveEndTime: event.leaveEndTime,
      attachmentFiles: event.attachmentFiles,
    );

    result.fold(
      (failure) {
        emit(LeaveRequestError(failure.message));
      },
      (applyResult) {
        emit(LeaveRequestApplied(result: applyResult));
      },
    );
  }

  Future<void> _onUpdateLeave(
    UpdateLeave event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(const LeaveRequestApplying());

    final result = await updateLeaveUseCase(
      leaveId: event.leaveId,
      leaveType: event.leaveType,
      clubing: event.clubing,
      isClubbing: event.isClubbing,
      startDate: event.startDate,
      endDate: event.endDate,
      subject: event.subject,
      reason: event.reason,
      startHalf: event.startHalf,
      endHalf: event.endHalf,
      dayType: event.dayType,
      description: event.description,
      requestTo: event.requestTo,
      leaveStartTime: event.leaveStartTime,
      leaveEndTime: event.leaveEndTime,
    );

    result.fold(
      (failure) {
        emit(LeaveRequestError(failure.message));
      },
      (updateResult) {
        emit(LeaveRequestUpdated(result: updateResult));
      },
    );
  }

  Future<void> _onUploadLeaveFiles(
    UploadLeaveFiles event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(const LeaveFilesUploading());

    final result = await uploadLeaveFilesUseCase(
      leaveId: event.leaveId,
      files: event.files,
    );

    result.fold(
      (failure) {
        emit(LeaveRequestError(failure.message));
      },
      (uploadedFiles) {
        emit(
          LeaveFilesUploaded(
            uploadedFiles: uploadedFiles,
            localFiles: event.files,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteLeaveFile(
    DeleteLeaveFile event,
    Emitter<LeaveRequestState> emit,
  ) async {
    emit(LeaveFileDeleting(event.fileId));

    final result = await deleteLeaveFileUseCase(
      leaveFileId: event.leaveFileId,
      fileId: event.fileId,
    );

    result.fold(
      (failure) => emit(LeaveRequestError(failure.message)),
      (message) => emit(
        LeaveFileDeleted(
          message: message,
          fileId: event.fileId,
        ),
      ),
    );
  }
}
