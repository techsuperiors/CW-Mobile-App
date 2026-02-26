/// Regularize request model
class RegularizeRequestModel {
  final String id;
  final RegularizeRequestType requestType; // 'Punch-In', 'Punch-Out', 'Both'
  final DateTime fromDate;
  final DateTime? toDate; // null for single day
  final String reason;
  final RegularizeStatus status; // 'Pending', 'Approved', 'Rejected'
  final DateTime appliedDate;

  const RegularizeRequestModel({
    required this.id,
    required this.requestType,
    required this.fromDate,
    this.toDate,
    required this.reason,
    required this.status,
    required this.appliedDate,
  });

  /// Get formatted date range string
  String get dateRange {
    if (toDate == null) {
      return _formatDate(fromDate);
    }
    // For date ranges, use short month format
    return '${_formatDateShort(fromDate)} to ${_formatDateShort(toDate!)}';
  }

  /// Format date to "November 30" format (full month name for single dates)
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
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Format date to "Dec 16" format (short month name for date ranges)
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
      'Dec'
    ];
    return '${shortMonths[date.month - 1]} ${date.day}';
  }

  /// Create a copy with updated values
  RegularizeRequestModel copyWith({
    String? id,
    RegularizeRequestType? requestType,
    DateTime? fromDate,
    DateTime? toDate,
    String? reason,
    RegularizeStatus? status,
    DateTime? appliedDate,
  }) {
    return RegularizeRequestModel(
      id: id ?? this.id,
      requestType: requestType ?? this.requestType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
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
  rejected;

  String get displayName {
    switch (this) {
      case RegularizeStatus.pending:
        return 'Pending';
      case RegularizeStatus.approved:
        return 'Approved';
      case RegularizeStatus.rejected:
        return 'Rejected';
    }
  }
}
