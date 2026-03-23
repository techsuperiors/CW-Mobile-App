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
  });
}
