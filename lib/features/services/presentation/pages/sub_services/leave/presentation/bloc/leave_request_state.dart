import 'package:equatable/equatable.dart';
import 'dart:io';

import '../../../../../../../leaves/domain/entities/leave_type.dart';
import '../../../../../../../leaves/domain/entities/leave_apply_result.dart';
import '../../../../../../../leaves/domain/entities/leave_uploaded_file.dart';

/// Leave request states
abstract class LeaveRequestState extends Equatable {
  const LeaveRequestState();

  @override
  List<Object> get props => [];
}

/// Initial state
class LeaveRequestInitial extends LeaveRequestState {
  const LeaveRequestInitial();
}

/// Loading state
class LeaveRequestLoading extends LeaveRequestState {
  const LeaveRequestLoading();
}

/// Loaded state
class LeaveRequestLoaded extends LeaveRequestState {
  final LeaveTypes leaveTypes;

  const LeaveRequestLoaded({required this.leaveTypes});

  @override
  List<Object> get props => [leaveTypes];
}

/// Error state
class LeaveRequestError extends LeaveRequestState {
  final String message;

  const LeaveRequestError(this.message);

  @override
  List<Object> get props => [message];
}

/// Applying leave state
class LeaveRequestApplying extends LeaveRequestState {
  const LeaveRequestApplying();
}

class LeaveFilesUploading extends LeaveRequestState {
  const LeaveFilesUploading();
}

class LeaveFilesUploaded extends LeaveRequestState {
  final List<LeaveUploadedFile> uploadedFiles;
  final List<File> localFiles;

  const LeaveFilesUploaded({
    required this.uploadedFiles,
    required this.localFiles,
  });

  @override
  List<Object> get props => [uploadedFiles, localFiles];
}

class LeaveFileDeleting extends LeaveRequestState {
  final String fileId;

  const LeaveFileDeleting(this.fileId);

  @override
  List<Object> get props => [fileId];
}

class LeaveFileDeleted extends LeaveRequestState {
  final String message;
  final String fileId;

  const LeaveFileDeleted({
    required this.message,
    required this.fileId,
  });

  @override
  List<Object> get props => [message, fileId];
}

/// Leave applied successfully state
class LeaveRequestApplied extends LeaveRequestState {
  final LeaveApplyResult result;

  const LeaveRequestApplied({required this.result});

  @override
  List<Object> get props => [result];
}

class LeaveRequestUpdated extends LeaveRequestState {
  final LeaveApplyResult result;

  const LeaveRequestUpdated({required this.result});

  @override
  List<Object> get props => [result];
}
