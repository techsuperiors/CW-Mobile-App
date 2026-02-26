/// Leave request model
class LeaveRequestModel {
  final String id;
  final String leaveType; // 'Casual', 'Sick', 'Vacation', 'Personal', etc.
  final DateTime fromDate;
  final DateTime? toDate; // null for single day leave
  final String reason;
  final LeaveStatus status; // 'Pending', 'Approved', 'Rejected'
  final DateTime appliedDate;

  const LeaveRequestModel({
    required this.id,
    required this.leaveType,
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
  LeaveRequestModel copyWith({
    String? id,
    String? leaveType,
    DateTime? fromDate,
    DateTime? toDate,
    String? reason,
    LeaveStatus? status,
    DateTime? appliedDate,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      leaveType: leaveType ?? this.leaveType,
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
    return other is LeaveRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Leave status enum
enum LeaveStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }
}
