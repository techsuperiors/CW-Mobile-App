import '../../domain/entities/attendance_request_comment.dart';

int _safeInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

class AttendanceRequestCommentUserModel extends AttendanceRequestCommentUser {
  const AttendanceRequestCommentUserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.imageUrl,
    super.profileColor,
  });

  factory AttendanceRequestCommentUserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AttendanceRequestCommentUserModel(
      id: _safeInt(json['id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
    );
  }
}

class AttendanceRequestCommentModel extends AttendanceRequestComment {
  const AttendanceRequestCommentModel({
    required super.id,
    required super.requestId,
    required super.comment,
    required super.type,
    required super.status,
    required super.createdBy,
    required super.createdAt,
    required super.user,
  });

  factory AttendanceRequestCommentModel.fromJson(Map<String, dynamic> json) {
    // final userJson = json['requestCommentCreatedBy'];
    ///For handling comment of comp-off and all other requests
    final userJson = json['requestCommentCreatedBy'] ??
        json['compOffCommentCreatedBy'] ??
        json['leaveCommentCreatedBy'] ??
        json['wfhCommentCreatedBy'] ??
        json['onDutyCommentCreatedBy'];
    return AttendanceRequestCommentModel(
      id: _safeInt(json['id']),
      requestId: _safeInt(json['request_id']),
      comment: json['comment'] as String? ?? '',
      type: json['type'] as String? ?? 'Attendance',
      status: json['status'] as String? ?? 'Active',
      createdBy: _safeInt(json['created_by']),
      createdAt: _parseDate(json['created_at']),
      user:
          userJson is Map<String, dynamic>
              ? AttendanceRequestCommentUserModel.fromJson(userJson)
              : null,
    );
  }
}

List<AttendanceRequestComment> parseAttendanceRequestComments(
  Map<String, dynamic> json,
) {
  final rawList = json['data'] as List<dynamic>? ?? const [];
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(AttendanceRequestCommentModel.fromJson)
      .toList();
}
