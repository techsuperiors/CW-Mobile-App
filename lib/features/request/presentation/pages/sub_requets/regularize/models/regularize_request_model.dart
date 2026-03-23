import '../../../../../../../core/utils/date_pareser.dart';

/// Regularize request model
class RegularizeRequestModel {
  final String id;
  final RegularizeRequestType requestType; // 'Punch-In', 'Punch-Out', 'Both'
  final DateTime fromDate;
  final DateTime? toDate; // null for single day
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String reason;
  final String? description;
  final String? modeType; // 'Web', 'Mobile', etc.
  final RegularizeStatus status;
  final DateTime appliedDate;
  final String? rejectRemark;
  final String? regularizedBy;
  final bool isEligibleToApprove;

  const RegularizeRequestModel({
    required this.id,
    required this.requestType,
    required this.fromDate,
    this.toDate,
    this.checkIn,
    this.checkOut,
    required this.reason,
    this.description,
    this.modeType,
    required this.status,
    required this.appliedDate,
    this.rejectRemark,
    this.regularizedBy,
    this.isEligibleToApprove = false,
  });

  /// Factory constructor to create from API JSON response.
  factory RegularizeRequestModel.fromJson(Map<String, dynamic> json) {
    return RegularizeRequestModel(
      id: json['id'].toString(),
      requestType: parseRequestTypeValue(
        json['request_for'] as String? ?? 'both',
      ),

      fromDate: parseApiDate(json['request_date']),

      checkIn: parseApiDateNullable(json['check_in']),

      checkOut: parseApiDateNullable(json['check_out']),
      reason: json['reason'] as String? ?? '',
      description: json['description'] as String?,
      modeType: json['mode_type'] as String?,
      status: parseStatusValue(json['request_status'] as String? ?? 'Pending'),
      appliedDate: parseApiDate(json['created_at']),

      rejectRemark: json['reject_remark'] as String?,
      regularizedBy: json['regularized_by'] as String?,
      isEligibleToApprove:
          (json['approval_eligibility'] as Map<String, dynamic>?)?['isEligible']
              as bool? ??
          false,
    );
  }


  /// Parse request_for string to enum.
  static RegularizeRequestType parseRequestTypeValue(String type) {
    switch (type.toLowerCase()) {
      case 'punch-in':
      case 'punchin':
      case 'checkin':
        return RegularizeRequestType.punchIn;
      case 'punch-out':
      case 'punchout':
      case 'checkout':
        return RegularizeRequestType.punchOut;
      case 'both':
      default:
        return RegularizeRequestType.both;
    }
  }

  /// Parse status string to enum.
  static RegularizeStatus parseStatusValue(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return RegularizeStatus.approved;
      case 'rejected':
        return RegularizeStatus.rejected;
      case 'withdrawn':
        return RegularizeStatus.withdrawn;
      case 'pending':
      default:
        return RegularizeStatus.pending;
    }
  }

  /// Get formatted date range string
  String get dateRange {
    if (toDate == null) {
      return _formatDate(fromDate);
    }
    return '${_formatDateShort(fromDate)} to ${_formatDateShort(toDate!)}';
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
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatDateShort(DateTime date) {
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

  RegularizeRequestModel copyWith({
    String? id,
    RegularizeRequestType? requestType,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? checkIn,
    DateTime? checkOut,
    String? reason,
    String? description,
    String? modeType,
    RegularizeStatus? status,
    DateTime? appliedDate,
    String? rejectRemark,
    String? regularizedBy,
    bool? isEligibleToApprove,
  }) {
    return RegularizeRequestModel(
      id: id ?? this.id,
      requestType: requestType ?? this.requestType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      modeType: modeType ?? this.modeType,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      rejectRemark: rejectRemark ?? this.rejectRemark,
      regularizedBy: regularizedBy ?? this.regularizedBy,
      isEligibleToApprove:
          isEligibleToApprove ?? this.isEligibleToApprove,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegularizeRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Regularize request type enum
enum RegularizeRequestType {
  punchIn,
  punchOut,
  both;

  String get displayName {
    switch (this) {
      case RegularizeRequestType.punchIn:
        return 'Punch-In';
      case RegularizeRequestType.punchOut:
        return 'Punch-Out';
      case RegularizeRequestType.both:
        return 'Both';
    }
  }
}

/// Regularize status enum
enum RegularizeStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  String get displayName {
    switch (this) {
      case RegularizeStatus.pending:
        return 'Pending';
      case RegularizeStatus.approved:
        return 'Approved';
      case RegularizeStatus.rejected:
        return 'Rejected';
      case RegularizeStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}
