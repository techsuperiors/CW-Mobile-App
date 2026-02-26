/// WFH request model
class WfhRequestModel {
  final String id;
  final int numberOfDays;
  final DateTime fromDate;
  final DateTime? toDate; // null for single day WFH
  final String reason;
  final WfhStatus status; // 'Pending', 'Approved', 'Rejected'
  final DateTime appliedDate;

  const WfhRequestModel({
    required this.id,
    required this.numberOfDays,
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
    if (fromDate.year == toDate!.year && fromDate.month == toDate!.month) {
      return '${_formatDate(fromDate)} to ${_formatDate(toDate!)}';
    }
    return '${_formatDate(fromDate)} to ${_formatDate(toDate!)}';
  }

  /// Format date to "Dec 16" or "November 30" format
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

    // Use short format for current month, full for others
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month) {
      return '${shortMonths[date.month - 1]} ${date.day}';
    }
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Create a copy with updated values
  WfhRequestModel copyWith({
    String? id,
    int? numberOfDays,
    DateTime? fromDate,
    DateTime? toDate,
    String? reason,
    WfhStatus? status,
    DateTime? appliedDate,
  }) {
    return WfhRequestModel(
      id: id ?? this.id,
      numberOfDays: numberOfDays ?? this.numberOfDays,
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
    return other is WfhRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// WFH status enum
enum WfhStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case WfhStatus.pending:
        return 'Pending';
      case WfhStatus.approved:
        return 'Approved';
      case WfhStatus.rejected:
        return 'Rejected';
    }
  }
}
