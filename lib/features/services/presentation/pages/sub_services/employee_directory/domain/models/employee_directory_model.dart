import 'package:equatable/equatable.dart';

class EmployeeDirectoryModel extends Equatable {
  final int id;
  final int userId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phone;
  final String employeeId;
  final String imageUrl;
  final String profileColor;
  final String departmentName;
  final String designationName;
  final String loginStatus;
  final String attendanceStatus;
  final String status;
  final bool loginEnabled;

  const EmployeeDirectoryModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.employeeId,
    required this.imageUrl,
    required this.profileColor,
    required this.departmentName,
    required this.designationName,
    required this.loginStatus,
    required this.attendanceStatus,
    required this.status,
    required this.loginEnabled,
  });

  String get fullName {
    final parts = [
      firstName.trim(),
      middleName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) return 'Unknown Employee';
    return parts.join(' ');
  }

  String get employeeCodeLabel => employeeId.trim().isEmpty ? '--' : employeeId;

  String get designationLabel =>
      designationName.trim().isEmpty
          ? 'Designation not assigned'
          : designationName;

  String get phoneLabel => phone.trim().isEmpty ? '--' : phone;

  String get loginStatusLabel =>
      _normalizeLabel(loginStatus, fallback: 'Offline');

  String get attendanceStatusLabel =>
      _normalizeLabel(attendanceStatus, fallback: 'Unavailable');

  String _normalizeLabel(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    final parts = trimmed.split(RegExp(r'[_\s]+'));
    return parts
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    firstName,
    middleName,
    lastName,
    email,
    phone,
    employeeId,
    imageUrl,
    profileColor,
    departmentName,
    designationName,
    loginStatus,
    attendanceStatus,
    status,
    loginEnabled,
  ];
}

class EmployeeDirectoryPageModel extends Equatable {
  final List<EmployeeDirectoryModel> employees;
  final int totalCount;

  const EmployeeDirectoryPageModel({
    required this.employees,
    required this.totalCount,
  });

  @override
  List<Object?> get props => [employees, totalCount];
}

class EmployeeDirectoryPersonModel extends Equatable {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String imageUrl;
  final String profileColor;
  final String employeeId;

  const EmployeeDirectoryPersonModel({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.imageUrl,
    required this.profileColor,
    required this.employeeId,
  });

  String get fullName {
    final parts = [
      firstName.trim(),
      middleName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) return 'Unknown Employee';
    return parts.join(' ');
  }

  String get secondaryLabel {
    final trimmedEmployeeId = employeeId.trim();
    if (trimmedEmployeeId.isNotEmpty) {
      return trimmedEmployeeId;
    }
    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty) {
      return trimmedEmail;
    }
    return '--';
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    middleName,
    lastName,
    email,
    imageUrl,
    profileColor,
    employeeId,
  ];
}

class EmployeeDirectoryDetailModel extends Equatable {
  final int userId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String employeeId;
  final String imageUrl;
  final String profileColor;
  final String gender;
  final String location;
  final String departmentName;
  final EmployeeDirectoryPersonModel? reportingManager;
  final EmployeeDirectoryPersonModel? reportingHr;
  final EmployeeDirectoryPersonModel? l2Manager;
  final List<EmployeeDirectoryPersonModel> associateManagers;

  const EmployeeDirectoryDetailModel({
    required this.userId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.employeeId,
    required this.imageUrl,
    required this.profileColor,
    required this.gender,
    required this.location,
    required this.departmentName,
    this.reportingManager,
    this.reportingHr,
    this.l2Manager,
    this.associateManagers = const [],
  });

  String get fullName {
    final parts = [
      firstName.trim(),
      middleName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) return 'Unknown Employee';
    return parts.join(' ');
  }

  String get employeeCodeLabel => employeeId.trim().isEmpty ? '--' : employeeId;

  String get genderLabel => _normalizeLabel(gender, fallback: '--');

  String get departmentLabel =>
      departmentName.trim().isEmpty ? '--' : departmentName.trim();

  String get locationLabel => location.trim().isEmpty ? '--' : location.trim();

  String _normalizeLabel(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    final parts = trimmed.split(RegExp(r'[_\s]+'));
    return parts
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  List<Object?> get props => [
    userId,
    firstName,
    middleName,
    lastName,
    email,
    employeeId,
    imageUrl,
    profileColor,
    gender,
    location,
    departmentName,
    reportingManager,
    reportingHr,
    l2Manager,
    associateManagers,
  ];
}
