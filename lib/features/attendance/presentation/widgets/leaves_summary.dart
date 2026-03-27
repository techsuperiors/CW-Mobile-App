import 'package:collectivWork/core/extension/string_extensions.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../leaves/domain/entities/leave_type.dart';

/// Leaves summary with donut chart and legend
class LeavesSummary extends StatelessWidget {
  final LeaveTypes? leaveTypes;
  final bool isLoading;
  final String? errorMessage;

  const LeavesSummary({
    super.key,
    this.leaveTypes,
    required this.isLoading,
    this.errorMessage,
  });

  /// Get mapped leave types with colors
  List<Map<String, dynamic>> _getMappedLeaveTypes() {
    if (leaveTypes == null) return [];

    return leaveTypes!.leaveTypes.map((type) {
      return {
        'label': type.leaveType,
        'count': type.count,
        'total': type.totalLeaves ?? type.count,
        'color': _getColorForLeaveType(type.leaveType),
      };
    }).toList();
  }

  double _getTotalLeaves() {
    final mappedTypes = _getMappedLeaveTypes();
    return mappedTypes.fold<double>(
      0.0,
      (sum, type) => sum + (type['count'] as double),
    );
  }

  String _formatLeaveValue(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Color _getColorForLeaveType(String leaveType) {
    final type = leaveType.toLowerCase();
    if (type.contains('sick')) {
      return AppColors.leaveSick;
    } else if (type.contains('casual')) {
      return AppColors.leaveCasual;
    } else if (type.contains('paternity')) {
      return AppColors.leavePaternity;
    } else if (type.contains('earned') || type.contains('el')) {
      return AppColors.leaveEarned;
    } else if (type.contains('paid') || type.contains('holiday')) {
      return AppColors.leavePaidHoliday;
    } else if (type.contains('lop') || type.contains('loss')) {
      return AppColors.error;
    } else if (type.contains('privilege')) {
      return AppColors.leaveprivilage;
    } else if (type.contains('comp-off')) {
      return AppColors.leavecompoff;
    } else if (type.contains('emergency')) {
      return AppColors.leaveEmergency;
    }
    else if (type.contains('ozi')) {
      return AppColors.ozicasualLeave;
    } else if (type.contains('planned')) {
      return AppColors.serviceBlue;
    }
    // Default color for unknown types
    return AppColors.serviceTeal;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.042),
      // ~4.2% of screen width
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.053), // ~5.3% of screen width
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Leaves',
              style: AppTextStyles.heading5(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.02, // 2% of screen height
            ),
            // Content: Loading, Error, or Data
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        errorMessage!,
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_getMappedLeaveTypes().isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No leave types available',
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              // Content: Legend and Chart
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Left side: Legend
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _getMappedLeaveTypes().map((type) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: screenHeight * 0.015,
                          ),
                          // 1.5% of screen height
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: type['color'] as Color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${(type['label'] as String).capitalizeFirst()} (${_formatLeaveValue(type['count'] as double)}/${_formatLeaveValue(type['total'] as double)})',
                                  style: AppTextStyles.bodySmall(context)
                                      .copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w400,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Right side: Donut Chart
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.width *
                              0.30, // 40% of screen width
                          width: MediaQuery.of(context).size.width * 0.32,
                          child: CustomPaint(
                            painter: DonutChartPainter(
                              leaveTypes: _getMappedLeaveTypes(),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        // 1% of screen height
                        // Total Leaves
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getTotalLeaves().toString(),
                              style: AppTextStyles.heading3(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(width: screenWidth * 0.011),
                            // ~1.1% of screen width
                            Flexible(
                              child: Text(
                                'Total Leaves',
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(color: Colors.grey[600]),
                                overflow: TextOverflow.visible,
                                // allow wrapping
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for donut chart with white gaps between segments
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> leaveTypes;

  /// Gap between segments in radians
  static const double _gapAngle = 0.05;

  DonutChartPainter({required this.leaveTypes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final total = leaveTypes.fold<double>(
      0.0,
      (sum, type) => sum + (type['count'] as double),
    );

    if (total == 0) return;

    var startAngle = -math.pi / 2;

    for (final type in leaveTypes) {
      final value = type['count'] as double;
      if (value == 0) continue; // skip zero-value segments

      final color = type['color'] as Color;

      // Full proportional sweep minus the gap on each side
      final fullSweep = (value / total) * 2 * math.pi;
      final sweepAngle = fullSweep - _gapAngle;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap
            .butt // flat ends so gaps stay clean
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (_gapAngle / 2), // center the arc within the gap
        sweepAngle,
        false,
        paint,
      );

      startAngle += fullSweep;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) =>
      oldDelegate.leaveTypes != leaveTypes;
}
