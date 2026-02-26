import 'package:equatable/equatable.dart';
import '../../domain/entities/leave_type.dart';

/// Leave types states
abstract class LeaveTypesState extends Equatable {
  const LeaveTypesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LeaveTypesInitial extends LeaveTypesState {
  const LeaveTypesInitial();
}

/// Loading state
class LeaveTypesLoading extends LeaveTypesState {
  const LeaveTypesLoading();
}

/// Loaded state
class LeaveTypesLoaded extends LeaveTypesState {
  final LeaveTypes leaveTypes;

  const LeaveTypesLoaded(this.leaveTypes);

  @override
  List<Object?> get props => [leaveTypes];
}

/// Error state
class LeaveTypesError extends LeaveTypesState {
  final String message;

  const LeaveTypesError(this.message);

  @override
  List<Object?> get props => [message];
}
