/// User Profile entity
class UserProfile {
  final int clientId;
  final int userId;
  final bool allowAllUsers;
  final int? departmentId;
  final String? address;
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
  final String? officialPhone;
  final bool inProbation;
  final int? l2Manager;
  final UserInfo user;
  final ReportingManagerInfo? reportingManagerInfo;
  final ReportingHrInfo? reportingHrInfo;
  final UserDepartmentInfo? userDepartment;
  final UserDesignationInfo? userDesignation;
  final ClientInfo? client;
  final RoleInfo? role;

  UserProfile({
    required this.clientId,
    required this.userId,
    this.allowAllUsers = false,
    this.departmentId,
    this.address,
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
    this.officialPhone,
    required this.inProbation,
    this.l2Manager,
    required this.user,
    this.reportingManagerInfo,
    this.reportingHrInfo,
    this.userDepartment,
    this.userDesignation,
    this.client,
    this.role,
  });
}

/// User basic information entity
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

/// Reporting Manager Information entity
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

/// Reporting HR Information entity
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

/// User Department Information entity
class UserDepartmentInfo {
  final String? departmentName;

  UserDepartmentInfo({this.departmentName});
}

/// User Designation Information entity
class UserDesignationInfo {
  final String? designationName;

  UserDesignationInfo({this.designationName});
}

/// Client Information entity
class ClientInfo {
  final int id;
  final String? clientName;

  ClientInfo({required this.id, this.clientName});
}

/// Role Information entity
class RoleInfo {
  final String? roleName;
  final List<String>? permissions;

  RoleInfo({this.roleName, this.permissions});
}
