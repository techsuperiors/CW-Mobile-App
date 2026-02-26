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
  final String? createdBy;
  final String? createdAt;
  final String? updatedBy;
  final String? updatedAt;
  final bool? onDuty;
  final bool? wfhShowPunch;

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
    this.isProcessed,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.onDuty,
    this.wfhShowPunch,
    required this.formattedPunchIn,
    required this.formattedPunchOut,
    required this.formattedBreakTime,
    required this.formattedOverTime,
  });
}

