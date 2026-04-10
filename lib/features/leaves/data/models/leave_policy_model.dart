class LeavePolicyModel {
  final String leaveTypeName;
  final bool allowHalfDayLeave;
  final bool allowShortLeave;
  final bool allowClubLeave;

  const LeavePolicyModel({
    required this.leaveTypeName,
    required this.allowHalfDayLeave,
    required this.allowShortLeave,
    required this.allowClubLeave,
  });

  factory LeavePolicyModel.fromJson(Map<String, dynamic> json) {
    final leaveTypeName =
        json['leave_type']?.toString() ??
        (json['LeaveType'] as Map<String, dynamic>? ?? const {})['leave_name']
            ?.toString() ??
        '';
    final quotaRules =
        json['quota_allocation_rules'] as Map<String, dynamic>? ?? const {};
    final leaveConfiguration =
        quotaRules['leave_configuration'] as Map<String, dynamic>? ?? const {};
    final applyRules = json['apply_rules'] as Map<String, dynamic>? ?? const {};
    final restrictions =
        applyRules['leave_application_restrictions'] as Map<String, dynamic>? ??
            const {};
    final clubLeave = restrictions['club_leave'] as Map<String, dynamic>? ?? const {};
    return LeavePolicyModel(
      leaveTypeName: leaveTypeName,
      allowHalfDayLeave: leaveConfiguration['allow_half_day_leave'] == true,
      allowShortLeave: leaveConfiguration['allow_short_leave'] == true,
      allowClubLeave: clubLeave['allowed']?.toString().toLowerCase() == 'yes',
    );
  }
}

class WorkingHoursModel {
  final int fullDayHours;
  final int halfDayHours;
  final int shortDayHours;

  const WorkingHoursModel({
    required this.fullDayHours,
    required this.halfDayHours,
    required this.shortDayHours,
  });

  factory WorkingHoursModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return WorkingHoursModel(
      fullDayHours: (data['full_day_hours'] as num?)?.toInt() ?? 0,
      halfDayHours: (data['half_day_hours'] as num?)?.toInt() ?? 0,
      shortDayHours: (data['short_day_hours'] as num?)?.toInt() ?? 0,
    );
  }
}
