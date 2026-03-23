import 'package:equatable/equatable.dart';

abstract class LeaveHistoryEvent extends Equatable {
  const LeaveHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when users click the Info icon on a LeaveTypeCard to load the specific balance history
class FetchLeaveHistory extends LeaveHistoryEvent {
  final String leaveType;

  const FetchLeaveHistory({required this.leaveType});

  @override
  List<Object?> get props => [leaveType];
}
