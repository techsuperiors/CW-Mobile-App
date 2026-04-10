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
  final bool requiresServerRefresh;
  final bool isQueuedOffline;
  // Unique timestamp to prevent Equatable from deduplicating identical events
  final DateTime _emittedAt;

  AttendancePunchInSuccess({
    required this.message,
    DateTime? punchInTime,
    this.requiresServerRefresh = false,
    this.isQueuedOffline = false,
  })
    : punchInTime = punchInTime ?? DateTime.now(),
      _emittedAt = DateTime.now();

  @override
  List<Object?> get props => [
    message,
    punchInTime,
    requiresServerRefresh,
    isQueuedOffline,
    _emittedAt,
  ];
}

/// Punch Out succeeded — show success message, stop timer
class AttendancePunchOutSuccess extends AttendancePunchState {
  final String message;
  final bool requiresServerRefresh;
  final bool isQueuedOffline;
  final DateTime _emittedAt;

  AttendancePunchOutSuccess({
    required this.message,
    this.requiresServerRefresh = false,
    this.isQueuedOffline = false,
  })
    : _emittedAt = DateTime.now();

  @override
  List<Object?> get props => [
    message,
    requiresServerRefresh,
    isQueuedOffline,
    _emittedAt,
  ];
}

/// Error state — show error message via SnackBar
class AttendancePunchError extends AttendancePunchState {
  final String message;
  final DateTime _emittedAt;

  AttendancePunchError({required this.message}) : _emittedAt = DateTime.now();

  @override
  List<Object?> get props => [message, _emittedAt];
}

class AttendancePendingSyncSuccess extends AttendancePunchState {
  final String message;
  final DateTime _emittedAt;

  AttendancePendingSyncSuccess({required this.message})
    : _emittedAt = DateTime.now();

  @override
  List<Object?> get props => [message, _emittedAt];
}
