import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/attendance_details.dart';

/// Punch details widget with 2x2 grid layout
class PunchDetails extends StatelessWidget {
  final AttendanceDetails? attendanceDetails;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const PunchDetails({
    super.key,
    this.attendanceDetails,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.042), // ~4.2% of screen width
      child: isLoading
          ? SizedBox(
              height: screenHeight * 0.15,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : errorMessage != null
              ? SizedBox(
                  height: screenHeight * 0.15,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: AppTextStyles.bodyMediumHeading(context).copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onRefresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: screenWidth * 0.027, // ~2.7% of screen width
                  mainAxisSpacing:
                      screenHeight * 0.015, // 1.5% of screen height
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  childAspectRatio: 2.3,
                  children: [
                    _buildPunchCard(
                      context,
                      time: attendanceDetails?.formattedPunchIn ?? '-',
                      label: AppStrings.punchIn,
                      icon: AppAssets.iconPunchIn,
                      iconColor: AppColors.primary,
                      backgroundColor: AppColors.attendanceLightBlueBg,
                      borderColor: AppColors.primary,
                    ),
                    _buildPunchCard(
                      context,
                      time: attendanceDetails?.formattedPunchOut ?? '-',
                      label: AppStrings.punchOut,
                      icon: AppAssets.iconPunchOut,
                      iconColor: AppColors.success,
                      backgroundColor: AppColors.attendanceLightGreenBg,
                      borderColor: AppColors.success,
                    ),
                    _buildPunchCard(
                      context,
                      time: attendanceDetails?.formattedBreakTime ?? '-',
                      label: AppStrings.breakTime,
                      icon: AppAssets.iconBreak,
                      iconColor: AppColors.warning,
                      backgroundColor: AppColors.attendanceLightOrangeBg,
                      borderColor: AppColors.warning,
                    ),
                    _buildPunchCard(
                      context,
                      time: attendanceDetails?.formattedOverTime ?? '-',
                      label: AppStrings.overtime,
                      icon: AppAssets.iconOvertime,
                      iconColor: AppColors.error,
                      backgroundColor: AppColors.attendanceLightRedBg,
                      borderColor: AppColors.error,
                    ),
                  ],
                ),
    );
  }

  Widget _buildPunchCard(
    BuildContext context, {
    required String time,
    required String label,
    required String icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.032), // ~3.2% of screen width
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with optional progress indicator
          SvgPicture.asset(
            icon,
            fit: BoxFit.contain,
          ),
          // Time and label
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.0025), // 0.25% of screen height
                Text(
                  label,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}