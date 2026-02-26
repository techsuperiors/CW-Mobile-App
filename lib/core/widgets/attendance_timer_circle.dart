import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Reusable attendance timer circle widget
/// Shows progress based on worked hours vs shift hours
class AttendanceTimerCircle extends StatelessWidget {
  /// Total worked hours (in hours, e.g., 7.5 for 7 hours 30 minutes)
  final double workedHours;
  
  /// Shift hours (default 8 hours)
  final double shiftHours;
  
  /// Size of the circle (default 90)
  final double size;

  const AttendanceTimerCircle({
    super.key,
    required this.workedHours,
    this.shiftHours = 8.0,
    this.size = 90,
  });

  /// Calculate progress (0.0 to 1.0)
  double get _progress {
    if (shiftHours <= 0) return 0.0;
    final double progress = workedHours / shiftHours;
    return progress.clamp(0.0, 1.0);
  }

  /// Format worked hours to HH:MM string
  String get _formattedTime {
    final hours = workedHours.floor();
    final minutes = ((workedHours - hours) * 60).round();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Inner circle with gradient border, inset shadows, and background gradient
          Stack(
            children: [
              // Outer circle with gradient border (0.86px)
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    // 44.27deg gradient for border
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.attendanceAlmostWhite,
                      AppColors.attendanceLightBlueGrey,
                    ],
                    stops: const [0.273, 0.8825],
                  ),
                ),
              ),
              // Inner circle with background gradient and inset shadows
              Center(
                child: Container(
                  width: size - (0.86 * 2), // Subtract border width
                  height: size - (0.86 * 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.attendanceGreyBlue,
                        AppColors.attendanceVeryLightGreyBlue,
                      ],
                    ),
                    boxShadow: [
                      // First inset shadow
                      BoxShadow(
                        color: AppColors.attendanceLightBlueGrey.withOpacity(0.71),
                        blurRadius: 25.76,
                        spreadRadius: -0.86,
                        offset: const Offset(8.59, 9.45),
                      ),
                      // Second inset shadow
                      BoxShadow(
                        color: AppColors.attendanceLightBlueGrey.withOpacity(0.52),
                        blurRadius: 6.87,
                        spreadRadius: 0,
                        offset: const Offset(6.01, 6.01),
                      ),
                      // Third inset shadow (negative offset for inset effect)
                      BoxShadow(
                        color: AppColors.background.withOpacity(0.2),
                        blurRadius: 25.76,
                        spreadRadius: 0,
                        offset: const Offset(-10.31, -10.31),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Progress ring
          CustomPaint(
            size: Size(size, size),
            painter: CircularProgressPainter(
              progress: _progress,
              progressColor: AppColors.success,
              remainingColor: AppColors.background,
              strokeWidth: 10,
            ),
          ),
          // Time text
          Center(
            child: Text(
              _formattedTime,
              style: AppTextStyles.heading5(context).copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.attendanceTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for circular progress indicator with two colors
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color remainingColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.remainingColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final startAngle = -math.pi / 2; // Start from top (12 o'clock)
    final progressSweepAngle = 2 * math.pi * progress;

    // Create SweepGradient with smooth color blending
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final progressGradient = SweepGradient(
      center: Alignment.center,
      startAngle: startAngle, // Align with arc start
      colors: [
        AppColors.successDark,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.success,
        AppColors.accent,
        AppColors.accent,
        AppColors.accent,
        AppColors.accent,
        AppColors.accent,
        AppColors.accent,
        AppColors.accentLight,
      ],
      stops: const [
        0.0, 0.067, 0.133, 0.2, 0.267, 0.333, 0.4, 0.467, 0.533, 0.6, 0.667, 0.733, 0.8, 0.867, 0.933, 1.0
      ],
    );

    // Draw progress arc with gradient
    final progressPaint = Paint()
      ..shader = progressGradient.createShader(rect)
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

    // Draw remaining arc with gradient, border, and shadow
    final remainingSweepAngle = 2 * math.pi * (1 - progress);
    
    if (remainingSweepAngle > 0) {
      // Calculate the angle for the remaining arc
      final remainingStartAngle = startAngle + progressSweepAngle;
      
      // Create gradient for remaining arc (white with subtle gradient for depth)
      final remainingGradient = SweepGradient(
        center: Alignment.center,
        startAngle: remainingStartAngle,
        colors: [
          AppColors.background,
          AppColors.attendanceVeryLightGrey,
          AppColors.attendanceGreyDepth,
          AppColors.attendanceVeryLightGrey,
          AppColors.background,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      );

      // Draw shadow layer for remaining arc (creates depth effect)
      final shadowPaint = Paint()
        ..color = AppColors.textPrimary.withOpacity(0.1)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
        ..isAntiAlias = true;

      // Draw shadow with slight offset to create depth
      canvas.save();
      canvas.translate(2.0, 2.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        remainingStartAngle,
        remainingSweepAngle,
        false,
        shadowPaint,
      );
      canvas.restore();

      // Draw light border as base layer (creates visible edge definition)
      final borderBasePaint = Paint()
        ..color = AppColors.attendanceLightGreyBorder
        ..strokeWidth = strokeWidth + 2.0 // Slightly larger for visible border
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        remainingStartAngle,
        remainingSweepAngle,
        false,
        borderBasePaint,
      );

      // Draw remaining arc with internal gradient (main fill) on top of border
      final remainingPaint = Paint()
        ..shader = remainingGradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        remainingStartAngle,
        remainingSweepAngle,
        false,
        remainingPaint,
      );

      // Draw inner highlight for premium 3D effect
      final innerHighlightRadius = radius - (strokeWidth / 2) + 0.5;
      final innerHighlightPaint = Paint()
        ..color = AppColors.background.withOpacity(0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerHighlightRadius),
        remainingStartAngle,
        remainingSweepAngle,
        false,
        innerHighlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.remainingColor != remainingColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
