import '../../domain/entities/attendance_day_detail.dart';

class AttendanceDayLogModel {
  final String? punchIn;
  final String? punchOut;

  const AttendanceDayLogModel({this.punchIn, this.punchOut});

  factory AttendanceDayLogModel.fromJson(Map<String, dynamic> json) {
    return AttendanceDayLogModel(
      punchIn: json['punch_in']?.toString(),
      punchOut: json['punch_out']?.toString(),
    );
  }

  AttendanceDayLog toEntity() {
    return AttendanceDayLog(punchIn: punchIn, punchOut: punchOut);
  }
}

class AttendanceDayShiftTimingModel {
  final String day;
  final String punchIn;
  final String punchOut;
  final String breakTime;
  final String grossHours;
  final String effectiveHours;

  const AttendanceDayShiftTimingModel({
    required this.day,
    required this.punchIn,
    required this.punchOut,
    required this.breakTime,
    required this.grossHours,
    required this.effectiveHours,
  });

  factory AttendanceDayShiftTimingModel.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    return AttendanceDayShiftTimingModel(
      day: parseString(json['day']),
      punchIn: parseString(json['punch_in']),
      punchOut: parseString(json['punch_out']),
      breakTime: parseString(json['break_time']),
      grossHours: parseString(json['gross_hours']),
      effectiveHours: parseString(json['effective_hours']),
    );
  }

  AttendanceDayShiftTiming toEntity() {
    return AttendanceDayShiftTiming(
      day: day,
      punchIn: punchIn,
      punchOut: punchOut,
      breakTime: breakTime,
      grossHours: grossHours,
      effectiveHours: effectiveHours,
    );
  }
}

class AttendanceDayOvertimeModel {
  final int total;
  final int beforePunchIn;
  final int afterPunchOut;

  const AttendanceDayOvertimeModel({
    required this.total,
    required this.beforePunchIn,
    required this.afterPunchOut,
  });

  factory AttendanceDayOvertimeModel.fromJson(Map<String, dynamic> json) {
    return AttendanceDayOvertimeModel(
      total: json['total'] as int? ?? 0,
      beforePunchIn: json['before_punchIn'] as int? ?? 0,
      afterPunchOut: json['after_punchOut'] as int? ?? 0,
    );
  }

  AttendanceDayOvertime toEntity() {
    return AttendanceDayOvertime(
      total: total,
      beforePunchIn: beforePunchIn,
      afterPunchOut: afterPunchOut,
    );
  }
}

class AttendanceDayDetailModel {
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
  final AttendanceDayShiftTimingModel? shiftTiming;
  final List<AttendanceDayLogModel> dayLogs;
  final int? actualGrossHrs;
  final String? actualEffectiveHrs;
  final String? actualBreakTime;
  final bool isRegularized;
  final String? regularizePunchIn;
  final String? regularizePunchOut;
  final String? incompleteHours;
  final AttendanceDayOvertimeModel? overTime;
  final bool isManualAttendance;
  final String? manualPunchIn;
  final String? manualPunchOut;
  final bool? approvalRequired;
  final bool? punchOutRemarkRequired;
  final String? remark;
  final String? approvalStatus;

  const AttendanceDayDetailModel({
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

  factory AttendanceDayDetailModel.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    final rawLogs = json['day_logs'];
    final parsedLogs =
        rawLogs is List
            ? rawLogs
                .whereType<Map>()
                .map(
                  (item) => AttendanceDayLogModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
            : <AttendanceDayLogModel>[];

    return AttendanceDayDetailModel(
      day: json['day']?.toString(),
      date: json['date']?.toString(),
      holiday: json['holiday'] as bool? ?? false,
      holidayName: json['holiday_name']?.toString(),
      weekOff: json['weekOff'] as bool? ?? false,
      punchIn: json['punch_in']?.toString(),
      punchOut: json['punch_out']?.toString(),
      isLateEntries: json['is_late_entries'] as bool? ?? false,
      status: json['status']?.toString(),
      leaveType: json['leave_type']?.toString(),
      firstHalf: json['first_half'] as bool? ?? false,
      secondHalf: json['second_half'] as bool? ?? false,
      shiftName: json['shift_name']?.toString(),
      shiftTiming:
          json['shift_timing'] is Map
              ? AttendanceDayShiftTimingModel.fromJson(
                Map<String, dynamic>.from(json['shift_timing'] as Map),
              )
              : null,
      dayLogs: parsedLogs,
      actualGrossHrs: parseInt(json['actual_gross_hrs']),
      actualEffectiveHrs: json['actual_effective_hrs']?.toString(),
      actualBreakTime: json['actual_break_time']?.toString(),
      isRegularized: json['isRegularized'] as bool? ?? false,
      regularizePunchIn: json['regularize_punch_in']?.toString(),
      regularizePunchOut: json['regularize_punch_out']?.toString(),
      incompleteHours: json['incomplete_hours']?.toString(),
      overTime:
          json['over_time'] is Map
              ? AttendanceDayOvertimeModel.fromJson(
                Map<String, dynamic>.from(json['over_time'] as Map),
              )
              : null,
      isManualAttendance: json['isManualAttendance'] as bool? ?? false,
      manualPunchIn: json['manual_punch_in']?.toString(),
      manualPunchOut: json['manual_punch_out']?.toString(),
      approvalRequired: json['approval_required'] as bool?,
      punchOutRemarkRequired: json['punch_out_remark_required'] as bool?,
      remark: json['remark']?.toString(),
      approvalStatus: json['approval_status']?.toString(),
    );
  }

  AttendanceDayDetail toEntity() {
    return AttendanceDayDetail(
      day: day,
      date: date,
      holiday: holiday,
      holidayName: holidayName,
      weekOff: weekOff,
      punchIn: punchIn,
      punchOut: punchOut,
      isLateEntries: isLateEntries,
      status: status,
      leaveType: leaveType,
      firstHalf: firstHalf,
      secondHalf: secondHalf,
      shiftName: shiftName,
      shiftTiming: shiftTiming?.toEntity(),
      dayLogs: dayLogs.map((log) => log.toEntity()).toList(),
      actualGrossHrs: actualGrossHrs,
      actualEffectiveHrs: actualEffectiveHrs,
      actualBreakTime: actualBreakTime,
      isRegularized: isRegularized,
      regularizePunchIn: regularizePunchIn,
      regularizePunchOut: regularizePunchOut,
      incompleteHours: incompleteHours,
      overTime: overTime?.toEntity(),
      isManualAttendance: isManualAttendance,
      manualPunchIn: manualPunchIn,
      manualPunchOut: manualPunchOut,
      approvalRequired: approvalRequired,
      punchOutRemarkRequired: punchOutRemarkRequired,
      remark: remark,
      approvalStatus: approvalStatus,
    );
  }
}
