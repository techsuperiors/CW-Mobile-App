/// Leave Type Entity
class LeaveType {
  final String leaveType;
  final double count;
  final String leaveCode;
  final double? consumedLeaves;
  final double? totalLeaves;
  final double? annualQuota;
  final double? allocatedQuota;
  final double? allocatedLeave; // Accrued So Far
  final double? remainingLeaves;
  final double? currentMonthLop;

  LeaveType({
    required this.leaveType,
    required this.count,
    required this.leaveCode,
    this.consumedLeaves,
    this.totalLeaves,
    this.annualQuota,
    this.allocatedQuota,
    this.allocatedLeave,
    this.remainingLeaves,
    this.currentMonthLop,
  });
}

/// Leave Types Entity
class LeaveTypes {
  final List<LeaveType> leaveTypes;
  final bool lossOffPay;

  LeaveTypes({required this.leaveTypes, required this.lossOffPay});

  double get totalLeaves {
    return leaveTypes.fold<double>(0, (sum, type) => sum + type.count);
  }
}
