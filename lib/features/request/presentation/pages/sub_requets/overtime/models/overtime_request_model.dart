import 'package:equatable/equatable.dart';

import '../../../../../../../core/utils/date_pareser.dart';

class OvertimeRequestModel extends Equatable {
  final String id;
  final String subject;
  final DateTime requestDate;
  final OvertimeStatus status;
  final DateTime appliedDate;
  final bool isEligibleToApprove;

  const OvertimeRequestModel({
    required this.id,
    required this.subject,
    required this.requestDate,
    required this.status,
    required this.appliedDate,
    this.isEligibleToApprove = false,
  });

  factory OvertimeRequestModel.fromJson(Map<String, dynamic> json) {
    return OvertimeRequestModel(
      id: json['id'].toString(),
      subject: json['subject'] as String? ?? '',
      requestDate: parseApiDate(json['request_date']),
      status: parseStatusValue(json['status'] as String? ?? 'Pending'),
      appliedDate: parseApiDate(json['created_at']),
      isEligibleToApprove:
          (json['approval_eligibility'] as Map<String, dynamic>?)?['isEligible']
              as bool? ??
          false,
    );
  }

  OvertimeRequestModel copyWith({
    String? id,
    String? subject,
    DateTime? requestDate,
    OvertimeStatus? status,
    DateTime? appliedDate,
    bool? isEligibleToApprove,
  }) {
    return OvertimeRequestModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      requestDate: requestDate ?? this.requestDate,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      isEligibleToApprove:
          isEligibleToApprove ?? this.isEligibleToApprove,
    );
  }

  static OvertimeStatus parseStatusValue(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return OvertimeStatus.approved;
      case 'rejected':
        return OvertimeStatus.rejected;
      case 'withdrawn':
        return OvertimeStatus.withdrawn;
      case 'pending':
      default:
        return OvertimeStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
    id,
    subject,
    requestDate,
    status,
    appliedDate,
    isEligibleToApprove,
  ];
}

enum OvertimeStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case OvertimeStatus.pending:
        return 'Pending';
      case OvertimeStatus.approved:
        return 'Approved';
      case OvertimeStatus.rejected:
        return 'Rejected';
      case OvertimeStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}
