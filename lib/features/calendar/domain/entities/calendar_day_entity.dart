/// Represents a single day's attendance status from the attendance range API.
///
/// Pure domain entity — no JSON parsing or framework dependencies.
class CalendarDayEntity {
  final String date; // local date "yyyy-MM-dd" (already converted from ISO UTC)
  final String
  status; // "Present", "Weekend", "Leave", "Holiday", "Absent", etc.
  final bool isWeekoff;
  final bool isHoliday;
  final String? holidayName;
  final String? leaveType;
  final bool isFuture;
  final String? punchIn;
  final String? punchOut;
  final bool isLateEntry; // true when is_late_entries is true
  final String? punchInMode;
  final String? punchOutMode;
  final String? actualGrossHours;
  final String? actualEffectiveHours;
  final String? actualBreakHours;
  final String? shiftDay;
  final String? shiftPunchIn;
  final String? shiftPunchOut;
  final String? shiftBreakTime;
  final String? shiftGrossHours;
  final String? shiftEffectiveHours;
  final String? overtimeHours;
  final int? lateBySeconds;
  final int? earlyBySeconds;
  final bool firstHalf;
  final bool secondHalf;

  const CalendarDayEntity({
    required this.date,
    required this.status,
    required this.isWeekoff,
    required this.isHoliday,
    this.holidayName,
    this.leaveType,
    required this.isFuture,
    this.punchIn,
    this.punchOut,
    this.isLateEntry = false,
    this.punchInMode,
    this.punchOutMode,
    this.actualGrossHours,
    this.actualEffectiveHours,
    this.actualBreakHours,
    this.shiftDay,
    this.shiftPunchIn,
    this.shiftPunchOut,
    this.shiftBreakTime,
    this.shiftGrossHours,
    this.shiftEffectiveHours,
    this.overtimeHours,
    this.lateBySeconds,
    this.earlyBySeconds,
    this.firstHalf = false,
    this.secondHalf = false,
  });
}
