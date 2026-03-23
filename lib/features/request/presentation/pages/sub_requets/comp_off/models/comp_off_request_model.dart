import 'package:equatable/equatable.dart';

import '../../../../../../../core/utils/date_pareser.dart';

class CompOffRequestModel extends Equatable {
  final String id;
  final String type; // Day / Hours
  final DateTime date;
  final String duration;
  final String subject;
  final String reason;
  final CompOffStatus status;
  final DateTime createdAt;
  final bool isEligibleToApprove;

  const CompOffRequestModel({
    required this.id,
    required this.type,
    required this.date,
    required this.duration,
    required this.subject,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.isEligibleToApprove = false,
  });

  factory CompOffRequestModel.fromJson(Map<String, dynamic> json) {
    return CompOffRequestModel(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'Day',
      date: parseApiDate(json['date']),
      duration: json['duration']?.toString() ?? '',
      subject: json['subject'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: _parseStatus(json['status'] as String? ?? 'Pending'),
      createdAt: parseApiDate(json['created_at']),
      isEligibleToApprove:
          (json['approval_eligibility'] as Map<String, dynamic>?)?['isEligible']
              as bool? ??
          false,
    );
  }

  CompOffRequestModel copyWith({
    String? id,
    String? type,
    DateTime? date,
    String? duration,
    String? subject,
    String? reason,
    CompOffStatus? status,
    DateTime? createdAt,
    bool? isEligibleToApprove,
  }) {
    return CompOffRequestModel(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      subject: subject ?? this.subject,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isEligibleToApprove:
          isEligibleToApprove ?? this.isEligibleToApprove,
    );
  }

  static CompOffStatus _parseStatus(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return CompOffStatus.approved;
      case 'rejected':
        return CompOffStatus.rejected;
      case 'withdrawn':
        return CompOffStatus.withdrawn;
      case 'pending':
      default:
        return CompOffStatus.pending;
    }
  }

  static CompOffStatus parseStatusValue(String value) => _parseStatus(value);

  @override
  List<Object?> get props => [
        id,
        type,
        date,
        duration,
        subject,
        reason,
        status,
        createdAt,
        isEligibleToApprove,
      ];
}

enum CompOffStatus { pending, approved, rejected, withdrawn }
