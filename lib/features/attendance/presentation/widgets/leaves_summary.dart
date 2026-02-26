import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
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
        'color': _getColorForLeaveType(type.leaveType),
      };
    }).toList();
  }

  int _getTotalLeaves() {
    final mappedTypes = _getMappedLeaveTypes();
    return mappedTypes.fold<int>(0, (sum, type) => sum + (type['count'] as int));
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
    }
    // Default color for unknown types
    return AppColors.serviceTeal;
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Leaves',
              style: AppTextStyles.heading4(context).copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02, // 2% of screen height
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
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.error,
                        ),
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
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              // Content: Legend and Chart
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Legend
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _getMappedLeaveTypes().map((type) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.015), // 1.5% of screen height
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
                                '${type['label']} (${(type['count'] as int).toString().padLeft(2, '0')})',
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  color: AppColors.textSecondary,
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
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 0.40, // 40% of screen width
                        width: MediaQuery.of(context).size.width * 0.40,
                        child: CustomPaint(
                          painter: DonutChartPainter(leaveTypes: _getMappedLeaveTypes()),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01), // 1% of screen height
                      // Total Leaves
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _getTotalLeaves().toString(),
                              style: AppTextStyles.heading3(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.011), // ~1.1% of screen width
                          Flexible(
                            child: Text(
                              'Total Leaves',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
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
    )/*Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: ResponsiveUtils.responsiveCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Leaves',
              style: AppTextStyles.heading4(context).copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02, // 2% of screen height
            ),
            // Content: Legend and Chart
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Legend
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: leaveTypes.map((type) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.015), // 1.5% of screen height
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
                                '${type['label']} (${(type['count'] as int).toString().padLeft(2, '0')})',
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  color: AppColors.textSecondary,
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
                  flex: 1,
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.width * 0.40, // 40% of screen width
                        width: MediaQuery.of(context).size.width * 0.40,
                        child: CustomPaint(
                          painter: DonutChartPainter(leaveTypes: leaveTypes),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01), // 1% of screen height
                      // Total Leaves
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            totalLeaves.toString(),
                            style: AppTextStyles.heading2(context).copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Total Leaves',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: Colors.grey[600],
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
    )*/;
  }
}

/// Custom painter for donut chart
class DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> leaveTypes;

  DonutChartPainter({required this.leaveTypes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    final total = leaveTypes.fold<int>(0, (sum, type) => sum + (type['count'] as int));
    var startAngle = -math.pi / 2;
    
    for (final type in leaveTypes) {
      final value = type['count'] as int;
      final color = type['color'] as Color;
      final sweepAngle = (value / total) * 2 * math.pi;
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => false;
}


