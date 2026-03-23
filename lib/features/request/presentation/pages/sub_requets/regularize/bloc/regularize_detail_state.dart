import 'package:equatable/equatable.dart';

import '../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../../../../../attendance/domain/entities/attendance_regularize_detail.dart';

abstract class RegularizeDetailState extends Equatable {
  const RegularizeDetailState();

  @override
  List<Object?> get props => [];
}

class RegularizeDetailInitial extends RegularizeDetailState {
  const RegularizeDetailInitial();
}

class RegularizeDetailLoading extends RegularizeDetailState {
  const RegularizeDetailLoading();
}

class RegularizeDetailLoaded extends RegularizeDetailState {
  final AttendanceRegularizeDetail detail;
  final List<AttendanceRequestComment> comments;

  const RegularizeDetailLoaded({
    required this.detail,
    required this.comments,
  });

  @override
  List<Object?> get props => [detail, comments];
}

class RegularizeDetailStatusUpdating extends RegularizeDetailState {
  final AttendanceRegularizeDetail detail;
  final List<AttendanceRequestComment> comments;
  final String status;

  const RegularizeDetailStatusUpdating({
    required this.detail,
    required this.comments,
    required this.status,
  });

  @override
  List<Object?> get props => [detail, comments, status];
}

class RegularizeCommentSubmitting extends RegularizeDetailState {
  final AttendanceRegularizeDetail detail;
  final List<AttendanceRequestComment> comments;

  const RegularizeCommentSubmitting({
    required this.detail,
    required this.comments,
  });

  @override
  List<Object?> get props => [detail, comments];
}

class RegularizeDetailStatusUpdated extends RegularizeDetailState {
  final String message;

  const RegularizeDetailStatusUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class RegularizeDetailError extends RegularizeDetailState {
  final String message;
  final AttendanceRegularizeDetail? detail;
  final List<AttendanceRequestComment> comments;

  const RegularizeDetailError(
    this.message, {
    this.detail,
    this.comments = const [],
  });

  @override
  List<Object?> get props => [message, detail, comments];
}
