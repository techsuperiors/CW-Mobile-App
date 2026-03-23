import 'package:equatable/equatable.dart';

/// Represents a single record in the user's leave balance history
class LeaveHistoryEntity extends Equatable {
  final String leaveType;
  final String action;
  final double leaveCount;
  final double remainingLeaves;
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String profileUrl;
  final String profileColor;
  final DateTime date;
  final String remarks;
  final String performedBy;

  const LeaveHistoryEntity({
    required this.leaveType,
    required this.action,
    required this.leaveCount,
    required this.remainingLeaves,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.profileUrl,
    required this.profileColor,
    required this.date,
    required this.remarks,
    required this.performedBy,
  });

  @override
  List<Object?> get props => [
    leaveType,
    action,
    leaveCount,
    remainingLeaves,
    userId,
    email,
    firstName,
    lastName,
    profileUrl,
    profileColor,
    date,
    remarks,
    performedBy,
  ];
}
