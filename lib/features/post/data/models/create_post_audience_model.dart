import '../../domain/entities/create_post_audience_entity.dart';

class CreatePostAudienceUserModel extends CreatePostAudienceUserEntity {
  const CreatePostAudienceUserModel({
    required super.id,
    required super.firstName,
    super.middleName,
    super.lastName,
    required super.email,
    super.employeeId,
    super.profileColor,
    super.imageUrl,
    super.department,
    super.designation,
  });

  factory CreatePostAudienceUserModel.fromUsersApiJson(
    Map<String, dynamic> json,
  ) {
    return CreatePostAudienceUserModel(
      id: _parseToInt(json['id']),
      firstName: _asString(json['first_name']),
      middleName: _asString(json['middle_name']),
      lastName: _asString(json['last_name']),
      email: _asString(json['email']),
      employeeId: _nullableString(json['employeeID']),
      profileColor: _nullableString(json['profile_color']),
      imageUrl: _nullableString(json['image_url']),
      department: _nullableString(json['department']),
      designation: _nullableString(json['designation']),
    );
  }

  factory CreatePostAudienceUserModel.fromDepartmentMemberJson(
    Map<String, dynamic> json,
  ) {
    final userJson =
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : <String, dynamic>{};

    return CreatePostAudienceUserModel(
      id: _parseToInt(userJson['id']),
      firstName: _asString(userJson['first_name']),
      middleName: '',
      lastName: _asString(userJson['last_name']),
      email: _asString(userJson['email']),
      employeeId: null,
      profileColor: _nullableString(userJson['profile_color']),
      imageUrl: _nullableString(userJson['image_url']),
      department: _nullableString(userJson['department_name']),
      designation: _nullableString(userJson['designation']),
    );
  }
}

class CreatePostAudienceDepartmentModel
    extends CreatePostAudienceDepartmentEntity {
  const CreatePostAudienceDepartmentModel({
    required super.id,
    required super.name,
    super.members,
  });

  factory CreatePostAudienceDepartmentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final members =
        (json['userList'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CreatePostAudienceUserModel.fromDepartmentMemberJson)
            .where((user) => user.id > 0)
            .toList(growable: false) ??
        const <CreatePostAudienceUserModel>[];

    return CreatePostAudienceDepartmentModel(
      id: _parseToInt(json['id']),
      name: _asString(json['department_name']),
      members: members,
    );
  }
}

class CreatePostAudienceUsersResponseModel {
  final bool success;
  final List<CreatePostAudienceUserModel> data;

  const CreatePostAudienceUsersResponseModel({
    required this.success,
    required this.data,
  });

  factory CreatePostAudienceUsersResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreatePostAudienceUsersResponseModel(
      success: json['success'] as bool? ?? false,
      data:
          (json['data'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(CreatePostAudienceUserModel.fromUsersApiJson)
              .where((user) => user.id > 0)
              .toList(growable: false) ??
          const <CreatePostAudienceUserModel>[],
    );
  }
}

class CreatePostAudienceDepartmentsResponseModel {
  final bool success;
  final List<CreatePostAudienceDepartmentModel> data;

  const CreatePostAudienceDepartmentsResponseModel({
    required this.success,
    required this.data,
  });

  factory CreatePostAudienceDepartmentsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreatePostAudienceDepartmentsResponseModel(
      success: json['success'] as bool? ?? false,
      data:
          (json['data'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(CreatePostAudienceDepartmentModel.fromJson)
              .where((department) => department.id > 0)
              .toList(growable: false) ??
          const <CreatePostAudienceDepartmentModel>[],
    );
  }
}

int _parseToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  return value.toString().trim();
}

String? _nullableString(dynamic value) {
  final normalizedValue = _asString(value);
  return normalizedValue.isEmpty ? null : normalizedValue;
}
