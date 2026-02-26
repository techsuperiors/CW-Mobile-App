import '../../domain/models/payslip_model.dart';

/// Payslip data provider - can be replaced with API call
class PayslipData {
  static List<PayslipModel> getPayslips() {
    // Sample PDF URLs from internet (using sample PDFs)
    // Sample thumbnail URLs (using placeholder image service)
    final baseThumbnailUrl = 'https://via.placeholder.com/300x400/4A90E2/FFFFFF?text=';
    // Using a reliable sample PDF URL
    final basePdfUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
    
    final months = [
      'Jan', 'Feb', 'March', 'April', 'May', 'June',
      'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'
    ];
    
    final year = '2025';
    
    return List.generate(12, (index) {
      final month = months[index];
      final displayText = '$month%20$year';
      return PayslipModel(
        id: index + 1,
        month: month,
        year: year,
        thumbnailUrl: '$baseThumbnailUrl$displayText',
        pdfUrl: basePdfUrl, // Using same sample PDF for all months
        displayName: '$month $year',
      );
    });
  }
}

