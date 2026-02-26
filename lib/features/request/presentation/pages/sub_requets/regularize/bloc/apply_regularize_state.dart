import 'package:equatable/equatable.dart';
import '../../../../../../attendance/domain/entities/attendance_regularize_result.dart';

/// Apply regularize states
abstract class ApplyRegularizeState extends Equatable {
  const ApplyRegularizeState();

  @override
  List<Object> get props => [];
}

/// Initial state
class ApplyRegularizeInitial extends ApplyRegularizeState {
  const ApplyRegularizeInitial();
}

/// Applying regularize state
class ApplyRegularizeApplying extends ApplyRegularizeState {
  const ApplyRegularizeApplying();
}

/// Regularize applied successfully state
class ApplyRegularizeApplied extends ApplyRegularizeState {
  final AttendanceRegularizeResult result;

  const ApplyRegularizeApplied({required this.result});

  @override
  List<Object> get props => [result];
}

/// Error state
class ApplyRegularizeError extends ApplyRegularizeState {
  final String message;

  const ApplyRegularizeError(this.message);

  @override
  List<Object> get props => [message];
}
