import 'package:equatable/equatable.dart';

import '../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../domain/entities/on_duty_detail.dart';

abstract class OnDutyDetailState extends Equatable {
  const OnDutyDetailState();

  @override
  List<Object?> get props => [];
}

class OnDutyDetailInitial extends OnDutyDetailState {
  const OnDutyDetailInitial();
}

class OnDutyDetailLoading extends OnDutyDetailState {
  const OnDutyDetailLoading();
}

class OnDutyDetailLoaded extends OnDutyDetailState {
  final OnDutyDetail detail;
  final List<AttendanceRequestComment> comments;

  const OnDutyDetailLoaded({
    required this.detail,
    required this.comments,
  });

  @override
  List<Object?> get props => [detail, comments];
}

class OnDutyDetailStatusUpdating extends OnDutyDetailState {
  final OnDutyDetail detail;
  final List<AttendanceRequestComment> comments;
  final String status;

  const OnDutyDetailStatusUpdating({
    required this.detail,
    required this.comments,
    required this.status,
  });

  @override
  List<Object?> get props => [detail, comments, status];
}

class OnDutyCommentSubmitting extends OnDutyDetailState {
  final OnDutyDetail detail;
  final List<AttendanceRequestComment> comments;

  const OnDutyCommentSubmitting({
    required this.detail,
    required this.comments,
  });

  @override
  List<Object?> get props => [detail, comments];
}

class OnDutyDetailStatusUpdated extends OnDutyDetailState {
  final String message;

  const OnDutyDetailStatusUpdated(this.message);

  @override
  List<Object?> get props => [message];
}

class OnDutyDetailError extends OnDutyDetailState {
  final String message;
  final OnDutyDetail? detail;
  final List<AttendanceRequestComment> comments;

  const OnDutyDetailError(
    this.message, {
    this.detail,
    this.comments = const [],
  });

  @override
  List<Object?> get props => [message, detail, comments];
}
