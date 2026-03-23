import '../../domain/entities/leave_history_entity.dart';

/// Data model mapping JSON response to LeaveHistoryEntity
class LeaveHistoryModel extends LeaveHistoryEntity {
  const LeaveHistoryModel({
    required super.leaveType,
    required super.action,
    required super.leaveCount,
    required super.remainingLeaves,
    required super.userId,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.profileUrl,
    required super.profileColor,
    required super.date,
    required super.remarks,
    required super.performedBy,
  });

  /// Factory constructor to create from API JSON response.
  factory LeaveHistoryModel.fromJson(Map<String, dynamic> json) {
    return LeaveHistoryModel(
      leaveType: json['leave_type'] as String? ?? 'Leave',
      action: json['action'] as String? ?? 'Update',
      leaveCount: (json['leave_count'] as num?)?.toDouble() ?? 0.0,
      remainingLeaves: (json['remaining_leaves'] as num?)?.toDouble() ?? 0.0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? 'User',
      lastName: json['last_name'] as String? ?? '',
      profileUrl: json['profile_url'] as String? ?? '',
      profileColor: json['profile_color'] as String? ?? '#000000',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      remarks: json['remarks'] as String? ?? '',
      performedBy: json['performed_by'] as String? ?? 'System',
    );
  }
}
