import 'package:equatable/equatable.dart';

/// Leave types events
abstract class LeaveTypesEvent extends Equatable {
  const LeaveTypesEvent();

  @override
  List<Object> get props => [];
}

/// Load leave types event (dispatched from dashboard/attendance)
class LoadLeaveTypes extends LeaveTypesEvent {
  final int userId;

  const LoadLeaveTypes(this.userId);

  @override
  List<Object> get props => [userId];
}
