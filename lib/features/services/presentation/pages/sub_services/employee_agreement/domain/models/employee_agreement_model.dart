/// Employee Agreement model
class EmployeeAgreementModel {
  final int id;
  final String agreementName;
  final String employeeName;
  final String employeeAvatar;
  final String? employeeProfileColor;
  final String agreementType;
  final String assignedBy;
  final String assignedByAvatar;
  final String? assignedByProfileColor;
  final String expiryDate;
  final String status;
  final String? content; // Agreement content text
  final String? signatureUrl; // Signature image URL
  final String? documentUrl; // Signature pdf URL

  const EmployeeAgreementModel({
    required this.id,
    required this.agreementName,
    required this.employeeName,
    required this.employeeAvatar,
    this.employeeProfileColor,
    required this.agreementType,
    required this.assignedBy,
    required this.assignedByAvatar,
    this.assignedByProfileColor,
    required this.expiryDate,
    required this.status,
    this.content,
    this.signatureUrl,
    this.documentUrl,
  });
}
