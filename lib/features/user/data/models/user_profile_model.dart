/// User Profile Model based on API response
class UserProfileModel {
  final int clientId;
  final int userId;
  final int? departmentId;
  final String? address;
  final List<dynamic>? contactDetails;
  final Map<String, dynamic>? bankDetails;
  final List<dynamic>? educationDetails;
  final List<dynamic>? pastExperience;
  final List<dynamic>? socialLinks;
  final String? birthday;
  final String? bloodGroup;
  final String? userAbout;
  final int reportingHr;
  final int reportingManager;
  final List<dynamic> skills;
  final String? esiNumber;
  final String? uanNumber;
  final String? pfNumber;
  final String? ctc;
  final bool payrollEnabled;
  final String belongsTo;
  final String employmentStatus;
  final List<dynamic> familyDetails;
  final Map<String, dynamic>? identityDetails;
  final String? officialPhone;
  final bool inProbation;
  final int? l2Manager;
  final List<dynamic>? associateManagers;
  final int? legalEntityId;
  final UserInfo user;
  final ReportingManagerInfo? reportingManagerInfo;
  final ReportingHrInfo? reportingHrInfo;
  final UserDepartmentInfo? userDepartment;
  final UserDesignationInfo? userDesignation;
  final ClientInfo? client;
  final RoleInfo? role;

  UserProfileModel({
    required this.clientId,
    required this.userId,
    this.departmentId,
    this.address,
    this.contactDetails,
    this.bankDetails,
    this.educationDetails,
    this.pastExperience,
    this.socialLinks,
    this.birthday,
    this.bloodGroup,
    this.userAbout,
    required this.reportingHr,
    required this.reportingManager,
    required this.skills,
    this.esiNumber,
    this.uanNumber,
    this.pfNumber,
    this.ctc,
    required this.payrollEnabled,
    required this.belongsTo,
    required this.employmentStatus,
    required this.familyDetails,
    this.identityDetails,
    this.officialPhone,
    required this.inProbation,
    this.l2Manager,
    this.associateManagers,
    this.legalEntityId,
    required this.user,
    this.reportingManagerInfo,
    this.reportingHrInfo,
    this.userDepartment,
    this.userDesignation,
    this.client,
    this.role,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      clientId: _asInt(json['client_id']) ?? 0,
      userId: _asInt(json['user_id']) ?? 0,
      departmentId: _asInt(json['department_id']),
      address: _parseAddress(json['address']),
      contactDetails: json['contact_details'] as List<dynamic>?,
      bankDetails: _asMap(json['bank_details']),
      educationDetails: json['education_details'] as List<dynamic>?,
      pastExperience: json['past_experience'] as List<dynamic>?,
      socialLinks: json['social_links'] as List<dynamic>?,
      birthday: _asString(json['birthday']),
      bloodGroup: _asString(json['blood_group']),
      userAbout: _asString(json['user_about']),
      reportingHr: _asInt(json['reporting_hr']) ?? 0,
      reportingManager: _asInt(json['reporting_manager']) ?? 0,
      skills: json['skills'] as List<dynamic>? ?? [],
      esiNumber: _asString(json['esi_number']),
      uanNumber: _asString(json['uan_number']),
      pfNumber: _asString(json['pf_number']),
      ctc: _asString(json['ctc']),
      payrollEnabled: json['payroll_enabled'] as bool? ?? false,
      belongsTo: _asString(json['belongs_to']) ?? 'organization',
      employmentStatus: _asString(json['employment_status']) ?? 'PERMANENT',
      familyDetails: json['family_details'] as List<dynamic>? ?? [],
      identityDetails: _asMap(json['identity_details']),
      officialPhone: _asString(json['official_phone']),
      inProbation: json['in_probation'] as bool? ?? false,
      l2Manager: _asInt(json['l2_manager']),
      associateManagers: json['associate_managers'] as List<dynamic>?,
      legalEntityId: _asInt(json['legal_entity_id']),
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
      reportingManagerInfo:
          json['reportingManager'] != null
              ? ReportingManagerInfo.fromJson(
                json['reportingManager'] as Map<String, dynamic>,
              )
              : null,
      reportingHrInfo:
          json['reportingHR'] != null
              ? ReportingHrInfo.fromJson(
                json['reportingHR'] as Map<String, dynamic>,
              )
              : null,
      userDepartment:
          json['department_name'] != null
              ? UserDepartmentInfo(
                departmentName: json['department_name'] as String?,
              )
              : null,
      userDesignation:
          json['designation_name'] != null
              ? UserDesignationInfo(
                designationName: json['designation_name'] as String?,
              )
              : null,
      client:
          (json['client_id'] != null || json['client_name'] != null)
              ? ClientInfo(
                id: _asInt(json['client_id']) ?? 0,
                clientName: _asString(json['client_name']),
              )
              : null,
      role:
          json['Role'] != null
              ? RoleInfo.fromJson(json['Role'] as Map<String, dynamic>)
              : null,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool || value is DateTime) {
      return value.toString();
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key.toString(), val),
      );
    }
    return null;
  }

  static String? _parseAddress(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) {
      final parts =
          value
              .whereType<Map>()
              .map((item) => item['line1'])
              .whereType<String>()
              .where((line) => line.trim().isNotEmpty)
              .toList();
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }
    return null;
  }
}

/// User basic information
class UserInfo {
  final int id;
  final String? title;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? location;
  final String? email;
  final String? phone;
  final String? status;
  final String? username;
  final String? personalEmail;
  final String? imageUrl;
  final String? gender;
  final String? joiningDate;
  final String? employeeType;
  final String? employeeID;
  final String? profileColor;
  final String? coverImageUrl;
  final String? workMode;
  final String? maritalStatus;

  UserInfo({
    required this.id,
    this.title,
    this.firstName,
    this.middleName,
    this.lastName,
    this.location,
    this.email,
    this.phone,
    this.status,
    this.username,
    this.personalEmail,
    this.imageUrl,
    this.gender,
    this.joiningDate,
    this.employeeType,
    this.employeeID,
    this.profileColor,
    this.coverImageUrl,
    this.workMode,
    this.maritalStatus,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: UserProfileModel._asInt(json['id']) ?? 0,
      title: UserProfileModel._asString(json['title']),
      firstName: UserProfileModel._asString(json['first_name']),
      middleName: UserProfileModel._asString(json['middle_name']),
      lastName: UserProfileModel._asString(json['last_name']),
      location: UserProfileModel._asString(json['location']),
      email: UserProfileModel._asString(json['email']),
      phone: UserProfileModel._asString(json['phone']),
      status: UserProfileModel._asString(json['status']),
      username: UserProfileModel._asString(json['username']),
      personalEmail: UserProfileModel._asString(json['personal_email']),
      imageUrl: UserProfileModel._asString(json['image_url']),
      gender: UserProfileModel._asString(json['gender']),
      joiningDate: UserProfileModel._asString(json['joining_date']),
      employeeType: UserProfileModel._asString(json['employee_type']),
      employeeID: UserProfileModel._asString(json['employeeID']),
      profileColor: UserProfileModel._asString(json['profile_color']),
      coverImageUrl: UserProfileModel._asString(json['cover_image_url']),
      workMode: UserProfileModel._asString(json['work_mode']),
      maritalStatus: UserProfileModel._asString(json['marital_status']),
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? email ?? 'User' : parts.join(' ');
  }
}

/// Reporting Manager Information
class ReportingManagerInfo {
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? email;
  final String? imageUrl;
  final String? profileColor;

  ReportingManagerInfo({
    this.firstName,
    this.lastName,
    this.middleName,
    this.email,
    this.imageUrl,
    this.profileColor,
  });

  factory ReportingManagerInfo.fromJson(Map<String, dynamic> json) {
    return ReportingManagerInfo(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      middleName: json['middle_name'] as String?,
      email: json['email'] as String?,
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? email ?? 'Manager' : parts.join(' ');
  }
}

/// Reporting HR Information
class ReportingHrInfo {
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? email;
  final String? imageUrl;
  final String? profileColor;

  ReportingHrInfo({
    this.firstName,
    this.lastName,
    this.middleName,
    this.email,
    this.imageUrl,
    this.profileColor,
  });

  factory ReportingHrInfo.fromJson(Map<String, dynamic> json) {
    return ReportingHrInfo(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      middleName: json['middle_name'] as String?,
      email: json['email'] as String?,
      imageUrl: json['image_url'] as String?,
      profileColor: json['profile_color'] as String?,
    );
  }

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) {
      parts.add(firstName!);
    }
    if (middleName != null && middleName!.isNotEmpty) {
      parts.add(middleName!);
    }
    if (lastName != null && lastName!.isNotEmpty) {
      parts.add(lastName!);
    }
    return parts.isEmpty ? email ?? 'HR' : parts.join(' ');
  }
}

/// User Department Information
class UserDepartmentInfo {
  final String? departmentName;

  UserDepartmentInfo({this.departmentName});

  factory UserDepartmentInfo.fromJson(Map<String, dynamic> json) {
    return UserDepartmentInfo(
      departmentName: json['department_name'] as String?,
    );
  }
}

/// User Designation Information
class UserDesignationInfo {
  final String? designationName;

  UserDesignationInfo({this.designationName});

  factory UserDesignationInfo.fromJson(Map<String, dynamic> json) {
    return UserDesignationInfo(
      designationName: json['designation_name'] as String?,
    );
  }
}

/// Client Information
class ClientInfo {
  final int id;
  final String? clientName;

  ClientInfo({required this.id, this.clientName});

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: (json['id'] as int?) ?? 0,
      clientName: json['client_name'] as String?,
    );
  }
}

/// Role Information
class RoleInfo {
  final String? roleName;
  final List<String>? permissions;

  RoleInfo({this.roleName, this.permissions});

  factory RoleInfo.fromJson(Map<String, dynamic> json) {
    return RoleInfo(
      roleName: json['role_name'] as String?,
      permissions:
          (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
    );
  }
}
