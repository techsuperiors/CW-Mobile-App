/// WFH request model
class WfhApproverSnapshot {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;

  const WfhApproverSnapshot({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory WfhApproverSnapshot.fromJson(Map<String, dynamic> json) {
    return WfhApproverSnapshot(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
    );
  }
}

class WfhRequestModel {
  final String id;
  final int numberOfDays;
  final DateTime fromDate;
  final DateTime? toDate; // null for single day WFH
  final String reason;
  final String? subject;
  final String? requestType; // 'single', 'multiple'
  final WfhStatus status;
  final DateTime appliedDate;
  final String? rejectRemark;
  final bool? isAnywhere;
  final String? attendanceRequestId; // Often needed for Withdraw/mutations
  final bool isEligibleToApprove;
  final List<WfhApproverSnapshot> approvers;

  const WfhRequestModel({
    required this.id,
    required this.numberOfDays,
    required this.fromDate,
    this.toDate,
    required this.reason,
    this.subject,
    this.requestType,
    required this.status,
    required this.appliedDate,
    this.rejectRemark,
    this.isAnywhere,
    this.attendanceRequestId,
    this.isEligibleToApprove = false,
    this.approvers = const [],
  });

  /// Factory constructor to create from API JSON response.
  factory WfhRequestModel.fromJson(Map<String, dynamic> json) {
    final approvers =
        (json['approvers'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .expand(
              (level) => (level['users'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .map(WfhApproverSnapshot.fromJson),
            )
            .toList();

    return WfhRequestModel(
      id: json['id'].toString(),
      numberOfDays: (json['number_of_days'] as num?)?.toInt() ?? 1,
      fromDate:
      (DateTime.tryParse(json['start_date'] ?? '')?.toLocal()) ??
          DateTime.now(),

      toDate:
      json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])?.toLocal()
          : null,

      reason: json['reason'] as String? ?? '',
      subject: json['subject'] as String?,
      requestType: json['request_type'] as String?,
      status: _parseStatus(json['request_status'] as String? ?? 'Pending'),

      appliedDate:
      (DateTime.tryParse(json['created_at'] ?? '')?.toLocal()) ??
          DateTime.now(),

      rejectRemark: json['reject_remark'] as String?,
      isAnywhere: json['is_anywhere'] as bool?,
      attendanceRequestId:
          json['attendance_request_id']?.toString() ??
          json['request_id']?.toString() ??
          json['attendance_id']?.toString(),
      isEligibleToApprove:
          (json['approval_eligibility'] as Map<String, dynamic>?)?['isEligible']
              as bool? ??
          false,
      approvers: approvers,
    );
  }

  /// Parse status string to enum.
  static WfhStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return WfhStatus.approved;
      case 'rejected':
        return WfhStatus.rejected;
      case 'withdrawn':
        return WfhStatus.withdrawn;
      case 'pending':
      default:
        return WfhStatus.pending;
    }
  }

  /// Get formatted date range string
  String get dateRange {
    if (toDate == null) {
      return _formatDate(fromDate);
    }
    if (fromDate.year == toDate!.year && fromDate.month == toDate!.month) {
      return '${_formatDate(fromDate)} to ${_formatDate(toDate!)}';
    }
    return '${_formatDate(fromDate)} to ${_formatDate(toDate!)}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
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

    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month) {
      return '${shortMonths[date.month - 1]} ${date.day}';
    }
    return '${months[date.month - 1]} ${date.day}';
  }

  WfhRequestModel copyWith({
    String? id,
    int? numberOfDays,
    DateTime? fromDate,
    DateTime? toDate,
    String? reason,
    String? subject,
    String? requestType,
    WfhStatus? status,
    DateTime? appliedDate,
    String? rejectRemark,
    bool? isAnywhere,
    String? attendanceRequestId,
    bool? isEligibleToApprove,
    List<WfhApproverSnapshot>? approvers,
  }) {
    return WfhRequestModel(
      id: id ?? this.id,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      reason: reason ?? this.reason,
      subject: subject ?? this.subject,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      rejectRemark: rejectRemark ?? this.rejectRemark,
      isAnywhere: isAnywhere ?? this.isAnywhere,
      attendanceRequestId: attendanceRequestId ?? this.attendanceRequestId,
      isEligibleToApprove:
          isEligibleToApprove ?? this.isEligibleToApprove,
      approvers: approvers ?? this.approvers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WfhRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// WFH status enum
enum WfhStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case WfhStatus.pending:
        return 'Pending';
      case WfhStatus.approved:
        return 'Approved';
      case WfhStatus.rejected:
        return 'Rejected';
      case WfhStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}
