/// Leave Apply Request Model
class LeaveApplyRequest {
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
      'rHDates': rHDates,
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
