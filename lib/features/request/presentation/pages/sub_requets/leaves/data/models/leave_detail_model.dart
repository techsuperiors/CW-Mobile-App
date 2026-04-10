import '../../../../../../../../core/utils/date_pareser.dart';

/// Safely parse any value (int, double, String) to int — prevents type cast crashes.
int _safeInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}



/// A document/image attached to the leave request
class LeaveFileDocument {
  final String id;
  final String url;
  final String name;

  const LeaveFileDocument({
    required this.id,
    required this.url,
    required this.name,
  });

  factory LeaveFileDocument.fromJson(Map<String, dynamic> json) {
    return LeaveFileDocument(
      id: json['id']?.toString() ?? '',
      url: json['url'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// A single approver inside an approval level
class LeaveApprover {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? imageUrl;
  final String? profileColor;
  final String approvalStatus;
  final DateTime? actionDate;
  final String? remarks;

  const LeaveApprover({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.imageUrl,
    this.profileColor,
    required this.approvalStatus,
    this.actionDate,
    this.remarks,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory LeaveApprover.fromJson(Map<String, dynamic> json) {
    return LeaveApprover(
      id: _safeInt(json['id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String?,
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      actionDate: parseApiDateNullable(json['action_date']),
      remarks: json['remarks'] as String?,
    );
  }
}

/// An approval level (level 1, 2, …)
class LeaveApprovalLevel {
  final int level;
  final List<LeaveApprover> users;
  final String approvalStatus;
  final bool allApproversRequired;

  const LeaveApprovalLevel({
    required this.level,
    required this.users,
    required this.approvalStatus,
    required this.allApproversRequired,
  });

  factory LeaveApprovalLevel.fromJson(Map<String, dynamic> json) {
    final usersList = (json['users'] as List<dynamic>? ?? [])
        .map((u) => LeaveApprover.fromJson(u as Map<String, dynamic>))
        .toList();
    return LeaveApprovalLevel(
      level: _safeInt(json['level'], fallback: 1),
      users: usersList,
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      allApproversRequired: json['all_approvers_required'] as bool? ?? false,
    );
  }
}

/// Activity log entry
class LeaveActivity {
  final String action;
  final String actionType;
  final String status;
  final DateTime updatedAt;

  const LeaveActivity({
    required this.action,
    required this.actionType,
    required this.status,
    required this.updatedAt,
  });

  factory LeaveActivity.fromJson(Map<String, dynamic> json) {
    return LeaveActivity(
      action: json['action'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      updatedAt: parseApiDate(json['updated_at']),
    );
  }
}

/// A user snapshot (request_to, userLeave, userRequest, etc.)
class LeaveUserSnapshot {
  final int id;
  final String firstName;
  final String lastName;
  final String? imageUrl;
  final String? profileColor;

  const LeaveUserSnapshot({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.imageUrl,
    this.profileColor,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory LeaveUserSnapshot.fromJson(Map<String, dynamic> json) {
    return LeaveUserSnapshot(
      id: _safeInt(json['id']),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
    );
  }
}

class LeaveComment {
  final int id;
  final String comment;
  final DateTime? createdAt;
  final LeaveUserSnapshot? user;

  const LeaveComment({
    required this.id,
    required this.comment,
    this.createdAt,
    this.user,
  });

  factory LeaveComment.fromJson(Map<String, dynamic> json) {
    final userJson =
        json['leaveCommentCreatedBy'] ??
        json['user'] ??
        json['created_by'] ??
        json['comment_by'] ??
        json['userComment'];

    return LeaveComment(
      id: _safeInt(json['id']),
      comment:
          json['comment'] as String? ??
          json['comments'] as String? ??
          json['message'] as String? ??
          '',
      createdAt: parseApiDateNullable(
        json['created_at'] ?? json['updated_at'] ?? json['commented_at'],
      ),
      user:
          userJson is Map<String, dynamic>
              ? LeaveUserSnapshot.fromJson(userJson)
              : null,
    );
  }
}

List<LeaveComment> parseLeaveCommentsResponse(Map<String, dynamic> json) {
  final rawList =
      json['data'] as List<dynamic>? ??
      json['comments'] as List<dynamic>? ??
      json['leave_comments'] as List<dynamic>? ??
      [];

  return rawList
      .whereType<Map<String, dynamic>>()
      .map(LeaveComment.fromJson)
      .toList();
}

/// Full leave detail model from /api/leaves/request/details
class LeaveDetailModel {
  final int id;
  final String leaveType;
  final String? shortCode;
  final DateTime startDate;
  final String? startHalf;
  final DateTime endDate;
  final String? endHalf;
  final num noOfDays;
  final String? subject;
  final String reason;
  final String? description;
  final String? leaveStartTime;
  final String? leaveEndTime;
  final String status;
  final String? rejectRemark;
  final String dayType;
  final bool isClubing;
  final DateTime requestDate;
  final DateTime? createdAt;
  final DateTime? statusUpdatedAt;
  final List<LeaveFileDocument> fileDocuments;
  final List<LeaveComment> comments;
  final List<LeaveApprovalLevel> approvers;
  final List<LeaveActivity> activity;
  final LeaveUserSnapshot? userRequest;   // request_to user
  final LeaveUserSnapshot? userLeave;    // the employee on leave
  final int pendingApprovals;
  final bool allApprovalMandatory;
  final bool isEligibleToApprove;

  const LeaveDetailModel({
    required this.id,
    required this.leaveType,
    this.shortCode,
    required this.startDate,
    this.startHalf,
    required this.endDate,
    this.endHalf,
    required this.noOfDays,
    this.subject,
    required this.reason,
    this.description,
    this.leaveStartTime,
    this.leaveEndTime,
    required this.status,
    this.rejectRemark,
    required this.dayType,
    required this.isClubing,
    required this.requestDate,
    this.createdAt,
    this.statusUpdatedAt,
    required this.fileDocuments,
    required this.comments,
    required this.approvers,
    required this.activity,
    this.userRequest,
    this.userLeave,
    required this.pendingApprovals,
    required this.allApprovalMandatory,
    required this.isEligibleToApprove,
  });

  factory LeaveDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final docs = (data['file_document'] as List<dynamic>? ?? [])
        .map((d) => LeaveFileDocument.fromJson(d as Map<String, dynamic>))
        .toList();

    final commentsList =
        (data['comments'] as List<dynamic>? ??
                data['leave_comments'] as List<dynamic>? ??
                [])
            .map((c) => LeaveComment.fromJson(c as Map<String, dynamic>))
            .toList();

    final approverLevels = (data['approvers'] as List<dynamic>? ?? [])
        .map((a) => LeaveApprovalLevel.fromJson(a as Map<String, dynamic>))
        .toList();

    final activityList = (data['activity'] as List<dynamic>? ?? [])
        .map((a) => LeaveActivity.fromJson(a as Map<String, dynamic>))
        .toList();

    LeaveUserSnapshot? userRequest;
    if (data['userRequest'] != null) {
      userRequest = LeaveUserSnapshot.fromJson(data['userRequest'] as Map<String, dynamic>);
    }

    LeaveUserSnapshot? userLeave;
    if (data['userLeave'] != null) {
      userLeave = LeaveUserSnapshot.fromJson(data['userLeave'] as Map<String, dynamic>);
    }

    final eligibility = data['approval_eligibility'] as Map<String, dynamic>?;

    return LeaveDetailModel(
      id: _toNum(data['id'])?.toInt() ?? 0,
      leaveType: data['leave_type'] as String? ?? '',
      shortCode: data['short_code'] as String?,
      startDate: parseApiDate(data['start_date']),
      startHalf: data['start_half'] as String?,
      endDate: parseApiDate(data['end_date']),
      endHalf: data['end_half'] as String?,
      noOfDays: _toNum(data['no_of_days']) ?? 1,
      subject: data['subject'] as String?,
      reason: data['reason'] as String? ?? '',
      description: data['description'] as String?,
      leaveStartTime: data['leave_start_time']?.toString(),
      leaveEndTime: data['leave_end_time']?.toString(),
      status: data['status'] as String? ?? 'Pending',
      rejectRemark: data['reject_remark'] as String?,
      dayType: data['day_type'] as String? ?? 'single',
      isClubing: data['is_clubing'] as bool? ?? false,
      requestDate: parseApiDate(data['request_date']),
      createdAt: parseApiDateNullable(
        data['created_at'] ?? data['updated_at'] ?? data['request_date'],
      ),
      statusUpdatedAt: parseApiDateNullable(data['status_updated_at']),
      fileDocuments: docs,
      comments: commentsList,
      approvers: approverLevels,
      activity: activityList,
      userRequest: userRequest,
      userLeave: userLeave,
      pendingApprovals: _toNum(data['pending_approvals'])?.toInt() ?? 0,
      allApprovalMandatory: data['all_approval_mandatory'] as bool? ?? false,
      isEligibleToApprove: eligibility?['isEligible'] as bool? ?? false,
    );
  }

  LeaveDetailModel copyWith({
    int? id,
    String? leaveType,
    String? shortCode,
    DateTime? startDate,
    String? startHalf,
    DateTime? endDate,
    String? endHalf,
    num? noOfDays,
    String? subject,
    String? reason,
    String? description,
    String? leaveStartTime,
    String? leaveEndTime,
    String? status,
    String? rejectRemark,
    String? dayType,
    bool? isClubing,
    DateTime? requestDate,
    DateTime? createdAt,
    DateTime? statusUpdatedAt,
    List<LeaveFileDocument>? fileDocuments,
    List<LeaveComment>? comments,
    List<LeaveApprovalLevel>? approvers,
    List<LeaveActivity>? activity,
    LeaveUserSnapshot? userRequest,
    LeaveUserSnapshot? userLeave,
    int? pendingApprovals,
    bool? allApprovalMandatory,
    bool? isEligibleToApprove,
  }) {
    return LeaveDetailModel(
      id: id ?? this.id,
      leaveType: leaveType ?? this.leaveType,
      shortCode: shortCode ?? this.shortCode,
      startDate: startDate ?? this.startDate,
      startHalf: startHalf ?? this.startHalf,
      endDate: endDate ?? this.endDate,
      endHalf: endHalf ?? this.endHalf,
      noOfDays: noOfDays ?? this.noOfDays,
      subject: subject ?? this.subject,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      leaveStartTime: leaveStartTime ?? this.leaveStartTime,
      leaveEndTime: leaveEndTime ?? this.leaveEndTime,
      status: status ?? this.status,
      rejectRemark: rejectRemark ?? this.rejectRemark,
      dayType: dayType ?? this.dayType,
      isClubing: isClubing ?? this.isClubing,
      requestDate: requestDate ?? this.requestDate,
      createdAt: createdAt ?? this.createdAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      fileDocuments: fileDocuments ?? this.fileDocuments,
      comments: comments ?? this.comments,
      approvers: approvers ?? this.approvers,
      activity: activity ?? this.activity,
      userRequest: userRequest ?? this.userRequest,
      userLeave: userLeave ?? this.userLeave,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      allApprovalMandatory: allApprovalMandatory ?? this.allApprovalMandatory,
      isEligibleToApprove: isEligibleToApprove ?? this.isEligibleToApprove,
    );
  }

  /// Safely convert any value (int, double, String) to num — avoids type cast exceptions.
  static num? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  /// Friendly half-label: 'first_half' → 'First Half'
  static String halfLabel(String? half) {
    if (half == null) return '';
    return half.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }
}
