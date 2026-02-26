import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/ticket_model.dart';

/// Ticket summary card widget
class TicketSummaryCard extends StatelessWidget {
  final TicketSummary summary;

  const TicketSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
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
      child: Row(
        children: [
          // Icon
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: summary.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              summary.icon,
              color: summary.color,
              size: screenWidth * 0.06,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          // Text and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.type,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  '${summary.count}',
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Mini chart (simplified bar chart)
          SizedBox(
            width: screenWidth * 0.12,
            height: screenWidth * 0.08,
            child: CustomPaint(
              painter: MiniBarChartPainter(
                color: summary.color,
                value: summary.count / 20.0, // Normalize to 0-1
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for mini bar chart
class MiniBarChartPainter extends CustomPainter {
  final Color color;
  final double value;

  MiniBarChartPainter({
    required this.color,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 4;
    final spacing = barWidth * 0.2;
    final maxHeight = size.height;

    // Draw 4 bars with increasing heights
    for (int i = 0; i < 4; i++) {
      final height = maxHeight * (0.3 + (i * 0.2) * value);
      final x = i * (barWidth + spacing);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, maxHeight - height, barWidth, height),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

