/// Employee Agreement model
class EmployeeAgreementModel {
  final int id;
  final String agreementName;
  final String employeeName;
  final String employeeAvatar;
  final String agreementType;
  final String assignedBy;
  final String assignedByAvatar;
  final String expiryDate;
  final String status;
  final String? content; // Agreement content text
  final String? signatureUrl; // Signature image URL

  const EmployeeAgreementModel({
    required this.id,
    required this.agreementName,
    required this.employeeName,
    required this.employeeAvatar,
    required this.agreementType,
    required this.assignedBy,
    required this.assignedByAvatar,
    required this.expiryDate,
    required this.status,
    this.content,
    this.signatureUrl,
  });
}

