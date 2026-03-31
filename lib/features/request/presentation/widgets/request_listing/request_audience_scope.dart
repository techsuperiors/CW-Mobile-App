enum RequestAudienceScope {
  allUsers,
  myReportees,
  myIndirectReportees;

  String get label {
    switch (this) {
      case RequestAudienceScope.allUsers:
        return 'All Users';
      case RequestAudienceScope.myReportees:
        return 'My Reportees';
      case RequestAudienceScope.myIndirectReportees:
        return 'My Indirect Reportees';
    }
  }

  String get leaveRequestType {
    switch (this) {
      case RequestAudienceScope.allUsers:
        return 'Admin';
      case RequestAudienceScope.myReportees:
        return 'Team';
      case RequestAudienceScope.myIndirectReportees:
        return 'Indirect_Team';
    }
  }

  String get attendanceRequestType {
    switch (this) {
      case RequestAudienceScope.allUsers:
        return 'All';
      case RequestAudienceScope.myReportees:
        return 'Team';
      case RequestAudienceScope.myIndirectReportees:
        return 'Indirect_Team';
    }
  }
}
