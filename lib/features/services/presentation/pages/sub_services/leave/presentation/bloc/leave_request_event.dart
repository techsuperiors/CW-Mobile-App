import 'package:equatable/equatable.dart';

/// Leave request events
abstract class LeaveRequestEvent extends Equatable {
  const LeaveRequestEvent();

  @override
  List<Object> get props => [];
}

/// Load leave request details event
class LoadLeaveRequestDetails extends LeaveRequestEvent {
  final int userId;

  const LoadLeaveRequestDetails(this.userId);

  @override
  List<Object> get props => [userId];
}

/// Apply leave event
class ApplyLeave extends LeaveRequestEvent {
  final String leaveType;
  final String clubing;
  final bool isClubbing;
  final String startDate;
  final String endDate;
  final String subject;
  final String reason;
  final String startHalf;
  final String endHalf;
  final String dayType;
  final String description;
  final String shortCode;
  final int requestTo;
  final List<String> rHDates;

  const ApplyLeave({
    required this.leaveType,
    required this.clubing,
    required this.isClubbing,
    required this.startDate,
    required this.endDate,
    required this.subject,
    required this.reason,
    required this.startHalf,
    required this.endHalf,
    required this.dayType,
    required this.description,
    required this.shortCode,
    required this.requestTo,
    required this.rHDates,
  });

  @override
  List<Object> get props => [
        leaveType,
        clubing,
        isClubbing,
        startDate,
        endDate,
        subject,
        reason,
        startHalf,
        endHalf,
        dayType,
        description,
        shortCode,
        requestTo,
        rHDates,
      ];
}