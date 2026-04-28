import '../../domain/models/employee_directory_model.dart';

class EmployeeDirectoryPageRemoteModel {
  final List<EmployeeDirectoryRemoteModel> employees;
  final int totalCount;

  const EmployeeDirectoryPageRemoteModel({
    required this.employees,
    required this.totalCount,
  });

  factory EmployeeDirectoryPageRemoteModel.fromJson(Map<String, dynamic> json) {
    return EmployeeDirectoryPageRemoteModel(
      employees: (json['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EmployeeDirectoryRemoteModel.fromJson)
          .toList(growable: false),
      totalCount: _parseInt(json['totalUsersList']),
    );
  }

  EmployeeDirectoryPageModel toDomain() {
    return EmployeeDirectoryPageModel(
      employees: employees
          .map((employee) => employee.toDomain())
          .toList(growable: false),
      totalCount: totalCount,
    );
  }
}

class EmployeeDirectoryRemoteModel {
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

  const EmployeeDirectoryRemoteModel({
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

  factory EmployeeDirectoryRemoteModel.fromJson(Map<String, dynamic> json) {
    final department = json['userDepartment'];
    final designation = json['userDesignation'];

    return EmployeeDirectoryRemoteModel(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      firstName: _nullableString(json['first_name']),
      middleName: _nullableString(json['middle_name']),
      lastName: _nullableString(json['last_name']),
      email: _nullableString(json['email']),
      phone: _nullableString(json['phone']),
      employeeId: _nullableString(json['employeeID']),
      imageUrl: _nullableString(json['image_url']),
      profileColor: _nullableString(json['profile_color']),
      departmentName:
          department is Map<String, dynamic>
              ? _nullableString(department['department_name'])
              : '',
      designationName:
          designation is Map<String, dynamic>
              ? _nullableString(designation['designation_name'])
              : '',
      loginStatus: _nullableString(json['login_status']),
      attendanceStatus: _nullableString(json['attendance_status']),
      status: _nullableString(json['status']),
      loginEnabled: _parseBool(json['login_enabled']),
    );
  }

  EmployeeDirectoryModel toDomain() {
    return EmployeeDirectoryModel(
      id: id,
      userId: userId,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      phone: phone,
      employeeId: employeeId,
      imageUrl: imageUrl,
      profileColor: profileColor,
      departmentName: departmentName,
      designationName: designationName,
      loginStatus: loginStatus,
      attendanceStatus: attendanceStatus,
      status: status,
      loginEnabled: loginEnabled,
    );
  }
}

class EmployeeDirectoryPersonRemoteModel {
  final int id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String imageUrl;
  final String profileColor;
  final String employeeId;

  const EmployeeDirectoryPersonRemoteModel({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.imageUrl,
    required this.profileColor,
    required this.employeeId,
  });

  factory EmployeeDirectoryPersonRemoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmployeeDirectoryPersonRemoteModel(
      id: _parseInt(json['id'] ?? json['user_id']),
      firstName: _nullableString(json['first_name']),
      middleName: _nullableString(json['middle_name']),
      lastName: _nullableString(json['last_name']),
      email: _nullableString(json['email']),
      imageUrl: _nullableString(json['image_url']),
      profileColor: _nullableString(json['profile_color']),
      employeeId: _nullableString(json['employeeID']),
    );
  }

  EmployeeDirectoryPersonModel toDomain() {
    return EmployeeDirectoryPersonModel(
      id: id,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      imageUrl: imageUrl,
      profileColor: profileColor,
      employeeId: employeeId,
    );
  }
}

class EmployeeDirectoryDetailRemoteModel {
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
  final EmployeeDirectoryPersonRemoteModel? reportingManager;
  final EmployeeDirectoryPersonRemoteModel? reportingHr;
  final EmployeeDirectoryPersonRemoteModel? l2Manager;
  final List<EmployeeDirectoryPersonRemoteModel> associateManagers;

  const EmployeeDirectoryDetailRemoteModel({
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

  factory EmployeeDirectoryDetailRemoteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    final source = data is Map<String, dynamic> ? data : json;
    final department = source['userDepartment'];

    return EmployeeDirectoryDetailRemoteModel(
      userId: _parseInt(source['user_id']),
      firstName: _nullableString(source['first_name']),
      middleName: _nullableString(source['middle_name']),
      lastName: _nullableString(source['last_name']),
      email: _nullableString(source['email']),
      employeeId: _nullableString(source['employeeID']),
      imageUrl: _nullableString(source['image_url']),
      profileColor: _nullableString(source['profile_color']),
      gender: _nullableString(source['gender']),
      location: _nullableString(source['location']),
      departmentName:
          department is Map<String, dynamic>
              ? _nullableString(department['department_name'])
              : '',
      reportingManager:
          source['reportingManager'] is Map<String, dynamic>
              ? EmployeeDirectoryPersonRemoteModel.fromJson(
                source['reportingManager'] as Map<String, dynamic>,
              )
              : null,
      reportingHr:
          source['reportingHR'] is Map<String, dynamic>
              ? EmployeeDirectoryPersonRemoteModel.fromJson(
                source['reportingHR'] as Map<String, dynamic>,
              )
              : null,
      l2Manager:
          source['l2Manager'] is Map<String, dynamic>
              ? EmployeeDirectoryPersonRemoteModel.fromJson(
                source['l2Manager'] as Map<String, dynamic>,
              )
              : null,
      associateManagers: (source['associate_managers'] as List<dynamic>? ??
              const [])
          .whereType<Map<String, dynamic>>()
          .map(EmployeeDirectoryPersonRemoteModel.fromJson)
          .toList(growable: false),
    );
  }

  EmployeeDirectoryDetailModel toDomain() {
    return EmployeeDirectoryDetailModel(
      userId: userId,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      email: email,
      employeeId: employeeId,
      imageUrl: imageUrl,
      profileColor: profileColor,
      gender: gender,
      location: location,
      departmentName: departmentName,
      reportingManager: reportingManager?.toDomain(),
      reportingHr: reportingHr?.toDomain(),
      l2Manager: l2Manager?.toDomain(),
      associateManagers: associateManagers
          .map((manager) => manager.toDomain())
          .toList(growable: false),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
  return false;
}

String _nullableString(dynamic value) {
  if (value == null) return '';
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.toLowerCase() == 'null' ? '' : trimmed;
  }
  return value.toString().trim();
}
