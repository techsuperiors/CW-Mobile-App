import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../pages/apply_leave_page.dart';
import '../pages/regularize_page.dart';

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
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.020),
      padding: EdgeInsets.all(screenWidth * 0.042),
      decoration: BoxDecoration(
        color: AppColors.background,
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
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // TSC Shift Timings
          Text(
            'TSC Shift Timings',
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '09:30 AM - 07:30 PM',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.025,
                  vertical: screenHeight * 0.005,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
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
          // Divider
          Divider(color: AppColors.border, height: 1),
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
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    '10 hr',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
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
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    '09 hr',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegularizePage(selectedDate: selectedDate),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.edit,
                    size: screenWidth * 0.03,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    AppStrings.regularize,
                    style: AppTextStyles.buttonSmall(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ApplyLeavePage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.calendar_today,
                    size: screenWidth * 0.03,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    AppStrings.applyLeave,
                    style: AppTextStyles.buttonSmall(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.025),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // Day Logs
          _buildSectionTitle(context, 'Day Logs'),
          SizedBox(height: screenHeight * 0.01),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Outgoing (Punch-out)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogEntry(context, '10:30:31 AM', true, false),
                    _buildLogEntry(context, '01:02:42 PM', true, false),
                    _buildLogEntry(context, '05:01:25 PM', true, false),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              // Right Column: Incoming (Punch-in)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogEntry(context, '11:27:58 AM', false, false),
                    _buildLogEntry(context, '01:58:56 PM', false, false),
                    _buildLogEntry(context, '--:--:--', false, true), // Missing punch-out
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // Adjusted Logs
          _buildSectionTitle(context, 'Adjusted Logs'),
          SizedBox(height: screenHeight * 0.01),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Outgoing (Punch-out)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogEntry(context, '09:30:25 AM', true, false),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              // Right Column: Incoming (Punch-in)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogEntry(context, '--:--:--', false, true), // Missing punch-out
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // Actual Hours and Break Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Actual Gross hour and Break Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actual Gross hour',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      '--',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // Break Time with icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'T',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Break Time',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              '40 min',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right Column: Actual Effective hour
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Actual Effective hour',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      '--',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
          // Checkmark for punch-in, upward arrow for punch-out
          if (isPunchIn)
            Text(
              '✓',
              style: TextStyle(
                fontSize: AppTextStyles.bodySmall(context).fontSize,
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '↗',
              style: TextStyle(
                fontSize: AppTextStyles.bodySmall(context).fontSize,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          SizedBox(width: screenWidth * 0.02),
          if (isDashed)
            Expanded(
              child: Text(
                time,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Text(
              time,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textSecondary,
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

