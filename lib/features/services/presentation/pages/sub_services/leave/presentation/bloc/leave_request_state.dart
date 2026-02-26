import 'package:equatable/equatable.dart';

import '../../../../../../../leaves/domain/entities/leave_type.dart';
import '../../../../../../../leaves/domain/entities/leave_apply_result.dart';

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

/// Leave applied successfully state
class LeaveRequestApplied extends LeaveRequestState {
  final LeaveApplyResult result;

  const LeaveRequestApplied({required this.result});

  @override
  List<Object> get props => [result];
}
