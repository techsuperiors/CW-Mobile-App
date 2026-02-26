/// Attendance Details Model based on API response
class AttendanceDetailsModel {
  final int? id;
  final int? clientId;
  final int? userId;
  final String? date;
  final String? punchIn;
  final String? punchOut;
  final String? totalTime;
  final String? breakTime;
  final String? overTime;
  final String? punchInIp;
  final String? punchOutIp;
  final String? punchInLocation;
  final String? punchOutLocation;
  final String? entries;
  final bool? isLateEntries;
  final String? shiftType;
  final int? shiftId;
  final String? punchType;
  final String? status;
  final String? incompleteHours;
  final bool? firstHalf;
  final bool? secondHalf;
  final String? leaveType;
  final String? deductDays;
  final int? regularizeId;
  final bool? isProcessed;
  final List<ActivityModel>? activity;
  final String? createdBy;
  final String? createdAt;
  final String? updatedBy;
  final String? updatedAt;
  final bool? onDuty;
  final bool? wfhShowPunch;

  AttendanceDetailsModel({
    this.id,
    this.clientId,
    this.userId,
    this.date,
    this.punchIn,
    this.punchOut,
    this.totalTime,
    this.breakTime,
    this.overTime,
    this.punchInIp,
    this.punchOutIp,
    this.punchInLocation,
    this.punchOutLocation,
    this.entries,
    this.isLateEntries,
    this.shiftType,
    this.shiftId,
    this.punchType,
    this.status,
    this.incompleteHours,
    this.firstHalf,
    this.secondHalf,
    this.leaveType,
    this.deductDays,
    this.regularizeId,
    this.isProcessed,
    this.activity,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.onDuty,
    this.wfhShowPunch,
  });

  factory AttendanceDetailsModel.fromJson(Map<String, dynamic> json) {
    List<ActivityModel>? activities;
    if (json['activity'] != null && json['activity'] is List) {
      activities = (json['activity'] as List)
          .map((item) => ActivityModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return AttendanceDetailsModel(
      id: json['id'] as int?,
      clientId: json['client_id'] as int?,
      userId: json['user_id'] as int?,
      date: json['date'] as String?,
      punchIn: json['punch_in'] as String?,
      punchOut: json['punch_out'] as String?,
      totalTime: json['total_time'] as String?,
      breakTime: json['break_time'] as String?,
      overTime: json['over_time'] as String?,
      punchInIp: json['punch_in_IP'] as String?,
      punchOutIp: json['punch_out_IP'] as String?,
      punchInLocation: json['punch_in_location'] as String?,
      punchOutLocation: json['punch_out_location'] as String?,
      entries: json['entries'] as String?,
      isLateEntries: json['is_late_entries'] as bool?,
      shiftType: json['shift_type'] as String?,
      shiftId: json['shift_id'] as int?,
      punchType: json['punch_type'] as String?,
      status: json['status'] as String?,
      incompleteHours: json['incomplete_hours'] as String?,
      firstHalf: json['first_half'] as bool?,
      secondHalf: json['second_half'] as bool?,
      leaveType: json['leave_type'] as String?,
      deductDays: json['deduct_days'] as String?,
      regularizeId: json['regularize_id'] as int?,
      isProcessed: json['is_processed'] as bool?,
      activity: activities,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String?,
      updatedBy: json['updated_by'] as String?,
      updatedAt: json['updated_at'] as String?,
      onDuty: json['onDuty'] as bool?,
      wfhShowPunch: json['wfhShowPunch'] as bool?,
    );
  }

  /// Format time string (e.g., "2026-01-11T17:56:52.572Z" to "05:56 PM")
  /// Converts UTC time to local timezone
  String? formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      // Parse as UTC
      final utcDateTime = DateTime.parse(timeString);
      // Convert to local timezone
      final localDateTime = utcDateTime.toLocal();
      final hour = localDateTime.hour;
      final minute = localDateTime.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMinute $period';
    } catch (e) {
      return timeString;
    }
  }

  /// Get formatted punch in time
  String get formattedPunchIn => formatTime(punchIn) ?? '-';

  /// Get formatted punch out time
  String get formattedPunchOut => formatTime(punchOut) ?? '-';

  /// Get formatted break time
  String get formattedBreakTime => breakTime ?? '-';

  /// Get formatted overtime
  String get formattedOverTime => overTime ?? '-';
}

/// Activity Model
class ActivityModel {
  final String? action;
  final String? activityType;
  final String? activityBy;
  final String? createdAt;
  final String? time;
  final String? penaltyMessage;
  final int? paidDays;
  final int? unPaidDays;

  ActivityModel({
    this.action,
    this.activityType,
    this.activityBy,
    this.createdAt,
    this.time,
    this.penaltyMessage,
    this.paidDays,
    this.unPaidDays,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      action: json['action'] as String?,
      activityType: json['activity_type'] as String?,
      activityBy: json['activity_by'] as String?,
      createdAt: json['created_at'] as String?,
      time: json['time'] as String?,
      penaltyMessage: json['penaltyMessage'] as String?,
      paidDays: json['paidDays'] as int?,
      unPaidDays: json['unPaidDays'] as int?,
    );
  }
}

/// Attendance Details Response Model
class AttendanceDetailsResponse {
  final bool success;
  final String? message;
  final AttendanceDetailsModel? data;

  AttendanceDetailsResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory AttendanceDetailsResponse.fromJson(Map<String, dynamic> json) {
    AttendanceDetailsModel? attendanceData;
    if (json['data'] != null) {
      attendanceData = AttendanceDetailsModel.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    }

    return AttendanceDetailsResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: attendanceData,
    );
  }
}

