/// Leave Type Configuration Model
class LeaveTypeConfigModel {
  final String? leaveType;
  final int? annualQuota;
  final int? assignedQuota;
  final int? remainingLeaves;
  final int? allocatedLeave;
  final String? leaveCode;
  final String? distributeType;
  final String? leaveTypeCategory;
  final List<String>? gender;
  final List<String>? maritalStatus;
  final int? consumedLeaves;
  final String? distributionType;
  final String? leaveCategory;
  final List<dynamic>? reasonList;
  final bool? mandatoryAttachments;
  final String? mandatoryRaiseDays;
  final String? status;
  final Map<String, dynamic>? rules;
  final int? totalLeaves;
  final int? currentMonthLop;

  LeaveTypeConfigModel({
    this.leaveType,
    this.annualQuota,
    this.assignedQuota,
    this.remainingLeaves,
    this.allocatedLeave,
    this.leaveCode,
    this.distributeType,
    this.leaveTypeCategory,
    this.gender,
    this.maritalStatus,
    this.consumedLeaves,
    this.distributionType,
    this.leaveCategory,
    this.reasonList,
    this.mandatoryAttachments,
    this.mandatoryRaiseDays,
    this.status,
    this.rules,
    this.totalLeaves,
    this.currentMonthLop,
  });

  factory LeaveTypeConfigModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeConfigModel(
      leaveType: json['leave_type'] as String?,
      annualQuota: json['annual_quota'] as int?,
      assignedQuota: json['assigned_quota'] as int?,
      remainingLeaves: json['remaining_leaves'] as int?,
      allocatedLeave: json['allocated_leave'] as int?,
      leaveCode: json['leave_code'] as String?,
      distributeType: json['distributeType'] as String?,
      leaveTypeCategory: json['leaveType'] as String?,
      gender: json['gender'] != null
          ? (json['gender'] as List).map((e) => e.toString()).toList()
          : null,
      maritalStatus: json['marital_status'] != null
          ? (json['marital_status'] as List).map((e) => e.toString()).toList()
          : null,
      consumedLeaves: json['consumed_leaves'] as int?,
      distributionType: json['distribution_type'] as String?,
      leaveCategory: json['leave_category'] as String?,
      reasonList: json['reason_list'] as List<dynamic>?,
      mandatoryAttachments: json['mandatory_attachments'] as bool?,
      mandatoryRaiseDays: json['mandatory_raise_days'] as String?,
      status: json['status'] as String?,
      rules: json['rules'] as Map<String, dynamic>?,
      totalLeaves: json['total_leaves'] as int?,
      currentMonthLop: json['current_month_lop'] as int?,
    );
  }

  /// Get the count to display (remaining leaves or allocated leave)
  int get displayCount {
    if (remainingLeaves != null) {
      return remainingLeaves!;
    } else if (allocatedLeave != null) {
      return allocatedLeave!;
    } else if (assignedQuota != null) {
      return assignedQuota!;
    } else if (annualQuota != null) {
      return annualQuota!;
    }
    return 0;
  }
}

/// Leave Types Response Model
class LeaveTypesResponseModel {
  final int? id;
  final int? userId;
  final int? leavePolicyId;
  final String? leavePolicyName;
  final List<LeaveTypeConfigModel> leaveConfig;
  final bool lossOffPay;

  LeaveTypesResponseModel({
    this.id,
    this.userId,
    this.leavePolicyId,
    this.leavePolicyName,
    required this.leaveConfig,
    required this.lossOffPay,
  });

  factory LeaveTypesResponseModel.fromJson(Map<String, dynamic> json) {
    List<LeaveTypeConfigModel> leaveConfig = [];
    if (json['leave_config'] != null && json['leave_config'] is List) {
      leaveConfig = (json['leave_config'] as List)
          .map((item) => LeaveTypeConfigModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return LeaveTypesResponseModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      leavePolicyId: json['leave_policy_id'] as int?,
      leavePolicyName: json['leave_policy_name'] as String?,
      leaveConfig: leaveConfig,
      lossOffPay: json['lossOffPay'] as bool? ?? false,
    );
  }
}

/// Leave Types API Response
class LeaveTypesApiResponse {
  final bool success;
  final String? message;
  final LeaveTypesResponseModel? data;

  LeaveTypesApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory LeaveTypesApiResponse.fromJson(Map<String, dynamic> json) {
    return LeaveTypesApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null
          ? LeaveTypesResponseModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

