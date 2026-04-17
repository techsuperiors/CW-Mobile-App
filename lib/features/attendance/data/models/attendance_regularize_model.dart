/// Attendance Regularize Request Model
class AttendanceRegularizeRequest {
  final String requestDate;
  final String requestFor; // 'checkIn', 'checkOut', 'both'
  final String modeType; // 'Remote', 'Office', etc.
  final String? checkIn; // Format: 'yyyy-MM-dd HH:mm:ss+05:30'
  final String? checkOut; // Format: 'yyyy-MM-dd HH:mm:ss+05:30'
  final String reason;
  final String? otherReason;
  final String description;
  final int userId;
  final bool isOther;
  final int? statusUpdatedBy;

  AttendanceRegularizeRequest({
    required this.requestDate,
    required this.requestFor,
    required this.modeType,
    this.checkIn,
    this.checkOut,
    required this.reason,
    this.otherReason,
    required this.description,
    required this.userId,
    required this.isOther,
    this.statusUpdatedBy,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'request_date': requestDate,
      'request_for': requestFor,
      'mode_type': modeType,
      'reason': reason,
      'description': description,
      'user_id': userId,
      'is_Other': isOther,
    };

    json['check_in'] = checkIn;
    json['check_out'] = checkOut;
    if (otherReason != null && otherReason!.trim().isNotEmpty) {
      json['other_reason'] = otherReason;
    }
    if (statusUpdatedBy != null) {
      json['status_updated_by'] = statusUpdatedBy;
    }

    return json;
  }
}

class AttendanceRegularizeUpdateRequest {
  final int id;
  final String requestFor;
  final String requestDate;
  final String checkIn;
  final String checkOut;
  final int statusUpdatedBy;
  final String description;

  AttendanceRegularizeUpdateRequest({
    required this.id,
    required this.requestFor,
    required this.requestDate,
    required this.checkIn,
    required this.checkOut,
    required this.statusUpdatedBy,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_for': requestFor,
      'request_date': requestDate,
      'check_in': checkIn,
      'check_out': checkOut,
      'status_updated_by': statusUpdatedBy,
      'description': description,
    };
  }
}

/// Attendance Regularize Response Model
class AttendanceRegularizeResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  AttendanceRegularizeResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AttendanceRegularizeResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceRegularizeResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
