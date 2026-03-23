import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Attendance summary card with individual circular progress rings
class AttendanceSummary extends StatelessWidget {
  final int workingDays;
  final int wfhDays;
  final int leaveDays;
  final int maxDays;
  final bool isLoading;
  final DateTime? selectedDate;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  const AttendanceSummary({
    super.key,
    this.selectedDate,
    this.onPreviousMonth,
    this.onNextMonth,
    this.workingDays = 0,
    this.wfhDays = 0,
    this.leaveDays = 0,
    this.maxDays = 30,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final now = DateTime.now();
    final monthYearStr =
        "${_getMonthName(selectedDate?.month ?? now.month)} ${selectedDate?.year ?? now.year}";
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.042),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.053),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            SizedBox(height: screenHeight * 0.008),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.attendance,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    GestureDetector(
                      onTap: onPreviousMonth,
                      child: Icon(
                        Icons.chevron_left,
                        color: AppColors.calendararrow,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    Text(
                      monthYearStr,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                    // Display actual month
                    GestureDetector(
                      onTap: onNextMonth,
                      child: Icon(
                        Icons.chevron_right,
                        color: AppColors.calendararrow,
                        size: screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.016),
            // Three individual ring cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRingCard(
                  context,
                  label: AppStrings.workingDays,
                  value:
                      isLoading ? '--' : workingDays.toString().padLeft(2, '0'),
                  progress: isLoading ? 0 : workingDays / maxDays,
                  color: AppColors.success,
                  trackColor: AppColors.success.withOpacity(0.15),
                ),
                _buildRingCard(
                  context,
                  label: AppStrings.wfhDays,
                  value: isLoading ? '--' : wfhDays.toString().padLeft(2, '0'),
                  progress: isLoading ? 0 : wfhDays / maxDays,
                  color: AppColors.primary,
                  trackColor: AppColors.primary.withOpacity(0.15),
                ),
                _buildRingCard(
                  context,
                  label: AppStrings.leaveDays,
                  value:
                      isLoading ? '--' : leaveDays.toString().padLeft(2, '0'),
                  progress: isLoading ? 0 : leaveDays / maxDays,
                  color: AppColors.warning,
                  trackColor: AppColors.warning.withOpacity(0.15),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.008),

          ],
        ),
      ),
    );
  }

  Widget _buildRingCard(
    BuildContext context, {
    required String label,
    required String value,
    required double progress,
    required Color color,
    required Color trackColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ringSize = screenWidth * 0.26;
    final innerContentWidth = ringSize * 0.55;
    return Column(
      children: [
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ring painter
              CustomPaint(
                size: Size(ringSize, ringSize),
                painter: SingleRingProgressPainter(
                  progress: progress,
                  activeColor: color,
                  trackColor: trackColor,
                ),
              ),
              // Center text
              SizedBox(
                width: innerContentWidth,
                // Force a width smaller than the ring itself
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        // Short label inside ring (Working / WFH / Leave)
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        // Standard practice for safety
                        softWrap: true,
                        // Explicitly tell Flutter to wrap
                        style: AppTextStyles.labelSmall(context).copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      value,
                      style: AppTextStyles.heading5(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    return [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ][month - 1];
  }
}

/// Custom painter for a single circular progress ring
class SingleRingProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color activeColor;
  final Color trackColor;

  SingleRingProgressPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 6.0;
    const startAngle = -math.pi / 2; // 12 o'clock

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track (background ring)
    final trackPaint =
        Paint()
          ..color = trackColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    if (progress > 0) {
      final progressSweep = 2 * math.pi * progress.clamp(0.0, 1.0);

      final progressPaint =
          Paint()
            ..color = activeColor
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true;

      canvas.drawArc(rect, startAngle, progressSweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(SingleRingProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
