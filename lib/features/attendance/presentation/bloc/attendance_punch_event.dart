import 'package:equatable/equatable.dart';

/// Events for the AttendancePunchBloc
abstract class AttendancePunchEvent extends Equatable {
  const AttendancePunchEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when user taps the Punch In button
class PunchInRequested extends AttendancePunchEvent {
  final bool captureLocation;

  const PunchInRequested({this.captureLocation = true});

  @override
  List<Object?> get props => [captureLocation];
}

/// Triggered when user taps the Punch Out button
class PunchOutRequested extends AttendancePunchEvent {
  final bool captureLocation;

  const PunchOutRequested({this.captureLocation = true});

  @override
  List<Object?> get props => [captureLocation];
}

class PendingAttendanceSyncRequested extends AttendancePunchEvent {
  final bool showFeedback;

  const PendingAttendanceSyncRequested({this.showFeedback = false});

  @override
  List<Object?> get props => [showFeedback];
}
