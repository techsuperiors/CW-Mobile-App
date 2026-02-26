/// OverTime Entity
class OverTime {
  final int total;
  final int beforePunchIn;
  final int afterPunchOut;

  OverTime({
    required this.total,
    required this.beforePunchIn,
    required this.afterPunchOut,
  });
}

/// Shift Day Timing Entity
class ShiftDayTiming {
  final String day;
  final String punchIn;
  final String punchOut;
  final String breakTime;
  final String grossHours;
  final String effectiveHours;

  ShiftDayTiming({
    required this.day,
    required this.punchIn,
    required this.punchOut,
    required this.breakTime,
    required this.grossHours,
    required this.effectiveHours,
  });
}

/// Weekly Off Day Entity
class WeeklyOffDay {
  final String day;
  final String offType;
  final bool selectedDay;
  final List<String> weeklyOccurrence;

  WeeklyOffDay({
    required this.day,
    required this.offType,
    required this.selectedDay,
    required this.weeklyOccurrence,
  });
}

/// Shift Entity
class Shift {
  final int id;
  final List<ShiftDayTiming> shiftDayTiming;
  final List<WeeklyOffDay> weeklyOffDays;

  Shift({
    required this.id,
    required this.shiftDayTiming,
    required this.weeklyOffDays,
  });
}

/// Activity Entity
class Activity {
  final String? action;
  final String? activityType;
  final String? activityBy;
  final String? createdAt;
  final String? time;
  final String? penaltyMessage;
  final int? paidDays;
  final int? unPaidDays;
  final String? ip;
  final String? location;
  final String? mode;

  Activity({
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
}

/// Attendance Details Entity
class AttendanceDetails {
  final int? id;
  final int? clientId;
  final int? userId;
  final String? date;
  final String? punchIn;
  final String? punchOut;
  final String? totalTime;
  final String? breakTime;
  final OverTime? overTime;
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
  final List<Activity>? activity;
  final String? createdBy;
  final String? createdAt;
  final int? updatedBy;
  final String? updatedAt;
  final Shift? shift;
  final bool? onDuty;
  final bool? wfhShowPunch;
  final bool? approvalRequired;
  final bool? punchOutRemarkRequired;
  final double? grossHours;
  final double? effectiveHours;

  // Formatted getters
  final String formattedPunchIn;
  final String formattedPunchOut;
  final String formattedBreakTime;
  final String formattedOverTime;

  AttendanceDetails({
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
    required this.formattedPunchIn,
    required this.formattedPunchOut,
    required this.formattedBreakTime,
    required this.formattedOverTime,
  });
}
