import 'package:equatable/equatable.dart';

/// Represents the payload for applying a leave request
class ApplyLeaveRequestEntity extends Equatable {
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

  const ApplyLeaveRequestEntity({
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
  List<Object?> get props => [
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

/// Represents the response after applying a leave
class ApplyLeaveResponseEntity extends Equatable {
  final bool success;
  final String message;
  final dynamic data;

  const ApplyLeaveResponseEntity({
    required this.success,
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [success, message, data];
}
