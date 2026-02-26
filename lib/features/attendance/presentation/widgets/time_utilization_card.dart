import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:intl/intl.dart';

/// Today's Time Utilization card with timer and Punch In button
class TimeUtilizationCard extends StatelessWidget {
  const TimeUtilizationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Get today's date
    final today = DateTime.now();
    final formattedDate = DateFormat('MMMM d yyyy').format(today);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.042), // ~4.2% of screen width
      padding: EdgeInsets.all(screenWidth * 0.042),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Today's Time Utilization",
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.015), // 1.5% of screen height
          // Date
          Text(
            formattedDate,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: screenHeight * 0.02), // 2% of screen height
          // Timer and Punch In button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timer boxes (00 00 00)
              Row(
                children: [
                  _buildTimeBox(context, '00'),
                  SizedBox(width: screenWidth * 0.02),
                  _buildTimeBox(context, '00'),
                  SizedBox(width: screenWidth * 0.02),
                  _buildTimeBox(context, '00'),
                ],
              ),
              // Punch In button
              ElevatedButton(
                onPressed: () {
                  // Handle punch in
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.attendanceTeal,
                  foregroundColor: AppColors.textWhite,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppStrings.punchIn,
                  style: AppTextStyles.buttonMedium(context).copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(BuildContext context, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      width: screenWidth * 0.12, // 12% of screen width
      height: screenHeight * 0.06, // 6% of screen height
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          value,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

