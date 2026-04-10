import 'dart:io';

/// Leave Apply Request Model
class LeaveApplyRequest {
  final String leaveType;
  final String clubing;
  final bool isClubbing;
  final String startDate;
  final String endDate;
  final String subject;
  final String reason;
  final String? startHalf;
  final String? endHalf;
  final String dayType;
  final String description;
  final String shortCode;
  final int requestTo;
  final List<String> rHDates;
  final String? leaveStartTime;
  final String? leaveEndTime;
  final List<File> attachmentFiles; // Optional image attachments

  LeaveApplyRequest({
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
    this.leaveStartTime,
    this.leaveEndTime,
    this.attachmentFiles = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'leave_type': leaveType,
      'clubing': clubing,
      'is_clubing': isClubbing,
      'start_date': startDate,
      'end_date': endDate,
      'subject': subject,
      'reason': reason,
      'start_half': startHalf,
      'end_half': endHalf,
      'day_type': dayType,
      'description': description,
      'short_code': shortCode,
      'request_to': requestTo,
      'leave_start_time': leaveStartTime,
      'leave_end_time': leaveEndTime,
      'rHDates': rHDates,
    };
  }
}

class UpdateLeaveRequest {
  final int leaveId;
  final String leaveType;
  final int requestTo;
  final String dayType;
  final String startDate;
  final String reason;
  final String subject;
  final String description;
  final String startHalf;
  final String endHalf;
  final bool isClubbing;
  final String? endDate;
  final List<String?> clubing;

  UpdateLeaveRequest({
    required this.leaveId,
    required this.leaveType,
    required this.requestTo,
    required this.dayType,
    required this.startDate,
    required this.reason,
    required this.subject,
    required this.description,
    required this.startHalf,
    required this.endHalf,
    required this.isClubbing,
    required this.endDate,
    required this.clubing,
  });

  Map<String, dynamic> toJson() {
    return {
      'leave_type': leaveType,
      'request_to': requestTo,
      'day_type': dayType,
      'start_date': startDate,
      'reason': reason,
      'subject': subject,
      'description': description,
      'start_half': startHalf,
      'end_half': endHalf,
      'leave_id': leaveId,
      'is_clubing': isClubbing,
      'end_date': endDate,
      'clubing': clubing,
    };
  }
}

/// Leave Apply Response Model
class LeaveApplyResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  LeaveApplyResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory LeaveApplyResponse.fromJson(Map<String, dynamic> json) {
    return LeaveApplyResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

class LeaveFileUploadResponse {
  final bool success;
  final String? message;

  LeaveFileUploadResponse({
    required this.success,
    this.message,
  });

  factory LeaveFileUploadResponse.fromJson(Map<String, dynamic> json) {
    return LeaveFileUploadResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

class LeaveFileDeleteRequest {
  final int leaveFileId;
  final String fileId;

  LeaveFileDeleteRequest({
    required this.leaveFileId,
    required this.fileId,
  });

  Map<String, dynamic> toJson() {
    return {
      'leave_file_id': leaveFileId,
      'file_id': fileId,
    };
  }
}

class LeaveFileDeleteResponse {
  final bool success;
  final String? message;

  LeaveFileDeleteResponse({
    required this.success,
    this.message,
  });

  factory LeaveFileDeleteResponse.fromJson(Map<String, dynamic> json) {
    return LeaveFileDeleteResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}
