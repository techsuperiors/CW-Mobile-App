import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/ticket_model.dart';

/// Priority ticket count model
class PriorityTicketCount {
  final String priority;
  final int count;
  final Color color;

  PriorityTicketCount({
    required this.priority,
    required this.count,
    required this.color,
  });
}

/// Priority tickets chart widget
class PriorityTicketsChart extends StatelessWidget {
  final List<TicketModel> tickets;

  const PriorityTicketsChart({super.key, required this.tickets});

  /// Calculate priority counts from tickets
  List<PriorityTicketCount> _calculatePriorityCounts(
    List<TicketModel> tickets,
  ) {
    // Count tickets by priority
    final Map<String, int> priorityMap = {};
    for (var ticket in tickets) {
      final priority = ticket.priority.toLowerCase();
      priorityMap[priority] = (priorityMap[priority] ?? 0) + 1;
    }

    // Define priority order and colors
    final priorityOrder = ['critical', 'high', 'medium', 'low'];
    final priorityColors = {
      'critical': AppColors.error,
      'high': AppColors.primary,
      'medium': AppColors.warning,
      'low': AppColors.success,
    };

    // Create PriorityTicketCount list in order
    return priorityOrder.map((priority) {
      final count = priorityMap[priority] ?? 0;
      return PriorityTicketCount(
        priority: priority,
        count: count,
        color: priorityColors[priority] ?? AppColors.textSecondary,
      );
    }).toList();
  }

  /// Capitalize first letter of priority
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final priorityCounts = _calculatePriorityCounts(tickets);

    // Calculate max count for chart scaling
    final maxCount =
        priorityCounts.isEmpty
            ? 1
            : priorityCounts
                .map((e) => e.count)
                .reduce((a, b) => a > b ? a : b);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title
          Text(
            'Priority Tickets',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          // Chart using fl_chart
          if (priorityCounts.isEmpty)
            SizedBox(
              height: screenHeight * 0.2,
              child: Center(
                child: Text(
                  'No tickets available',
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: screenHeight * 0.2,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxCount.toDouble() + 1,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < priorityCounts.length) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: screenHeight * 0.01,
                              ),
                              child: Text(
                                _capitalizeFirst(
                                  priorityCounts[index].priority,
                                ),
                                style: AppTextStyles.labelSmall(
                                  context,
                                ).copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: screenHeight * 0.04,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: screenWidth * 0.08,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) {
                            return const Text('');
                          }
                          return Text(
                            value.toInt().toString(),
                            style: AppTextStyles.labelSmall(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: AppColors.border, strokeWidth: 1);
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 1),
                      left: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  barGroups:
                      priorityCounts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final priority = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: priority.count.toDouble(),
                              color: priority.color,
                              width: screenWidth * 0.08,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
