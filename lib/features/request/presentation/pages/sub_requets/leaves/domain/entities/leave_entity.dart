import 'package:equatable/equatable.dart';

/// Leave status enum
enum LeaveStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

class LeaveAttachmentRef extends Equatable {
  final int leaveFileId;
  final String fileId;
  final String url;
  final String name;

  const LeaveAttachmentRef({
    required this.leaveFileId,
    required this.fileId,
    required this.url,
    required this.name,
  });

  @override
  List<Object?> get props => [leaveFileId, fileId, url, name];
}

/// Leave Entity representing the core business object for a leave request list item
class LeaveEntity extends Equatable {
  final String id;
  final String leaveType;
  final String? shortCode;
  final DateTime fromDate;
  final DateTime? toDate;
  final String? dayType;
  final String? startHalf;
  final String? endHalf;
  final String? leaveStartTime;
  final String? leaveEndTime;
  final int? noOfDays;
  final String reason;
  final String? subject;
  final String? description;
  final LeaveStatus status;
  final DateTime appliedDate;
  final String? rejectRemark;
  final List<String> fileDocuments;
  final List<LeaveAttachmentRef> fileAttachments;

  const LeaveEntity({
    required this.id,
    required this.leaveType,
    this.shortCode,
    required this.fromDate,
    this.toDate,
    this.dayType,
    this.startHalf,
    this.endHalf,
    this.leaveStartTime,
    this.leaveEndTime,
    this.noOfDays,
    required this.reason,
    this.subject,
    this.description,
    required this.status,
    required this.appliedDate,
    this.rejectRemark,
    this.fileDocuments = const [],
    this.fileAttachments = const [],
  });

  @override
  List<Object?> get props => [
    id,
    leaveType,
    shortCode,
    fromDate,
    toDate,
    dayType,
    startHalf,
    endHalf,
    leaveStartTime,
    leaveEndTime,
    noOfDays,
    reason,
    subject,
    description,
    status,
    appliedDate,
    rejectRemark,
    fileDocuments,
    fileAttachments,
  ];
}
