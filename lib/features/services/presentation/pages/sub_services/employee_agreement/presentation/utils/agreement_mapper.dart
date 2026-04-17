import '../../domain/entities/agreement.dart';
import '../../domain/models/employee_agreement_model.dart';
import '../../../../../../../../core/constants/app_assets.dart';

/// Mapper to convert Agreement entity to EmployeeAgreementModel
class AgreementMapper {
  /// Convert Agreement entity to EmployeeAgreementModel
  static EmployeeAgreementModel toEmployeeAgreementModel(Agreement agreement) {
    // Format expiry date from "2026-01-27" to "27/Jan/2026"
    String formattedExpiryDate = '';
    if (agreement.expiryDate != null && agreement.expiryDate!.isNotEmpty) {
      try {
        final dateParts = agreement.expiryDate!.split('-');
        if (dateParts.length == 3) {
          final year = dateParts[0];
          final month = _getMonthAbbreviation(int.parse(dateParts[1]));
          final day = dateParts[2];
          formattedExpiryDate = '$day $month $year';
        } else {
          formattedExpiryDate = agreement.expiryDate!;
        }
      } catch (e) {
        formattedExpiryDate = agreement.expiryDate!;
      }
    }

    // Note: Using placeholder avatar since the card widget uses AssetImage
    // which only supports local assets. If network images are needed,
    // update the card widget to use NetworkImage or cached_network_image
    return EmployeeAgreementModel(
      id: agreement.id,
      agreementName: agreement.agreementName,
      employeeName: agreement.agreementAssignedTo.fullName,
      employeeAvatar: agreement.agreementAssignedTo.imageUrl ?? AppAssets.placeholderAvatar,
      employeeProfileColor: agreement.agreementAssignedTo.profileColor,
      agreementType: agreement.category,
      assignedBy: agreement.agreementAssignedBy.fullName,
      assignedByAvatar: agreement.agreementAssignedBy.imageUrl?? AppAssets.placeholderAvatar,
      assignedByProfileColor: agreement.agreementAssignedBy.profileColor,
      expiryDate: formattedExpiryDate.isNotEmpty ? formattedExpiryDate : 'N/A',
      status: agreement.agreementStatus,
      content: agreement.agreementContent,
      signatureUrl: agreement.signatureUrl,
      documentUrl: agreement.documentUrl,
    );
  }

  /// Get month abbreviation
  static String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Jan';
  }
}
