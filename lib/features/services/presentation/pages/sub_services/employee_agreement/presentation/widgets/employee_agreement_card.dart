import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/employee_agreement_model.dart';
import '../pages/employee_agreement_detail_page.dart';

/// Card widget for displaying employee agreement information
class EmployeeAgreementCard extends StatelessWidget {
  final EmployeeAgreementModel agreement;

  const EmployeeAgreementCard({
    super.key,
    required this.agreement,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to agreement detail page when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeeAgreementDetailPage(agreement: agreement),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042), // ~4.2% of screen width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Kebab Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Assign Agreement',
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: MediaQuery.of(context).size.width * 0.053, // ~5.3% of screen width
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Handle kebab menu tap
                  },
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
            // Employee Name
            _buildDetailRow(
              context,
              'Employee Name',
              agreement.employeeName,
              agreement.employeeAvatar,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
            // Agreement Type
            _buildDetailRow(context,'Agreement Type', agreement.agreementType, null),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
            // Assigned By
            _buildDetailRow(context,
              'Assigned By',
              agreement.assignedBy,
              agreement.assignedByAvatar,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
            // Expiry Date
            _buildDetailRow(context,'Expiry Date', agreement.expiryDate, null),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
            // Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    agreement.status,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(context,String label, String value, String? avatarPath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: screenWidth * 0.267, // ~26.7% of screen width
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // ~4.2% of screen width
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (avatarPath != null) ...[
                SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                CircleAvatar(
                  radius: smallerDimension * 0.033, // ~3.3% of smaller dimension
                  backgroundImage: AssetImage(avatarPath),
                ),
              ],
              SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
              Text(
                value,
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: label == 'Employee Name'
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),

            ],
          ),
        ),
      ],
    );
  }
}

