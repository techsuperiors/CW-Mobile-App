/// Represents the user's leave statistics for the current month.
///
/// Pure domain entity — no JSON parsing or framework dependencies.
class LeaveStatsEntity {
  final int workingDays;
  final int wfhDays;
  final int leaveDays;
  final int regularizeDays;
  final int onDutyDays;
  final String startDate;
  final String endDate;

  const LeaveStatsEntity({
    required this.workingDays,
    required this.wfhDays,
    required this.leaveDays,
    this.regularizeDays = 0,
    this.onDutyDays = 0,
    required this.startDate,
    required this.endDate,
  });

  /// Total days in the month (for progress ring calculation).
  int get totalDays {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 30;
    }
  }
}
