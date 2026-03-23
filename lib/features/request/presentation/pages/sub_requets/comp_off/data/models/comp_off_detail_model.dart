import '../../domain/entities/comp_off_detail.dart';

class CompOffApproverModel extends CompOffApprover {
  const CompOffApproverModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.email,
    super.imageUrl,
    required super.profileColor,
    required super.approvalStatus,
    super.actionDate,
  });

  factory CompOffApproverModel.fromJson(Map<String, dynamic> json) {
    return CompOffApproverModel(
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

class CompOffApprovalLevelModel extends CompOffApprovalLevel {
  const CompOffApprovalLevelModel({
    required super.level,
    required super.approvalStatus,
    required super.allApproversRequired,
    required super.users,
  });

  factory CompOffApprovalLevelModel.fromJson(Map<String, dynamic> json) {
    final users = (json['users'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CompOffApproverModel.fromJson)
        .toList();

    return CompOffApprovalLevelModel(
      level: json['level']?.toString() ?? '1',
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      allApproversRequired: json['all_approvers_required'] as bool? ?? false,
      users: users,
    );
  }
}

class CompOffActivityModel extends CompOffActivity {
  const CompOffActivityModel({
    required super.action,
    required super.actionType,
    required super.firstName,
    required super.lastName,
    required super.userEmail,
    super.createdBy,
    super.createdAt,
  });

  factory CompOffActivityModel.fromJson(Map<String, dynamic> json) {
    return CompOffActivityModel(
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

class CompOffDetailModel extends CompOffDetail {
  const CompOffDetailModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.subject,
    required super.date,
    required super.duration,
    required super.year,
    required super.reason,
    required super.requestTo,
    super.requestByName,
    super.requestToName,
    super.requestByImage,
    super.requestToImage,
    super.requestByColor,
    super.requestToColor,
    required super.status,
    required super.createdAt,
    required super.approvers,
    required super.activity,
  });

  factory CompOffDetailModel.fromResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final activity = (data['activity'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CompOffActivityModel.fromJson)
        .toList();
    final approvers = (data['approvers'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CompOffApprovalLevelModel.fromJson)
        .toList();

    final requestedBy = data['CompOffRequestedBy'] as Map<String, dynamic>?;
    final requestedTo = data['CompOffRequestedTo'] as Map<String, dynamic>?;

    return CompOffDetailModel(
      id: _safeInt(data['id']),
      userId: _safeInt(data['user_id']),
      type: data['type'] as String? ?? 'Day',
      subject: data['subject'] as String? ?? '',
      date: _parseDate(data['date']),
      duration: data['duration']?.toString() ?? '',
      year: data['year']?.toString() ?? '',
      reason: data['reason'] as String? ?? '',
      requestTo: _nullableInt(data['request_to']),
      requestByName: _fullName(requestedBy),
      requestToName: _fullName(requestedTo),
      requestByImage: requestedBy?['image_url'] as String?,
      requestToImage: requestedTo?['image_url'] as String?,
      requestByColor: requestedBy?['profile_color'] as String?,
      requestToColor: requestedTo?['profile_color'] as String?,
      status: data['status'] as String? ?? 'Pending',
      createdAt: _parseDate(data['created_at']),
      approvers: approvers,
      activity: activity,
    );
  }
}

String? _fullName(Map<String, dynamic>? json) {
  if (json == null) return null;
  final first = json['first_name'] as String? ?? '';
  final last = json['last_name'] as String? ?? '';
  final name = '$first $last'.trim();
  return name.isNotEmpty ? name : null;
}

int _safeInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
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
