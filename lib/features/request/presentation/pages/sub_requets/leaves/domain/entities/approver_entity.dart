import 'package:equatable/equatable.dart';

class ApproverLevelEntity extends Equatable {
  final String level;
  final String approvalStatus;
  final bool? allApproversRequired;
  final List<ApproverUserEntity> users;

  const ApproverLevelEntity({
    required this.level,
    required this.approvalStatus,
    this.allApproversRequired,
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

class ApproverUserEntity extends Equatable {
  final int id;
  final String email;
  final String? remarks;
  final String? imageUrl;
  final String firstName;
  final String lastName;
  final String? actionDate;
  final String? profileColor;
  final String approvalStatus;

  const ApproverUserEntity({
    required this.id,
    required this.email,
    this.remarks,
    this.imageUrl,
    required this.firstName,
    required this.lastName,
    this.actionDate,
    this.profileColor,
    required this.approvalStatus,
  });

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
    id,
    email,
    remarks,
    imageUrl,
    firstName,
    lastName,
    actionDate,
    profileColor,
    approvalStatus,
  ];
}
