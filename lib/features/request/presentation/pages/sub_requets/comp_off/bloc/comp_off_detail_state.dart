import 'package:equatable/equatable.dart';
import '../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../domain/entities/comp_off_detail.dart';

abstract class CompOffDetailState extends Equatable {
  const CompOffDetailState();
  @override
  List<Object?> get props => [];
}

class CompOffDetailInitial extends CompOffDetailState {
  const CompOffDetailInitial();
}

class CompOffDetailLoading extends CompOffDetailState {
  const CompOffDetailLoading();
}

class CompOffDetailLoaded extends CompOffDetailState {
  final CompOffDetail detail;
  final List<AttendanceRequestComment> comments;
  const CompOffDetailLoaded({required this.detail, required this.comments});
  @override
  List<Object?> get props => [detail, comments];
}

class CompOffDetailSubmitting extends CompOffDetailState {
  final CompOffDetail detail;
  final List<AttendanceRequestComment> comments;
  const CompOffDetailSubmitting({required this.detail, required this.comments});
  @override
  List<Object?> get props => [detail, comments];
}

class CompOffDetailStatusUpdating extends CompOffDetailState {
  final CompOffDetail detail;
  final List<AttendanceRequestComment> comments;
  const CompOffDetailStatusUpdating({
    required this.detail,
    required this.comments,
  });
  @override
  List<Object?> get props => [detail, comments];
}

class CompOffDetailStatus extends CompOffDetailState {
  final String message;
  const CompOffDetailStatus(this.message);
  @override
  List<Object?> get props => [message];
}

class CompOffDetailError extends CompOffDetailState {
  final String message;
  final CompOffDetail? detail;
  final List<AttendanceRequestComment> comments;
  const CompOffDetailError(this.message, {this.detail, this.comments = const []});
  @override
  List<Object?> get props => [message, detail, comments];
}
