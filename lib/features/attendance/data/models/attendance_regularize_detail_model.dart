import '../../domain/entities/attendance_regularize_detail.dart';

class AttendanceRegularizeApproverModel extends AttendanceRegularizeApprover {
  const AttendanceRegularizeApproverModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.email,
    super.imageUrl,
    super.profileColor,
    required super.approvalStatus,
    super.actionDate,
  });

  factory AttendanceRegularizeApproverModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceRegularizeApproverModel(
      id: _safeInt(json['id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      actionDate: _parseDate(json['action_date']),
    );
  }
}

class AttendanceRegularizeApprovalLevelModel
    extends AttendanceRegularizeApprovalLevel {
  const AttendanceRegularizeApprovalLevelModel({
    required super.level,
    required super.approvalStatus,
    required super.allApproversRequired,
    required super.users,
  });

  factory AttendanceRegularizeApprovalLevelModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final users =
        (json['users'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AttendanceRegularizeApproverModel.fromJson)
            .toList();

    return AttendanceRegularizeApprovalLevelModel(
      level: json['level']?.toString() ?? '1',
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      allApproversRequired: json['all_approvers_required'] as bool? ?? false,
      users: users,
    );
  }
}

class AttendanceRegularizeActivityModel extends AttendanceRegularizeActivity {
  const AttendanceRegularizeActivityModel({
    required super.action,
    required super.actionType,
    required super.firstName,
    required super.lastName,
    required super.userEmail,
    super.createdBy,
    super.createdAt,
  });

  factory AttendanceRegularizeActivityModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceRegularizeActivityModel(
      action: json['action'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      createdBy: _safeIntNullable(json['created_by']),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class AttendanceRegularizeDetailModel extends AttendanceRegularizeDetail {
  const AttendanceRegularizeDetailModel({
    required super.id,
    required super.requestDate,
    required super.checkIn,
    required super.checkOut,
    required super.reason,
    required super.description,
    required super.requestStatus,
    required super.requestFor,
    required super.rejectRemark,
    required super.modeType,
    required super.createdAt,
    required super.updatedAt,
    required super.approvers,
    required super.activity,
  });

  factory AttendanceRegularizeDetailModel.fromResponse(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final activityList =
        (data['activity'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AttendanceRegularizeActivityModel.fromJson)
            .toList();
    final approvers =
        (data['approvers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AttendanceRegularizeApprovalLevelModel.fromJson)
            .toList();

    return AttendanceRegularizeDetailModel(
      id: data['id'] as int? ?? 0,
      requestDate: _parseDate(data['request_date']),
      checkIn: _parseDate(data['check_in']),
      checkOut: _parseDate(data['check_out']),
      reason: data['reason'] as String? ?? '',
      description: data['description'] as String?,
      requestStatus: data['request_status'] as String? ?? 'Pending',
      requestFor: data['request_for'] as String? ?? 'both',
      rejectRemark: data['reject_remark'] as String?,
      modeType: data['mode_type'] as String?,
      createdAt: _parseDate(data['created_at']),
      updatedAt: _parseDate(data['updated_at']),
      approvers: approvers,
      activity: activityList,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

int _safeInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _safeIntNullable(dynamic value) {
  if (value == null) return null;
  return _safeInt(value);
}
