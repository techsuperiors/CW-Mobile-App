import 'package:equatable/equatable.dart';

/// States emitted by AttendancePunchBloc
/// UI listens to these states to update accordingly
abstract class AttendancePunchState extends Equatable {
  const AttendancePunchState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state — no action has been performed yet
class AttendancePunchInitial extends AttendancePunchState {
  const AttendancePunchInitial();
}

/// Loading state — API call in progress, show spinner on button
class AttendancePunchLoading extends AttendancePunchState {
  const AttendancePunchLoading();
}

/// Punch In succeeded — show success message, start timer
class AttendancePunchInSuccess extends AttendancePunchState {
  final String message;
  final DateTime punchInTime;
  // Unique timestamp to prevent Equatable from deduplicating identical events
  final DateTime _emittedAt;

  AttendancePunchInSuccess({required this.message, DateTime? punchInTime})
    : punchInTime = punchInTime ?? DateTime.now(),
      _emittedAt = DateTime.now();

  @override
  List<Object?> get props => [message, punchInTime, _emittedAt];
}

/// Punch Out succeeded — show success message, stop timer
class AttendancePunchOutSuccess extends AttendancePunchState {
  final String message;
  final DateTime _emittedAt;

  AttendancePunchOutSuccess({required this.message})
    : _emittedAt = DateTime.now();

  @override
  List<Object?> get props => [message, _emittedAt];
}

/// Error state — show error message via SnackBar
class AttendancePunchError extends AttendancePunchState {
  final String message;
  final DateTime _emittedAt;

  AttendancePunchError({required this.message}) : _emittedAt = DateTime.now();

  @override
  List<Object?> get props => [message, _emittedAt];
}
