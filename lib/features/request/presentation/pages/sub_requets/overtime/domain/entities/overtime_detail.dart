import 'package:equatable/equatable.dart';

class OvertimeApprover extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? imageUrl;
  final String profileColor;
  final String approvalStatus;
  final DateTime? actionDate;

  const OvertimeApprover({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.imageUrl,
    required this.profileColor,
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

class OvertimeApprovalLevel extends Equatable {
  final String level;
  final String approvalStatus;
  final bool allApproversRequired;
  final List<OvertimeApprover> users;

  const OvertimeApprovalLevel({
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

class OvertimeActivity extends Equatable {
  final String action;
  final String actionType;
  final String firstName;
  final String lastName;
  final String userEmail;
  final int? createdBy;
  final DateTime? createdAt;

  const OvertimeActivity({
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

class OvertimeDetail extends Equatable {
  final int id;
  final int userId;
  final String subject;
  final String? description;
  final DateTime? requestDate;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String totalHours;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OvertimeApprovalLevel> approvers;
  final List<OvertimeActivity> activity;

  const OvertimeDetail({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.requestDate,
    required this.checkIn,
    required this.checkOut,
    required this.totalHours,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.approvers,
    required this.activity,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        subject,
        description,
        requestDate,
        checkIn,
        checkOut,
        totalHours,
        status,
        createdAt,
        updatedAt,
        approvers,
        activity,
      ];
}
