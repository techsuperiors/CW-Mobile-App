import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/employee_agreement_model.dart';
import '../pages/employee_agreement_detail_page.dart';
import '../bloc/agreement_bloc.dart';

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
      onTap: () async {
        // Navigate to agreement detail page when tapped
        // Pass the bloc using BlocProvider.value so the detail page can access it
        final bloc = context.read<AgreementBloc>();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: bloc,
              child: EmployeeAgreementDetailPage(agreement: agreement),
            ),
          ),
        );
        
        // If consent was submitted successfully, the refresh is already triggered
        // in the detail page, so we don't need to do anything here
        // The BlocBuilder in the list page will automatically update
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
            // Title
            Text(
              agreement.agreementName,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
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

