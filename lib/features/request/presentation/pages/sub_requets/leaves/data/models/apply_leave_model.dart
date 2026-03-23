import '../../domain/entities/apply_leave_entity.dart';

/// Request Model for Apply Leave
class ApplyLeaveRequestModel extends ApplyLeaveRequestEntity {
  const ApplyLeaveRequestModel({
    required super.leaveType,
    required super.clubing,
    required super.isClubbing,
    required super.startDate,
    required super.endDate,
    required super.subject,
    required super.reason,
    required super.startHalf,
    required super.endHalf,
    required super.dayType,
    required super.description,
    required super.shortCode,
    required super.requestTo,
    required super.rHDates,
  });

  /// Factory from Entity
  factory ApplyLeaveRequestModel.fromEntity(ApplyLeaveRequestEntity entity) {
    return ApplyLeaveRequestModel(
      leaveType: entity.leaveType,
      clubing: entity.clubing,
      isClubbing: entity.isClubbing,
      startDate: entity.startDate,
      endDate: entity.endDate,
      subject: entity.subject,
      reason: entity.reason,
      startHalf: entity.startHalf,
      endHalf: entity.endHalf,
      dayType: entity.dayType,
      description: entity.description,
      shortCode: entity.shortCode,
      requestTo: entity.requestTo,
      rHDates: entity.rHDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leave_type': leaveType,
      'clubing': clubing,
      'is_clubbing': isClubbing,
      'start_date': startDate,
      'end_date': endDate,
      'subject': subject,
      'reason': reason,
      'start_half': startHalf,
      'end_half': endHalf,
      'day_type': dayType,
      'description': description,
      'short_code': shortCode,
      'request_to': requestTo,
      'RH_dates': rHDates,
    };
  }
}

/// Response Model for Apply Leave
class ApplyLeaveResponseModel extends ApplyLeaveResponseEntity {
  const ApplyLeaveResponseModel({
    required super.success,
    required super.message,
    super.data,
  });

  factory ApplyLeaveResponseModel.fromJson(Map<String, dynamic> json) {
    return ApplyLeaveResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'],
    );
  }
}
