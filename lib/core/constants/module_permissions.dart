class ModulePermissions {
  ModulePermissions._();

  static const leaveRequest = [
    'Leave Management:My Leaves:Read',
    'Leave Management:My Leaves:Write',
  ];

  static const leaveApproval = [
    'Approvals:Team Leaves:Read',
    'Approvals:Team Leaves:Write',
  ];

  static const wfhRequest = [
    'Attendance:WFH Request:Read',
    'Attendance:WFH Request:Write',
  ];

  static const wfhApproval = [
    'Approvals:WFH Request:Read',
    'Approvals:WFH Request:Write',
  ];

  static const regularizeRequest = [
    'Attendance:Regularize:Read',
    'Attendance:Regularize:Write',
  ];

  static const regularizeApproval = [
    'Approvals:Regularize Request:Read',
    'Approvals:Regularize Request:Write',
  ];

  static const onDutyRequest = [
    'Attendance:On Duty Request:Read',
    'Attendance:On Duty Request:Write',
  ];

  static const onDutyApproval = [
    'Approvals:On Duty Request:Read',
    'Approvals:On Duty Request:Write',
  ];

  static const overtimeRequest = [
    'Attendance:Overtime Request:Read',
    'Attendance:Overtime Request:Write',
  ];

  static const overtimeApproval = [
    'Approvals:Overtime Request:Read',
    'Approvals:Overtime Request:Write',
  ];

  static const compOffRequest = [
    'Leave Management:My Comp Off:Read',
    'Leave Management:My Comp Off:Write',
  ];

  static const compOffApproval = [
    'Approvals:Team Comp-Off:Read',
    'Approvals:Team Comp-Off:Write',
  ];

  static const anyApprovalAccess = [
    ...leaveApproval,
    ...wfhApproval,
    ...regularizeApproval,
    ...onDutyApproval,
    ...overtimeApproval,
    ...compOffApproval,
  ];
}
