/// Employee Agreement model
class EmployeeAgreementModel {
  final int id;
  final String employeeName;
  final String employeeAvatar;
  final String agreementType;
  final String assignedBy;
  final String assignedByAvatar;
  final String expiryDate;
  final String status;
  final String? content; // Agreement content text

  const EmployeeAgreementModel({
    required this.id,
    required this.employeeName,
    required this.employeeAvatar,
    required this.agreementType,
    required this.assignedBy,
    required this.assignedByAvatar,
    required this.expiryDate,
    required this.status,
    this.content,
  });
}

