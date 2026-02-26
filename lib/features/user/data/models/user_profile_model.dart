/// User Profile Model based on API response
class UserProfileModel {
  final int clientId;
  final int userId;
  final int? departmentId;
  final String? address;
  final Map<String, dynamic>? contactDetails;
  final Map<String, dynamic>? bankDetails;
  final Map<String, dynamic>? educationDetails;
  final List<dynamic>? pastExperience;
  final Map<String, dynamic>? socialLinks;
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
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      clientId: (json['client_id'] as int?) ?? 0,
      userId: (json['user_id'] as int?) ?? 0,
      departmentId: json['department_id'] as int?,
      address: json['address'] as String?,
      contactDetails: json['contact_details'] as Map<String, dynamic>?,
      bankDetails: json['bank_details'] as Map<String, dynamic>?,
      educationDetails: json['education_details'] as Map<String, dynamic>?,
      pastExperience: json['past_experience'] as List<dynamic>?,
      socialLinks: json['social_links'] as Map<String, dynamic>?,
      birthday: json['birthday'] as String?,
      bloodGroup: json['blood_group'] as String?,
      userAbout: json['user_about'] as String?,
      reportingHr: (json['reporting_hr'] as int?) ?? 0,
      reportingManager: (json['reporting_manager'] as int?) ?? 0,
      skills: json['skills'] as List<dynamic>? ?? [],
      esiNumber: json['esi_number'] as String?,
      uanNumber: json['uan_number'] as String?,
      pfNumber: json['pf_number'] as String?,
      ctc: json['ctc'] as String?,
      payrollEnabled: json['payroll_enabled'] as bool? ?? false,
      belongsTo: json['belongs_to'] as String? ?? 'organization',
      employmentStatus: json['employment_status'] as String? ?? 'PERMANENT',
      familyDetails: json['family_details'] as List<dynamic>? ?? [],
      identityDetails: json['identity_details'] as Map<String, dynamic>?,
      officialPhone: json['official_phone'] as String?,
      inProbation: json['in_probation'] as bool? ?? false,
      l2Manager: json['l2_manager'] as int?,
      associateManagers: json['associate_managers'] as List<dynamic>?,
      legalEntityId: json['legal_entity_id'] as int?,
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
      reportingManagerInfo: json['reportingManager'] != null
          ? ReportingManagerInfo.fromJson(
              json['reportingManager'] as Map<String, dynamic>)
          : null,
      reportingHrInfo: json['reportingHR'] != null
          ? ReportingHrInfo.fromJson(
              json['reportingHR'] as Map<String, dynamic>)
          : null,
      userDepartment: json['userDepartment'] != null
          ? UserDepartmentInfo.fromJson(
              json['userDepartment'] as Map<String, dynamic>)
          : null,
      userDesignation: json['userDesignation'] != null
          ? UserDesignationInfo.fromJson(
              json['userDesignation'] as Map<String, dynamic>)
          : null,
      client: json['Client'] != null
          ? ClientInfo.fromJson(json['Client'] as Map<String, dynamic>)
          : null,
    );
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
      id: (json['id'] as int?) ?? 0,
      title: json['title'] as String?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      location: json['location'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String?,
      username: json['username'] as String?,
      personalEmail: json['personal_email'] as String?,
      imageUrl: json['image_url'] as String?,
      gender: json['gender'] as String?,
      joiningDate: json['joining_date'] as String?,
      employeeType: json['employee_type'] as String?,
      employeeID: json['employeeID'] as String?,
      profileColor: json['profile_color'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      workMode: json['work_mode'] as String?,
      maritalStatus: json['marital_status'] as String?,
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

  ClientInfo({
    required this.id,
    this.clientName,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: (json['id'] as int?) ?? 0,
      clientName: json['client_name'] as String?,
    );
  }
}

