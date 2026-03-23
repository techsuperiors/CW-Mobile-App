import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/payslip_model.dart';
import '../pages/payslip_pdf_viewer_page.dart';

/// Card widget for displaying payslip
class PayslipCard extends StatelessWidget {
  final PayslipModel payslip;

  const PayslipCard({
    super.key,
    required this.payslip,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = (screenWidth - (screenWidth * 0.01 * 3)) / 2; // 2 columns with padding
    final cardHeight = cardWidth * 1.0; 

    final canOpen = payslip.payslipVisible && payslip.template.trim().isNotEmpty;

    return GestureDetector(
      onTap:
          canOpen
              ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PayslipPdfViewerPage(payslip: payslip),
                  ),
                );
              }
              : null,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top icon area
            Expanded(
              child: Center(
                child: Icon(
                  canOpen ? Icons.receipt_long : Icons.receipt_long_outlined,
                  size: screenWidth * 0.12,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
            // Month and Salary Label
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.015,
                horizontal: screenWidth * 0.02,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    payslip.displayName,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    canOpen ? '₹${payslip.netSalary}' : 'Not available',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: canOpen ? AppColors.success : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
