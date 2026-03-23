import 'package:equatable/equatable.dart';

abstract class LeaveDetailEvent extends Equatable {
  const LeaveDetailEvent();
  @override
  List<Object?> get props => [];
}

class FetchLeaveDetail extends LeaveDetailEvent {
  final int leaveId;
  const FetchLeaveDetail(this.leaveId);
  @override
  List<Object?> get props => [leaveId];
}

class WithdrawLeave extends LeaveDetailEvent {
  final int leaveRequestId;
  const WithdrawLeave(this.leaveRequestId);
  @override
  List<Object?> get props => [leaveRequestId];
}

class UpdateLeaveStatus extends LeaveDetailEvent {
  final int leaveRequestId;
  final int userId;
  final String status;

  const UpdateLeaveStatus({
    required this.leaveRequestId,
    required this.userId,
    required this.status,
  });

  @override
  List<Object?> get props => [leaveRequestId, userId, status];
}

class AddLeaveComment extends LeaveDetailEvent {
  final int leaveId;
  final String comment;

  const AddLeaveComment({
    required this.leaveId,
    required this.comment,
  });

  @override
  List<Object?> get props => [leaveId, comment];
}
