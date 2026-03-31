import '../../domain/entities/calendar_day_entity.dart';

/// Data model extending the domain entity with JSON parsing capability.
///
/// Maps the new `/api/attendance/range` response to the domain entity.
/// KEY: API dates are UTC ISO strings (e.g. "2026-03-01T18:30:00.000Z")
/// which in IST (+5:30) equal the NEXT calendar day (2026-03-02).
/// We parse and convert to local date so the widget date-lookup is correct.
class CalendarDayModel extends CalendarDayEntity {
  const CalendarDayModel({
    required super.date,
    required super.status,
    required super.isWeekoff,
    required super.isHoliday,
    super.holidayName,
    super.leaveType,
    required super.isFuture,
    super.punchIn,
    super.punchOut,
    super.isLateEntry,
    super.punchInMode,
    super.punchOutMode,
    super.actualGrossHours,
    super.actualEffectiveHours,
    super.actualBreakHours,
    super.shiftDay,
    super.shiftPunchIn,
    super.shiftPunchOut,
    super.shiftBreakTime,
    super.shiftGrossHours,
    super.shiftEffectiveHours,
    super.overtimeHours,
    super.lateBySeconds,
    super.earlyBySeconds,
    super.firstHalf,
    super.secondHalf,
  });

  /// Factory constructor to create a [CalendarDayModel] from the new API JSON.
  factory CalendarDayModel.fromJson(Map<String, dynamic> json) {
    // Parse holidayName from the holidayDetails list if available
    String? holidayName;
    final holidayDetails = json['holidayDetails'];
    if (holidayDetails is List && holidayDetails.isNotEmpty) {
      final firstDetail = holidayDetails.first;
      if (firstDetail is Map<String, dynamic>) {
        holidayName = firstDetail['holiday_name'] as String?;
      }
    }

    // Convert UTC ISO date string → local date string "yyyy-MM-dd"
    // e.g. "2026-03-01T18:30:00.000Z" (UTC) = "2026-03-02" in IST
    String localDateStr = '';
    final rawDate = json['date'] as String?;
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        final utcDate = DateTime.parse(rawDate).toLocal();
        localDateStr =
            '${utcDate.year}-${utcDate.month.toString().padLeft(2, '0')}-${utcDate.day.toString().padLeft(2, '0')}';
      } catch (_) {
        localDateStr = rawDate;
      }
    }

    final shiftTiming = json['shift_timing'];
    final overtime = json['over_time'];

    return CalendarDayModel(
      date: localDateStr,
      status: json['status'] as String? ?? '',
      isWeekoff: json['weekoff'] as bool? ?? false,
      isHoliday: json['holiday'] as bool? ?? false,
      holidayName: holidayName,
      leaveType: json['leave_type'] as String?,
      isFuture: json['isFuture'] as bool? ?? false,
      punchIn: json['punch_in'] as String?,
      punchOut: json['punch_out'] as String?,
      isLateEntry: json['is_late_entries'] as bool? ?? false,
      punchInMode: json['punch_in_mode'] as String?,
      punchOutMode: json['punch_out_mode'] as String?,
      actualGrossHours: json['actual_gross_hrs']?.toString(),
      actualEffectiveHours: json['actual_effective_hrs']?.toString(),
      actualBreakHours: json['actual_break_time']?.toString(),
      shiftDay:
          shiftTiming is Map<String, dynamic>
              ? shiftTiming['day'] as String?
              : null,
      shiftPunchIn:
          shiftTiming is Map<String, dynamic>
              ? shiftTiming['punch_in'] as String?
              : null,
      shiftPunchOut:
          shiftTiming is Map<String, dynamic>
              ? shiftTiming['punch_out'] as String?
              : null,
      shiftBreakTime:
          shiftTiming is Map<String, dynamic>
              ? shiftTiming['break_time'] as String?
              : null,
      shiftGrossHours:
          shiftTiming is Map<String, dynamic>
              ? shiftTiming['gross_hours'] as String?
              : null,
      shiftEffectiveHours:
          shiftTiming is Map<String, dynamic>
              ? shiftTiming['effective_hours'] as String?
              : null,
      overtimeHours:
          overtime is Map<String, dynamic>
              ? overtime['total']?.toString()
              : overtime?.toString(),
      lateBySeconds: json['lateInSeconds'] as int?,
      earlyBySeconds: json['earlyInSeconds'] as int?,
      firstHalf: json['first_half'] as bool? ?? false,
      secondHalf: json['second_half'] as bool? ?? false,
    );
  }
}
