import '../../domain/entities/approver_entity.dart';

class ApproverLevelModel extends ApproverLevelEntity {
  const ApproverLevelModel({
    required super.level,
    required super.approvalStatus,
    super.allApproversRequired,
    required List<ApproverUserModel> super.users,
  });

  factory ApproverLevelModel.fromJson(Map<String, dynamic> json) {
    return ApproverLevelModel(
      level: json['level'].toString(),
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
      allApproversRequired: json['all_approvers_required'] as bool?,
      users:
          (json['users'] as List<dynamic>?)
              ?.map(
                (e) => ApproverUserModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class ApproverUserModel extends ApproverUserEntity {
  const ApproverUserModel({
    required super.id,
    required super.email,
    super.remarks,
    super.imageUrl,
    required super.firstName,
    required super.lastName,
    super.actionDate,
    super.profileColor,
    required super.approvalStatus,
  });

  factory ApproverUserModel.fromJson(Map<String, dynamic> json) {
    return ApproverUserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      remarks: json['remarks'] as String?,
      imageUrl: json['image_url'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      actionDate: json['action_date'] as String?,
      profileColor: json['profile_color'] as String?,
      approvalStatus: json['approval_status'] as String? ?? 'Pending',
    );
  }
}
