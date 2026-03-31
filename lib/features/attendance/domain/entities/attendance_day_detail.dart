class AttendanceDayLog {
  final String? punchIn;
  final String? punchOut;
  final String? activityAction;
  final String? activityType;
  final String? time;
  final String? activityBy;
  final String? location;

  const AttendanceDayLog({
    this.punchIn,
    this.punchOut,
    this.activityAction,
    this.activityType,
    this.time,
    this.activityBy,
    this.location,
  });
}

class AttendanceDayShiftTiming {
  final String day;
  final String punchIn;
  final String punchOut;
  final String breakTime;
  final String grossHours;
  final String effectiveHours;

  const AttendanceDayShiftTiming({
    required this.day,
    required this.punchIn,
    required this.punchOut,
    required this.breakTime,
    required this.grossHours,
    required this.effectiveHours,
  });
}

class AttendanceDayOvertime {
  final int total;
  final int beforePunchIn;
  final int afterPunchOut;

  const AttendanceDayOvertime({
    required this.total,
    required this.beforePunchIn,
    required this.afterPunchOut,
  });
}

class AttendanceDayDetail {
  final String? day;
  final String? date;
  final bool holiday;
  final String? holidayName;
  final bool weekOff;
  final String? punchIn;
  final String? punchOut;
  final bool isLateEntries;
  final String? status;
  final String? leaveType;
  final bool firstHalf;
  final bool secondHalf;
  final String? shiftName;
  final AttendanceDayShiftTiming? shiftTiming;
  final List<AttendanceDayLog> dayLogs;
  final int? actualGrossHrs;
  final String? actualEffectiveHrs;
  final String? actualBreakTime;
  final bool isRegularized;
  final String? regularizePunchIn;
  final String? regularizePunchOut;
  final String? incompleteHours;
  final AttendanceDayOvertime? overTime;
  final bool isManualAttendance;
  final String? manualPunchIn;
  final String? manualPunchOut;
  final bool? approvalRequired;
  final bool? punchOutRemarkRequired;
  final String? remark;
  final String? approvalStatus;

  const AttendanceDayDetail({
    this.day,
    this.date,
    required this.holiday,
    this.holidayName,
    required this.weekOff,
    this.punchIn,
    this.punchOut,
    required this.isLateEntries,
    this.status,
    this.leaveType,
    required this.firstHalf,
    required this.secondHalf,
    this.shiftName,
    this.shiftTiming,
    this.dayLogs = const [],
    this.actualGrossHrs,
    this.actualEffectiveHrs,
    this.actualBreakTime,
    required this.isRegularized,
    this.regularizePunchIn,
    this.regularizePunchOut,
    this.incompleteHours,
    this.overTime,
    required this.isManualAttendance,
    this.manualPunchIn,
    this.manualPunchOut,
    this.approvalRequired,
    this.punchOutRemarkRequired,
    this.remark,
    this.approvalStatus,
  });
}
