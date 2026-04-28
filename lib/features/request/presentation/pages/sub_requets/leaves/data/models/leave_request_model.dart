import '../../../../../../../../core/utils/date_pareser.dart';
import '../../domain/entities/leave_entity.dart';

/// Leave request model extending LeaveEntity
class LeaveRequestModel extends LeaveEntity {
  const LeaveRequestModel({
    required super.id,
    required super.leaveType,
    super.shortCode,
    required super.fromDate,
    super.toDate,
    super.noOfDays,
    required super.reason,
    super.subject,
    super.description,
    required super.status,
    required super.appliedDate,
    super.rejectRemark,
    super.fileDocuments = const [],
    super.fileAttachments = const [],
  });

  /// Factory constructor to create from API JSON response.
  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'].toString(),
      leaveType: json['leave_type'] as String? ?? '',
      shortCode: json['short_code'] as String?,
      fromDate: parseApiDate(json['start_date']),

      toDate: parseApiDateNullable(json['end_date']),

      noOfDays: (json['no_of_days'] as num?)?.toInt(),
      reason: json['reason'] as String? ?? '',
      subject: json['subject'] as String?,
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String? ?? 'Pending'),
      appliedDate: parseApiDate(
        json['request_date'] ?? json['created_at'] ?? json['updated_at'],
      ),
      rejectRemark: json['reject_remark'] as String?,
      fileDocuments:
          (json['file_document'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return e['url']?.toString() ?? e['name']?.toString() ?? '';
                }
                return e.toString();
              })
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      fileAttachments:
          (json['file_document'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(
                (e) => LeaveAttachmentRef(
                  leaveFileId: int.tryParse(json['id']?.toString() ?? '') ?? 0,
                  fileId: e['id']?.toString() ?? '',
                  url: e['url']?.toString() ?? '',
                  name: e['name']?.toString() ?? '',
                ),
              )
              .where((e) => e.fileId.isNotEmpty && e.url.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  /// Parse status string to enum.
  static LeaveStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'withdrawn':
        return LeaveStatus.withdrawn;
      case 'pending':
      default:
        return LeaveStatus.pending;
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

  /// Create a copy with updated values
  LeaveRequestModel copyWith({
    String? id,
    String? leaveType,
    String? shortCode,
    DateTime? fromDate,
    DateTime? toDate,
    int? noOfDays,
    String? reason,
    String? subject,
    String? description,
    LeaveStatus? status,
    DateTime? appliedDate,
    String? rejectRemark,
    List<String>? fileDocuments,
    List<LeaveAttachmentRef>? fileAttachments,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      leaveType: leaveType ?? this.leaveType,
      shortCode: shortCode ?? this.shortCode,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      noOfDays: noOfDays ?? this.noOfDays,
      reason: reason ?? this.reason,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      appliedDate: appliedDate ?? this.appliedDate,
      rejectRemark: rejectRemark ?? this.rejectRemark,
      fileDocuments: fileDocuments ?? this.fileDocuments,
      fileAttachments: fileAttachments ?? this.fileAttachments,
    );
  }
}
// enum LeaveStatus {
//   pending,
//   approved,
//   rejected,
//   withdrawn;
//
//   String get displayName {
//     switch (this) {
//       case LeaveStatus.pending:
//         return 'Pending';
//       case LeaveStatus.approved:
//         return 'Approved';
//       case LeaveStatus.rejected:
//         return 'Rejected';
//       case LeaveStatus.withdrawn:
//         return 'Withdrawn';
//     }
//   }
// }
