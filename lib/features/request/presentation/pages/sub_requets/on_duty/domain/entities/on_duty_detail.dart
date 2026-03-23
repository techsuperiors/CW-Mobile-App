import 'package:equatable/equatable.dart';

class OnDutyApprover extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? imageUrl;
  final String? profileColor;
  final String approvalStatus;
  final DateTime? actionDate;

  const OnDutyApprover({
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

class OnDutyApprovalLevel extends Equatable {
  final String level;
  final String approvalStatus;
  final bool allApproversRequired;
  final List<OnDutyApprover> users;

  const OnDutyApprovalLevel({
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

class OnDutyActivity extends Equatable {
  final String action;
  final String actionType;
  final String firstName;
  final String lastName;
  final String userEmail;
  final int? createdBy;
  final DateTime? createdAt;

  const OnDutyActivity({
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

class OnDutyDetail extends Equatable {
  final int id;
  final int userId;
  final int? requestFor;
  final DateTime? startDate;
  final String? startHalf;
  final DateTime? endDate;
  final String? endHalf;
  final String requestType;
  final String? reason;
  final String? subject;
  final String? description;
  final String? rejectRemark;
  final num numberOfDays;
  final String requestStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OnDutyApprovalLevel> approvers;
  final List<OnDutyActivity> activity;

  const OnDutyDetail({
    required this.id,
    required this.userId,
    required this.requestFor,
    required this.startDate,
    required this.startHalf,
    required this.endDate,
    required this.endHalf,
    required this.requestType,
    required this.reason,
    required this.subject,
    required this.description,
    required this.rejectRemark,
    required this.numberOfDays,
    required this.requestStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.approvers,
    required this.activity,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        requestFor,
        startDate,
        startHalf,
        endDate,
        endHalf,
        requestType,
        reason,
        subject,
        description,
        rejectRemark,
        numberOfDays,
        requestStatus,
        createdAt,
        updatedAt,
        approvers,
        activity,
      ];
}
