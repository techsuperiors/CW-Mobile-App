import 'package:equatable/equatable.dart';

class CompOffApprover extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? imageUrl;
  final String profileColor;
  final String approvalStatus;
  final DateTime? actionDate;

  const CompOffApprover({
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

class CompOffApprovalLevel extends Equatable {
  final String level;
  final String approvalStatus;
  final bool allApproversRequired;
  final List<CompOffApprover> users;

  const CompOffApprovalLevel({
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

class CompOffActivity extends Equatable {
  final String action;
  final String actionType;
  final String firstName;
  final String lastName;
  final String userEmail;
  final int? createdBy;
  final DateTime? createdAt;

  const CompOffActivity({
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

class CompOffDetail extends Equatable {
  final int id;
  final int userId;
  final String type;
  final String subject;
  final DateTime? date;
  final String duration;
  final String year;
  final String reason;
  final int? requestTo;
  final String? requestByName;
  final String? requestToName;
  final String? requestByImage;
  final String? requestToImage;
  final String? requestByColor;
  final String? requestToColor;
  final String status;
  final DateTime? createdAt;
  final List<CompOffApprovalLevel> approvers;
  final List<CompOffActivity> activity;

  const CompOffDetail({
    required this.id,
    required this.userId,
    required this.type,
    required this.subject,
    required this.date,
    required this.duration,
    required this.year,
    required this.reason,
    required this.requestTo,
    this.requestByName,
    this.requestToName,
    this.requestByImage,
    this.requestToImage,
    this.requestByColor,
    this.requestToColor,
    required this.status,
    required this.createdAt,
    required this.approvers,
    required this.activity,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        subject,
        date,
        duration,
        year,
        reason,
        requestTo,
        requestByName,
        requestToName,
        requestByImage,
        requestToImage,
        requestByColor,
        requestToColor,
        status,
        createdAt,
        approvers,
        activity,
      ];
}
