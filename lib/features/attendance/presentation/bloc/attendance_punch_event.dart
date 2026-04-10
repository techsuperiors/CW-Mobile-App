import 'package:equatable/equatable.dart';

/// Events for the AttendancePunchBloc
abstract class AttendancePunchEvent extends Equatable {
  const AttendancePunchEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when user taps the Punch In button
class PunchInRequested extends AttendancePunchEvent {
  const PunchInRequested();
}

/// Triggered when user taps the Punch Out button
class PunchOutRequested extends AttendancePunchEvent {
  const PunchOutRequested();
}

class PendingAttendanceSyncRequested extends AttendancePunchEvent {
  final bool showFeedback;

  const PendingAttendanceSyncRequested({this.showFeedback = false});

  @override
  List<Object?> get props => [showFeedback];
}
