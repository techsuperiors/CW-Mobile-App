import '../../domain/entities/leave_stats_entity.dart';

/// Data model with JSON parsing for leave stats API response.
class LeaveStatsModel extends LeaveStatsEntity {
  const LeaveStatsModel({
    required super.workingDays,
    required super.wfhDays,
    required super.leaveDays,
    required super.startDate,
    required super.endDate,
  });

  factory LeaveStatsModel.fromJson(Map<String, dynamic> json) {
    return LeaveStatsModel(
      workingDays: (json['working_days'] as num?)?.toInt() ?? 0,
      wfhDays: (json['wfh_days'] as num?)?.toInt() ?? 0,
      leaveDays: (json['leave_days'] as num?)?.toInt() ?? 0,
      startDate: json['start_date'] as String? ?? '',
      endDate: json['end_date'] as String? ?? '',
    );
  }
}
