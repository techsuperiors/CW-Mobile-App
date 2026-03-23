import '../../../../../../../core/utils/date_pareser.dart';

/// On-Duty request model
class OnDutyRequestModel {
  final String id;
  final num numberOfDays;
  final DateTime fromDate;
  final DateTime? toDate;
  final String reason;
  final String? subject;
  final String? requestType; // 'single', 'multiple'
  final String? startHalf;
  final String? endHalf;
  final OnDutyStatus status;
  final DateTime appliedDate;
  final String? rejectRemark;
  final bool isEligibleToApprove;

  const OnDutyRequestModel({
    required this.id,
    required this.numberOfDays,
    required this.fromDate,
    this.toDate,
    required this.reason,
    this.subject,
    this.requestType,
    this.startHalf,
    this.endHalf,
    required this.status,
    required this.appliedDate,
    this.rejectRemark,
    this.isEligibleToApprove = false,
  });

  /// Factory constructor to create from API JSON response.
  factory OnDutyRequestModel.fromJson(Map<String, dynamic> json) {
    return OnDutyRequestModel(
      id: json['id'].toString(),
      numberOfDays: json['number_of_days'] is num
          ? json['number_of_days']
          : num.tryParse(json['number_of_days']?.toString() ?? '1') ?? 1,
      fromDate: parseApiDate(json['start_date']),

      toDate: parseApiDateNullable(json['end_date']),

      reason: json['reason'] as String? ?? '',
      subject: json['subject'] as String?,
      requestType: json['request_type'] as String?,
      startHalf: json['start_half'] as String?,
      endHalf: json['end_half'] as String?,
      status: _parseStatus(json['request_status'] as String? ?? 'Pending'),
      appliedDate: parseApiDate(json['created_at']),
      rejectRemark: json['reject_remark'] as String?,
      isEligibleToApprove:
          (json['approval_eligibility'] as Map<String, dynamic>?)?['isEligible']
              as bool? ??
          false,
    );
  }

  /// Parse status string to enum.
  static OnDutyStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return OnDutyStatus.approved;
      case 'rejected':
        return OnDutyStatus.rejected;
      case 'withdrawn':
        return OnDutyStatus.withdrawn;
      case 'pending':
      default:
        return OnDutyStatus.pending;
    }
  }

  static OnDutyStatus parseStatusValue(String status) => _parseStatus(status);

  OnDutyRequestModel copyWith({
    String? id,
    num? numberOfDays,
    DateTime? fromDate,
    DateTime? toDate,
    String? reason,
    String? subject,
    String? requestType,
    String? startHalf,
    String? endHalf,
    OnDutyStatus? status,
    DateTime? appliedDate,
    String? rejectRemark,
    bool? isEligibleToApprove,
  }) {
    return OnDutyRequestModel(
      id: id ?? this.id,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      reason: reason ?? this.reason,
      subject: subject ?? this.subject,
      requestType: requestType ?? this.requestType,
      startHalf: startHalf ?? this.startHalf,
      endHalf: endHalf ?? this.endHalf,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      rejectRemark: rejectRemark ?? this.rejectRemark,
      isEligibleToApprove:
          isEligibleToApprove ?? this.isEligibleToApprove,
    );
  }

  /// Get formatted date range string
  String get dateRange {
    if (toDate == null) {
      return _formatDate(fromDate);
    }
    return '${_formatDate(fromDate)} to ${_formatDate(toDate!)}';
  }

  String _formatDate(DateTime date) {
    final shortMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${shortMonths[date.month - 1]} ${date.day}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnDutyRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// On-Duty status enum
enum OnDutyStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case OnDutyStatus.pending:
        return 'Pending';
      case OnDutyStatus.approved:
        return 'Approved';
      case OnDutyStatus.rejected:
        return 'Rejected';
      case OnDutyStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}
