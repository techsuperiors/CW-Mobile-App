import 'package:equatable/equatable.dart';

class AttendanceRegularizeApprover extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? imageUrl;
  final String? profileColor;
  final String approvalStatus;
  final DateTime? actionDate;

  const AttendanceRegularizeApprover({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.imageUrl,
    this.profileColor,
    required this.approvalStatus,
    this.actionDate,
  });

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        imageUrl,
        profileColor,
        approvalStatus,
        actionDate,
      ];
}

class AttendanceRegularizeApprovalLevel extends Equatable {
  final String level;
  final String approvalStatus;
  final bool allApproversRequired;
  final List<AttendanceRegularizeApprover> users;

  const AttendanceRegularizeApprovalLevel({
    required this.level,
    required this.approvalStatus,
    required this.allApproversRequired,
    required this.users,
  });

  @override
  List<Object?> get props => [
        level,
        approvalStatus,
        allApproversRequired,
        users,
      ];
}

class AttendanceRegularizeActivity extends Equatable {
  final String action;
  final String actionType;
  final String firstName;
  final String lastName;
  final String userEmail;
  final int? createdBy;
  final DateTime? createdAt;

  const AttendanceRegularizeActivity({
    required this.action,
    required this.actionType,
    required this.firstName,
    required this.lastName,
    required this.userEmail,
    this.createdBy,
    this.createdAt,
  });

  String get actorName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
        action,
        actionType,
        firstName,
        lastName,
        userEmail,
        createdBy,
        createdAt,
      ];
}

class AttendanceRegularizeDetail extends Equatable {
  final int id;
  final DateTime? requestDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String reason;
  final String? description;
  final String requestStatus;
  final String requestFor;
  final String? rejectRemark;
  final String? modeType;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AttendanceRegularizeApprovalLevel> approvers;
  final List<AttendanceRegularizeActivity> activity;

  const AttendanceRegularizeDetail({
    required this.id,
    required this.requestDate,
    required this.checkIn,
    required this.checkOut,
    required this.reason,
    required this.description,
    required this.requestStatus,
    required this.requestFor,
    required this.rejectRemark,
    required this.modeType,
    required this.createdAt,
    required this.updatedAt,
    required this.approvers,
    required this.activity,
  });

  @override
  List<Object?> get props => [
        id,
        requestDate,
        checkIn,
        checkOut,
        reason,
        description,
        requestStatus,
        requestFor,
        rejectRemark,
        modeType,
        createdAt,
        updatedAt,
        approvers,
        activity,
      ];
}
