import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';

/// Donut chart widget for displaying leave statistics
class DonutChartWidget extends StatelessWidget {
  final double percentage;
  final double totalLeaves;
  final Color color;
  final bool islop;

  const DonutChartWidget({
    super.key,
    required this.percentage,
    required this.totalLeaves,
    required this.color,
    this.islop = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;
    final chartSize = smallerDimension * 0.333; // ~33.3% of smaller dimension

    return SizedBox(
      width: chartSize,
      height: chartSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(chartSize, chartSize),
            painter: _DonutChartPainter(percentage: percentage, color: color),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                islop ? 'Total LOP' : 'Available',
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: screenHeight * 0.005), // 0.5% of screen height
              Text(
                "${totalLeaves.toStringAsFixed(2)} Day(s)",
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double percentage;
  final Color color;

  _DonutChartPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 12.0;

    // Background circle (remaining portion)
    final backgroundPaint =
        Paint()
          ..color = color.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Foreground circle (filled portion)
    final foregroundPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    // Draw background circle (full circle)
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw filled portion
    if (percentage > 0) {
      final sweepAngle = 2 * math.pi * percentage;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        foregroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
