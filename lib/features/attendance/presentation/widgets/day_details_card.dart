import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Day details card showing shift timings, logs, and actions
class DayDetailsCard extends StatelessWidget {
  final DateTime selectedDate;

  const DayDetailsCard({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final formattedDate = DateFormat('d MMMM yyyy').format(selectedDate);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.042),
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
          // Date title
          Text(
            formattedDate,
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          // TSC Shift Timings
          Row(
            children: [
              Text(
                'TSC Shift Timings: ',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '09:30 AM - 07:30 PM',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.025,
                  vertical: screenHeight * 0.005,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.success,
                    width: 1,
                  ),
                ),
                child: Text(
                  AppStrings.wfh,
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Expected Hours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expected Gross hours',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    '10 hr',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expected Effective hours',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    '09 hr',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Handle regularize
                  },
                  icon: Icon(
                    Icons.edit,
                    size: screenWidth * 0.04,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    AppStrings.regularize,
                    style: AppTextStyles.buttonMedium(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Handle apply leave
                  },
                  icon: Icon(
                    Icons.business,
                    size: screenWidth * 0.04,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    AppStrings.applyLeave,
                    style: AppTextStyles.buttonMedium(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.025),
          // Day Logs
          _buildSectionTitle(context, 'Day Logs'),
          SizedBox(height: screenHeight * 0.01),
          _buildLogEntry(context, '10:30:31 AM', true, false),
          _buildLogEntry(context, '11:27:58 AM', false, false),
          _buildLogEntry(context, '01:02:42 PM', true, false),
          _buildLogEntry(context, '01:58:56 PM', false, false),
          _buildLogEntry(context, '05:01:25 PM', true, false),
          _buildLogEntry(context, '--', false, true), // Dashed line for missing
          SizedBox(height: screenHeight * 0.02),
          // Adjusted Logs
          _buildSectionTitle(context, 'Adjusted Logs'),
          SizedBox(height: screenHeight * 0.01),
          _buildLogEntry(context, '09:30:25 AM', true, false),
          _buildLogEntry(context, '--', false, true), // Dashed line for missing
          SizedBox(height: screenHeight * 0.02),
          // Actual Hours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actual Gross hour',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    '--',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Actual Effective hour',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    '--',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Break Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Break Time',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '40 min',
                style: AppTextStyles.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium(context).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, String time, bool isPunchIn, bool isDashed) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.008),
      child: Row(
        children: [
          Icon(
            isPunchIn ? Icons.arrow_forward : Icons.arrow_back,
            size: screenWidth * 0.04,
            color: isPunchIn ? AppColors.success : AppColors.error,
          ),
          SizedBox(width: screenWidth * 0.02),
          if (isDashed)
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: CustomPaint(
                  painter: DashedLinePainter(),
                ),
              ),
            )
          else
            Text(
              time,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

