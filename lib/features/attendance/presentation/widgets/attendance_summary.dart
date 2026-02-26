import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Attendance summary card with data points and multi-layered circular progress
class AttendanceSummary extends StatelessWidget {
  const AttendanceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.042), // ~4.2% of screen width
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.053), // ~5.3% of screen width
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
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [
                AppColors.background,
                AppColors.background,
                AppColors.attendanceGradientLight.withOpacity(0.3),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side - Title and data points
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    AppStrings.attendance,
                    style: AppTextStyles.heading4(context).copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02), // 2% of screen height
                  // Data points
                  _buildDataPoint(
                    context,
                    value: '15',
                    label: AppStrings.workingDays,
                    color: AppColors.success,
                  ),
                  SizedBox(height: screenHeight * 0.015), // 1.5% of screen height
                  _buildDataPoint(
                    context,
                    value: '10',
                    label: AppStrings.wfhDays,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: screenHeight * 0.015), // 1.5% of screen height
                  _buildDataPoint(
                    context,
                    value: '05',
                    label: AppStrings.leaveDays,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.053), // ~5.3% of screen width
            // Right side - Multi-layered circular progress
            SizedBox(
              width: screenWidth * 0.32, // 32% of screen width
              height: screenWidth * 0.32,
              child: CustomPaint(
                painter: MultiLayerProgressPainter(
                  workingDays: 15,
                  wfhDays: 10,
                  leaveDays: 5,
                  maxDays: 30, // Can be 30 or 31 based on month
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPoint(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.027, // ~2.7% of screen width
            vertical: MediaQuery.of(context).size.height * 0.0075, // 0.75% of screen height
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: AppTextStyles.bodyLarge(context).copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.032), // ~3.2% of screen width
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for multi-layered circular progress chart
class MultiLayerProgressPainter extends CustomPainter {
  final int workingDays;
  final int wfhDays;
  final int leaveDays;
  final int maxDays;

  MultiLayerProgressPainter({
    required this.workingDays,
    required this.wfhDays,
    required this.leaveDays,
    required this.maxDays,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final startAngle = -math.pi / 2; // Start from top (12 o'clock)

    // Calculate progress percentages based on max days
    final ring1Progress = workingDays / maxDays; // Working days
    final ring2Progress = wfhDays / maxDays; // WFH days
    final ring3Progress = leaveDays / maxDays; // Leave days

    // Ring 1 (Outermost) - Green to teal-blue gradient (Working Days)
    final ring1Radius = 55.0;
    final ring1StrokeWidth = 12.0;
    
    _drawProgressRing(
      canvas,
      center: center,
      radius: ring1Radius,
      strokeWidth: ring1StrokeWidth,
      startAngle: startAngle,
      progress: ring1Progress,
      color: AppColors.success,
    );

    // Ring 2 (Second from outside) - Light blue (WFH Days)
    final ring2Radius = 40.0;
    final ring2StrokeWidth = 10.0;
    // All rings start from the same position (top)
    
    _drawProgressRing(
      canvas,
      center: center,
      radius: ring2Radius,
      strokeWidth: ring2StrokeWidth,
      startAngle: startAngle,
      progress: ring2Progress,
      color: AppColors.primary,
    );

    // Ring 3 (Innermost) - Light orange (Leave Days)
    final ring3Radius = 25.0;
    final ring3StrokeWidth = 8.0;
    // All rings start from the same position (top)
    
    _drawProgressRing(
      canvas,
      center: center,
      radius: ring3Radius,
      strokeWidth: ring3StrokeWidth,
      startAngle: startAngle,
      progress: ring3Progress,
      color: AppColors.warning,
    );

    // Draw remaining/unselected portions for all rings
    _drawRemainingPortions(
      canvas,
      center: center,
      ring1Radius: ring1Radius,
      ring1StrokeWidth: ring1StrokeWidth,
      ring1Progress: ring1Progress,
      ring2Radius: ring2Radius,
      ring2StrokeWidth: ring2StrokeWidth,
      ring2Progress: ring2Progress,
      ring3Radius: ring3Radius,
      ring3StrokeWidth: ring3StrokeWidth,
      ring3Progress: ring3Progress,
      startAngle: startAngle,
    );
  }

  void _drawProgressRing(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double strokeWidth,
    required double startAngle,
    required double progress,
    required Color color,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressSweepAngle = 2 * math.pi * progress;

    // Use solid color instead of gradient
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      rect,
      startAngle,
      progressSweepAngle,
      false,
      progressPaint,
    );
  }

  void _drawRemainingPortions(
    Canvas canvas, {
    required Offset center,
    required double ring1Radius,
    required double ring1StrokeWidth,
    required double ring1Progress,
    required double ring2Radius,
    required double ring2StrokeWidth,
    required double ring2Progress,
    required double ring3Radius,
    required double ring3StrokeWidth,
    required double ring3Progress,
    required double startAngle,
  }) {
    // Ring 1 remaining - starts after ring1 progress ends
    final ring1Remaining = 1.0 - ring1Progress;
    if (ring1Remaining > 0) {
      final ring1RemainingStart = startAngle + (2 * math.pi * ring1Progress);
      _drawRemainingRing(
        canvas,
        center: center,
        radius: ring1Radius,
        strokeWidth: ring1StrokeWidth,
        startAngle: ring1RemainingStart,
        sweepAngle: 2 * math.pi * ring1Remaining,
      );
    }

    // Ring 2 remaining - starts after ring2 progress ends
    final ring2Remaining = 1.0 - ring2Progress;
    if (ring2Remaining > 0) {
      final ring2RemainingStart = startAngle + (2 * math.pi * ring2Progress);
      _drawRemainingRing(
        canvas,
        center: center,
        radius: ring2Radius,
        strokeWidth: ring2StrokeWidth,
        startAngle: ring2RemainingStart,
        sweepAngle: 2 * math.pi * ring2Remaining,
      );
    }

    // Ring 3 remaining - starts after ring3 progress ends
    final ring3Remaining = 1.0 - ring3Progress;
    if (ring3Remaining > 0) {
      final ring3RemainingStart = startAngle + (2 * math.pi * ring3Progress);
      _drawRemainingRing(
        canvas,
        center: center,
        radius: ring3Radius,
        strokeWidth: ring3StrokeWidth,
        startAngle: ring3RemainingStart,
        sweepAngle: 2 * math.pi * ring3Remaining,
      );
    }
  }

  void _drawRemainingRing(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double strokeWidth,
    required double startAngle,
    required double sweepAngle,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Create gradient for remaining arc
    final remainingGradient = SweepGradient(
      center: Alignment.center,
      startAngle: startAngle,
      colors: [
        AppColors.background,
        AppColors.attendanceVeryLightGrey,
        AppColors.attendanceGreyDepth,
        AppColors.attendanceVeryLightGrey,
        AppColors.background,
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    // Draw shadow
    final shadowPaint = Paint()
      ..color = AppColors.textPrimary.withOpacity(0.08)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..isAntiAlias = true;

    canvas.save();
    canvas.translate(1.5, 1.5);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      shadowPaint,
    );
    canvas.restore();

    // Draw border
    final borderPaint = Paint()
      ..color = AppColors.attendanceLightGreyBorder
      ..strokeWidth = strokeWidth + 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      borderPaint,
    );

    // Draw remaining arc with gradient
    final remainingPaint = Paint()
      ..shader = remainingGradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      remainingPaint,
    );

    // Draw inner highlight
    final innerHighlightRadius = radius - (strokeWidth / 2) + 0.5;
    final innerHighlightPaint = Paint()
      ..color = AppColors.background.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerHighlightRadius),
      startAngle,
      sweepAngle,
      false,
      innerHighlightPaint,
    );
  }

  @override
  bool shouldRepaint(MultiLayerProgressPainter oldDelegate) {
    return oldDelegate.workingDays != workingDays ||
        oldDelegate.wfhDays != wfhDays ||
        oldDelegate.leaveDays != leaveDays ||
        oldDelegate.maxDays != maxDays;
  }
}
