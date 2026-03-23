import 'package:equatable/equatable.dart';

import '../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../domain/entities/overtime_detail.dart';

abstract class OvertimeDetailState extends Equatable {
  const OvertimeDetailState();

  @override
  List<Object?> get props => [];
}

class OvertimeDetailInitial extends OvertimeDetailState {
  const OvertimeDetailInitial();
}

class OvertimeDetailLoading extends OvertimeDetailState {
  const OvertimeDetailLoading();
}

class OvertimeDetailLoaded extends OvertimeDetailState {
  final OvertimeDetail detail;
  final List<AttendanceRequestComment> comments;

  const OvertimeDetailLoaded({required this.detail, required this.comments});

  @override
  List<Object?> get props => [detail, comments];
}

class OvertimeDetailStatusUpdating extends OvertimeDetailState {
  final OvertimeDetail detail;
  final List<AttendanceRequestComment> comments;

  const OvertimeDetailStatusUpdating({
    required this.detail,
    required this.comments,
  });

  @override
  List<Object?> get props => [detail, comments];
}

class OvertimeCommentSubmitting extends OvertimeDetailState {
  final OvertimeDetail detail;
  final List<AttendanceRequestComment> comments;

  const OvertimeCommentSubmitting({
    required this.detail,
    required this.comments,
  });

  @override
  List<Object?> get props => [detail, comments];
}

class OvertimeDetailStatusUpdated extends OvertimeDetailState {
  final String message;

  const OvertimeDetailStatusUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class OvertimeDetailError extends OvertimeDetailState {
  final String message;
  final OvertimeDetail? detail;
  final List<AttendanceRequestComment> comments;

  const OvertimeDetailError(
    this.message, {
    this.detail,
    this.comments = const [],
  });

  @override
  List<Object?> get props => [message, detail, comments];
}
