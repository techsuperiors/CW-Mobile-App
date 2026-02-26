/// Leave Type Entity
class LeaveType {
  final String leaveType;
  final int count;
  final String leaveCode;
  final int? consumedLeaves;
  final int? totalLeaves;
  final int? annualQuota;
  final int? allocatedQuota;
  final int? remainingLeaves;
  final int? currentMonthLop;

  LeaveType({
    required this.leaveType,
    required this.count,
    required this.leaveCode,
    this.consumedLeaves,
    this.totalLeaves,
    this.annualQuota,
    this.allocatedQuota,
    this.remainingLeaves,
    this.currentMonthLop,
  });
}

/// Leave Types Entity
class LeaveTypes {
  final List<LeaveType> leaveTypes;
  final bool lossOffPay;

  LeaveTypes({
    required this.leaveTypes,
    required this.lossOffPay,
  });

  int get totalLeaves {
    return leaveTypes.fold<int>(0, (sum, type) => sum + type.count);
  }
}

