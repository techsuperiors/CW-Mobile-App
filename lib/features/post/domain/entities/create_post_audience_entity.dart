import 'package:equatable/equatable.dart';

class CreatePostAudienceUserEntity extends Equatable {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String? employeeId;
  final String? profileColor;
  final String? imageUrl;
  final String? department;
  final String? designation;

  const CreatePostAudienceUserEntity({
    required this.id,
    required this.firstName,
    this.middleName = '',
    this.lastName = '',
    required this.email,
    this.employeeId,
    this.profileColor,
    this.imageUrl,
    this.department,
    this.designation,
  });

  String get fullName {
    final parts = [
      firstName.trim(),
      middleName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);

    if (parts.isEmpty) {
      return email.trim();
    }

    return parts.join(' ');
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    middleName,
    lastName,
    email,
    employeeId,
    profileColor,
    imageUrl,
    department,
    designation,
  ];
}

class CreatePostAudienceDepartmentEntity extends Equatable {
  final int id;
  final String name;
  final List<CreatePostAudienceUserEntity> members;

  const CreatePostAudienceDepartmentEntity({
    required this.id,
    required this.name,
    this.members = const [],
  });

  @override
  List<Object?> get props => [id, name, members];
}
