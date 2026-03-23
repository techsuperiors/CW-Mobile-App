/// Attendance Regularize Request Model
class AttendanceRegularizeRequest {
  final String requestDate;
  final int requestTo;
  final String requestFor; // 'Punch-In', 'Punch-Out', 'both'
  final String modeType; // 'Remote', 'Office', etc.
  final String checkIn; // Format: 'yyyy-MM-dd HH:mm:ss+05:30'
  final String checkOut; // Format: 'yyyy-MM-dd HH:mm:ss+05:30'
  final String reason;
  final String description;
  final int userId;
  final bool isOther;
  final int statusUpdatedBy;

  AttendanceRegularizeRequest({
    required this.requestDate,
    required this.requestTo,
    required this.requestFor,
    required this.modeType,
    required this.checkIn,
    required this.checkOut,
    required this.reason,
    required this.description,
    required this.userId,
    required this.isOther,
    required this.statusUpdatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'request_date': requestDate,
      'request_to': requestTo,
      'request_for': requestFor,
      'mode_type': modeType,
      'check_in': checkIn,
      'check_out': checkOut,
      'reason': reason,
      'description': description,
      'user_id': userId,
      'is_Other': isOther,
      'status_updated_by': statusUpdatedBy,
    };
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
