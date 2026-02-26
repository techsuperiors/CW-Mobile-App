/// Payslip model for payslip page
class PayslipModel {
  final int id;
  final String month;
  final String year;
  final String thumbnailUrl; // URL for thumbnail image
  final String pdfUrl; // URL for PDF file
  final String displayName; // e.g., "Jan 2025"

  const PayslipModel({
    required this.id,
    required this.month,
    required this.year,
    required this.thumbnailUrl,
    required this.pdfUrl,
    required this.displayName,
  });
}

