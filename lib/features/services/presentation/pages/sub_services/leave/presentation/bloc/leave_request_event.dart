import 'dart:io';
import 'package:equatable/equatable.dart';

/// Leave request events
abstract class LeaveRequestEvent extends Equatable {
  const LeaveRequestEvent();

  @override
  List<Object> get props => [];
}

class UploadLeaveFiles extends LeaveRequestEvent {
  final int leaveId;
  final List<File> files;

  const UploadLeaveFiles({
    required this.leaveId,
    required this.files,
  });

  @override
  List<Object> get props => [leaveId, files];
}

class DeleteLeaveFile extends LeaveRequestEvent {
  final int leaveFileId;
  final String fileId;

  const DeleteLeaveFile({
    required this.leaveFileId,
    required this.fileId,
  });

  @override
  List<Object> get props => [leaveFileId, fileId];
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
  final List<File> attachmentFiles; // Optional image attachments

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
    this.attachmentFiles = const [],
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

class UpdateLeave extends LeaveRequestEvent {
  final int leaveId;
  final String leaveType;
  final List<String?> clubing;
  final bool isClubbing;
  final String startDate;
  final String? endDate;
  final String subject;
  final String reason;
  final String startHalf;
  final String endHalf;
  final String dayType;
  final String description;
  final int requestTo;

  const UpdateLeave({
    required this.leaveId,
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
    required this.requestTo,
  });

  @override
  List<Object> get props => [
        leaveId,
        leaveType,
        clubing,
        isClubbing,
        startDate,
        endDate ?? '',
        subject,
        reason,
        startHalf,
        endHalf,
        dayType,
        description,
        requestTo,
      ];
}
