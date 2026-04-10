/// OverTime Model
double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class OverTimeModel {
  final int total;
  final int beforePunchIn;
  final int afterPunchOut;

  OverTimeModel({
    required this.total,
    required this.beforePunchIn,
    required this.afterPunchOut,
  });

  factory OverTimeModel.fromJson(Map<String, dynamic> json) {
    return OverTimeModel(
      total: json['total'] as int? ?? 0,
      beforePunchIn: json['before_punchIn'] as int? ?? 0,
      afterPunchOut: json['after_punchOut'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'before_punchIn': beforePunchIn,
      'after_punchOut': afterPunchOut,
    };
  }
}

/// Shift Day Timing Model
class ShiftDayTimingModel {
  final String day;
  final String punchIn;
  final String punchOut;
  final String breakTime;
  final String grossHours;
  final String effectiveHours;

  ShiftDayTimingModel({
    required this.day,
    required this.punchIn,
    required this.punchOut,
    required this.breakTime,
    required this.grossHours,
    required this.effectiveHours,
  });

  factory ShiftDayTimingModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse String fields that might be int or String
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return ShiftDayTimingModel(
      day: parseString(json['day']),
      punchIn: parseString(json['punch_in']),
      punchOut: parseString(json['punch_out']),
      breakTime: parseString(json['break_time']),
      grossHours: parseString(json['gross_hours']),
      effectiveHours: parseString(json['effective_hours']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'punch_in': punchIn,
      'punch_out': punchOut,
      'break_time': breakTime,
      'gross_hours': grossHours,
      'effective_hours': effectiveHours,
    };
  }
}

/// Weekly Off Day Model
class WeeklyOffDayModel {
  final String day;
  final String offType;
  final bool selectedDay;
  final List<String> weeklyOccurrence;

  WeeklyOffDayModel({
    required this.day,
    required this.offType,
    required this.selectedDay,
    required this.weeklyOccurrence,
  });

  factory WeeklyOffDayModel.fromJson(Map<String, dynamic> json) {
    List<String> occurrences = [];
    if (json['weekly_occurrence'] != null &&
        json['weekly_occurrence'] is List) {
      occurrences =
          (json['weekly_occurrence'] as List)
              .map((item) => item.toString())
              .toList();
    }

    // Helper function to safely parse String fields that might be int or String
    String parseString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return WeeklyOffDayModel(
      day: parseString(json['day']),
      offType: parseString(json['off_type']),
      selectedDay: json['selected_day'] as bool? ?? false,
      weeklyOccurrence: occurrences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'off_type': offType,
      'selected_day': selectedDay,
      'weekly_occurrence': weeklyOccurrence,
    };
  }
}

/// Shift Model
class ShiftModel {
  final int id;
  final List<ShiftDayTimingModel> shiftDayTiming;
  final List<WeeklyOffDayModel> weeklyOffDays;

  ShiftModel({
    required this.id,
    required this.shiftDayTiming,
    required this.weeklyOffDays,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    List<ShiftDayTimingModel> dayTimings = [];
    if (json['shift_day_timing'] != null && json['shift_day_timing'] is List) {
      dayTimings =
          (json['shift_day_timing'] as List)
              .map(
                (item) =>
                    ShiftDayTimingModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    }

    List<WeeklyOffDayModel> offDays = [];
    if (json['weekly_off_days'] != null && json['weekly_off_days'] is List) {
      offDays =
          (json['weekly_off_days'] as List)
              .map(
                (item) =>
                    WeeklyOffDayModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    }

    return ShiftModel(
      id: json['id'] as int? ?? 0,
      shiftDayTiming: dayTimings,
      weeklyOffDays: offDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shift_day_timing': shiftDayTiming.map((e) => e.toJson()).toList(),
      'weekly_off_days': weeklyOffDays.map((e) => e.toJson()).toList(),
    };
  }
}

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
  final OverTimeModel? overTime;
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
  final String? remark;
  final String? approvalStatus;
  final bool? isProcessed;
  final List<ActivityModel>? activity;
  final String? createdBy;
  final String? createdAt;
  final int? updatedBy;
  final String? updatedAt;
  final ShiftModel? shift;
  final bool? onDuty;
  final bool? wfhShowPunch;
  final bool? approvalRequired;
  final bool? punchOutRemarkRequired;
  final double? grossHours;
  final double? effectiveHours;

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
    this.remark,
    this.approvalStatus,
    this.isProcessed,
    this.activity,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.shift,
    this.onDuty,
    this.wfhShowPunch,
    this.approvalRequired,
    this.punchOutRemarkRequired,
    this.grossHours,
    this.effectiveHours,
  });

  factory AttendanceDetailsModel.fromJson(Map<String, dynamic> json) {
    List<ActivityModel>? activities;
    if (json['activity'] != null && json['activity'] is List) {
      activities =
          (json['activity'] as List)
              .map(
                (item) => ActivityModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    }

    // Helper function to convert int or String to String?
    String? parseTimeValue(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      return value.toString();
    }

    // Helper function to safely parse String? fields that might be int or String
    String? parseStringValue(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    // Parse over_time which may arrive either as a structured object
    // or as a direct numeric total value.
    OverTimeModel? overTimeModel;
    if (json['over_time'] != null && json['over_time'] is Map) {
      overTimeModel = OverTimeModel.fromJson(
        json['over_time'] as Map<String, dynamic>,
      );
    } else if (json['over_time'] is num) {
      overTimeModel = OverTimeModel(
        total: (json['over_time'] as num).toInt(),
        beforePunchIn: 0,
        afterPunchOut: 0,
      );
    }

    // Parse Shift object
    ShiftModel? shiftModel;
    if (json['Shift'] != null && json['Shift'] is Map) {
      shiftModel = ShiftModel.fromJson(json['Shift'] as Map<String, dynamic>);
    }

    // Parse gross_hours and effective_hours (can be int or double)
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return AttendanceDetailsModel(
      id: json['id'] as int?,
      clientId: json['client_id'] as int?,
      userId: json['user_id'] as int?,
      date: parseStringValue(json['date']),
      punchIn: parseStringValue(json['punch_in']),
      punchOut: parseStringValue(json['punch_out']),
      totalTime: parseTimeValue(json['total_time']),
      breakTime: parseTimeValue(json['break_time']),
      overTime: overTimeModel,
      punchInIp:
          parseStringValue(json['punch_in_IP']) ??
          parseStringValue(json['punch_in_ip']),
      punchOutIp: parseStringValue(json['punch_out_IP']),
      punchInLocation: parseStringValue(json['punch_in_location']),
      punchOutLocation: parseStringValue(json['punch_out_location']),
      entries: parseStringValue(json['entries']),
      isLateEntries: json['is_late_entries'] as bool?,
      shiftType: parseStringValue(json['shift_type']),
      shiftId: json['shift_id'] as int?,
      punchType: parseStringValue(json['punch_type']),
      status: parseStringValue(json['status']),
      incompleteHours: parseStringValue(json['incomplete_hours']),
      firstHalf: json['first_half'] as bool?,
      secondHalf: json['second_half'] as bool?,
      leaveType: parseStringValue(json['leave_type']),
      deductDays: parseStringValue(json['deduct_days']),
      regularizeId: json['regularize_id'] as int?,
      remark: parseStringValue(json['remark']),
      approvalStatus: parseStringValue(json['approval_status']),
      isProcessed: json['is_processed'] as bool?,
      activity: activities,
      createdBy: parseStringValue(json['created_by']),
      createdAt: parseStringValue(json['created_at']),
      updatedBy: json['updated_by'] as int?,
      updatedAt: parseStringValue(json['updated_at']),
      shift: shiftModel,
      onDuty: json['onDuty'] as bool?,
      wfhShowPunch: json['wfhShowPunch'] as bool?,
      approvalRequired: json['approval_required'] as bool?,
      punchOutRemarkRequired: json['punch_out_remark_required'] as bool?,
      grossHours: parseDouble(json['gross_hours']),
      effectiveHours: parseDouble(json['effective_hours']),
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
  String get formattedOverTime {
    if (overTime == null) return '-';
    return '${overTime!.total} (Before: ${overTime!.beforePunchIn}, After: ${overTime!.afterPunchOut})';
  }
}

/// Activity Model
class ActivityModel {
  final String? action;
  final String? activityType;
  final String? activityBy;
  final String? createdAt;
  final String? time;
  final String? penaltyMessage;
  final double? paidDays;
  final double? unPaidDays;
  final String? ip;
  final String? location;
  final String? mode;

  ActivityModel({
    this.action,
    this.activityType,
    this.activityBy,
    this.createdAt,
    this.time,
    this.penaltyMessage,
    this.paidDays,
    this.unPaidDays,
    this.ip,
    this.location,
    this.mode,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse String? fields that might be int or String
    String? parseStringValue(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return ActivityModel(
      action: parseStringValue(json['action']),
      activityType: parseStringValue(json['activity_type']),
      activityBy: parseStringValue(json['activity_by']),
      createdAt: parseStringValue(json['created_at']),
      time: parseStringValue(json['time']),
      penaltyMessage: parseStringValue(json['penaltyMessage']),
      paidDays: _parseNullableDouble(json['paidDays']),
      unPaidDays: _parseNullableDouble(json['unPaidDays']),
      ip: parseStringValue(json['ip']),
      location: parseStringValue(json['location']),
      mode: parseStringValue(json['mode']),
    );
  }
}

/// Attendance Details Response Model
class AttendanceDetailsResponse {
  final bool success;
  final String? message;
  final AttendanceDetailsModel? data;

  AttendanceDetailsResponse({required this.success, this.message, this.data});

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
