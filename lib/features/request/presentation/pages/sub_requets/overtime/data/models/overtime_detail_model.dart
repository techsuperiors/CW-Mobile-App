import '../../domain/entities/overtime_detail.dart';

class OvertimeApproverModel extends OvertimeApprover {
  const OvertimeApproverModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.email,
    super.imageUrl,
    required super.profileColor,
    required super.approvalStatus,
    super.actionDate,
  });

  factory OvertimeApproverModel.fromJson(Map<String, dynamic> json) {
    return OvertimeApproverModel(
      id: _safeInt(json['id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String? ?? '#667085',
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      actionDate: _parseDate(json['action_date']),
    );
  }
}

class OvertimeApprovalLevelModel extends OvertimeApprovalLevel {
  const OvertimeApprovalLevelModel({
    required super.level,
    required super.approvalStatus,
    required super.allApproversRequired,
    required super.users,
  });

  factory OvertimeApprovalLevelModel.fromJson(Map<String, dynamic> json) {
    final users = (json['users'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OvertimeApproverModel.fromJson)
        .toList();

    return OvertimeApprovalLevelModel(
      level: json['level']?.toString() ?? '1',
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      allApproversRequired: json['all_approvers_required'] as bool? ?? false,
      users: users,
    );
  }
}

class OvertimeActivityModel extends OvertimeActivity {
  const OvertimeActivityModel({
    required super.action,
    required super.actionType,
    required super.firstName,
    required super.lastName,
    required super.userEmail,
    super.createdBy,
    super.createdAt,
  });

  factory OvertimeActivityModel.fromJson(Map<String, dynamic> json) {
    return OvertimeActivityModel(
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

class OvertimeDetailModel extends OvertimeDetail {
  const OvertimeDetailModel({
    required super.id,
    required super.userId,
    required super.subject,
    required super.description,
    required super.requestDate,
    required super.checkIn,
    required super.checkOut,
    required super.totalHours,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required super.approvers,
    required super.activity,
  });

  factory OvertimeDetailModel.fromResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final activity = (data['activity'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OvertimeActivityModel.fromJson)
        .toList();
    final approvers = (data['approvers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OvertimeApprovalLevelModel.fromJson)
        .toList();

    return OvertimeDetailModel(
      id: _safeInt(data['id']),
      userId: _safeInt(data['user_id']),
      subject: data['subject'] as String? ?? '',
      description: data['description'] as String?,
      requestDate: _parseDate(data['request_date']),
      checkIn: _parseDate(data['check_in']),
      checkOut: _parseDate(data['check_out']),
      totalHours: data['total_hours']?.toString() ?? '0',
      status: data['status'] as String? ?? 'Pending',
      createdAt: _parseDate(data['created_at']),
      updatedAt: _parseDate(data['updated_at']),
      approvers: approvers,
      activity: activity,
    );
  }
}

int _safeInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
