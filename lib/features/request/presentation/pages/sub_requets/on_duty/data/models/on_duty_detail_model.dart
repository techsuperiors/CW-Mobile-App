import '../../domain/entities/on_duty_detail.dart';

class OnDutyApproverModel extends OnDutyApprover {
  const OnDutyApproverModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.email,
    super.imageUrl,
    super.profileColor,
    required super.approvalStatus,
    super.actionDate,
  });

  factory OnDutyApproverModel.fromJson(Map<String, dynamic> json) {
    return OnDutyApproverModel(
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

class OnDutyApprovalLevelModel extends OnDutyApprovalLevel {
  const OnDutyApprovalLevelModel({
    required super.level,
    required super.approvalStatus,
    required super.allApproversRequired,
    required super.users,
  });

  factory OnDutyApprovalLevelModel.fromJson(Map<String, dynamic> json) {
    final users =
        (json['users'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(OnDutyApproverModel.fromJson)
            .toList();

    return OnDutyApprovalLevelModel(
      level: json['level']?.toString() ?? '1',
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      allApproversRequired: json['all_approvers_required'] as bool? ?? false,
      users: users,
    );
  }
}

class OnDutyActivityModel extends OnDutyActivity {
  const OnDutyActivityModel({
    required super.action,
    required super.actionType,
    required super.firstName,
    required super.lastName,
    required super.userEmail,
    super.createdBy,
    super.createdAt,
  });

  factory OnDutyActivityModel.fromJson(Map<String, dynamic> json) {
    return OnDutyActivityModel(
      action: json['action'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      userEmail: json['user_email'] as String? ?? '',
      createdBy: _safeInt(json['created_by']),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class OnDutyDetailModel extends OnDutyDetail {
  const OnDutyDetailModel({
    required super.id,
    required super.userId,
    required super.requestFor,
    required super.startDate,
    required super.startHalf,
    required super.endDate,
    required super.endHalf,
    required super.requestType,
    required super.reason,
    required super.subject,
    required super.description,
    required super.rejectRemark,
    required super.numberOfDays,
    required super.requestStatus,
    required super.createdAt,
    required super.updatedAt,
    required super.approvers,
    required super.activity,
  });

  factory OnDutyDetailModel.fromResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final activityList = (data['activity'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OnDutyActivityModel.fromJson)
        .toList();
    final approvers = (data['approvers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OnDutyApprovalLevelModel.fromJson)
        .toList();

    return OnDutyDetailModel(
      id: _safeInt(data['id']),
      userId: _safeInt(data['user_id']),
      requestFor: _nullableInt(data['request_for']),
      startDate: _parseDate(data['start_date']),
      startHalf: data['start_half'] as String?,
      endDate: _parseDate(data['end_date']),
      endHalf: data['end_half'] as String?,
      requestType: data['request_type'] as String? ?? 'single',
      reason: data['reason'] as String?,
      subject: data['subject'] as String?,
      description: data['description'] as String?,
      rejectRemark: data['reject_remark'] as String?,
      numberOfDays: _safeNum(data['number_of_days'], fallback: 1.0),
      requestStatus: data['request_status'] as String? ?? 'Pending',
      createdAt: _parseDate(data['created_at']),
      updatedAt: _parseDate(data['updated_at']),
      approvers: approvers,
      activity: activityList,
    );
  }
}
num _safeNum(dynamic value, {num fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? fallback;
  return fallback;
}
int _safeInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
