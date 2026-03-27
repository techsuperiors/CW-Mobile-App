import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/payslip_model.dart';
import '../pages/payslip_pdf_viewer_page.dart';

/// Card widget for displaying payslip
class PayslipCard extends StatelessWidget {
  final PayslipModel payslip;

  const PayslipCard({super.key, required this.payslip});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final canOpen =
        payslip.payslipVisible && payslip.template.trim().isNotEmpty;

    return GestureDetector(
      onTap:
          canOpen
              ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PayslipPdfViewerPage(payslip: payslip),
                  ),
                );
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  AppAssets.payslipThumbnailImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.004,
                horizontal: screenWidth * 0.02,
              ),
              child: Text(
                payslip.displayName,
                style: AppTextStyles.bodyMediumHeading(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
