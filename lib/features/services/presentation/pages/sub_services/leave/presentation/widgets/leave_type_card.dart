import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import 'donut_chart_widget.dart';

/// Card widget for displaying leave type information with donut chart
class LeaveTypeCard extends StatelessWidget {
  final String title;
  final int totalLeaves;
  final int consumed;
  final int allocatedQuota;
  final int annualQuota;
  final Color color;
  final bool isLOP;

  const LeaveTypeCard({
    super.key,
    required this.title,
    required this.totalLeaves,
    required this.consumed,
    required this.allocatedQuota,
    required this.annualQuota,
    required this.color,
    this.isLOP = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = allocatedQuota > 0 ? (consumed / allocatedQuota) : 0.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Info Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.053, // ~5.3% of screen width
                height: MediaQuery.of(context).size.width * 0.053,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.iconInfo,
                    width: MediaQuery.of(context).size.width * 0.032, // ~3.2% of screen width
                    height: MediaQuery.of(context).size.width * 0.032,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryLight,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.025), // 2.5% of screen height
          // Donut Chart
          Center(
            child: DonutChartWidget(
              percentage: percentage,
              totalLeaves: totalLeaves,
              color: color,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.025), // 2.5% of screen height
          // Statistics Table
          isLOP
              ? _buildLOPTable(context)
              : _buildRegularTable(context),
        ],
      ),
    );
  }

  Widget _buildLOPTable(context) {
    return Table(
      border: TableBorder(
        top: const BorderSide(color: AppColors.border, width: 1),
        bottom: const BorderSide(color: AppColors.border, width: 1),
        left: const BorderSide(color: AppColors.border, width: 1),
        right: const BorderSide(color: AppColors.border, width: 1),
        horizontalInside: const BorderSide(color: AppColors.border, width: 1),
      ),
      children: [
        _buildTableRow(context, 'LOP This Month', '02 Days'),
        _buildTableRow(context, 'Total LOP Days', '$allocatedQuota Days'),
      ],
    );
  }

  Widget _buildRegularTable(context) {
    return Table(
      border: TableBorder(
        top: const BorderSide(color: AppColors.border, width: 1),
        bottom: const BorderSide(color: AppColors.border, width: 1),
        left: const BorderSide(color: AppColors.border, width: 1),
        right: const BorderSide(color: AppColors.border, width: 1),
        horizontalInside: const BorderSide(color: AppColors.border, width: 1),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            TableCell(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  
                  // Calculate responsive padding - use smaller percentages for tight spaces
                  final horizontalPadding = availableWidth < 150 
                      ? (availableWidth * 0.02).clamp(4.0, 6.0)
                      : (availableWidth * 0.03).clamp(6.0, 10.0);
                  final verticalPadding = MediaQuery.of(context).size.height * 0.012;
                  
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Consumed',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              fontSize: availableWidth < 150 
                                  ? AppTextStyles.bodySmall(context).fontSize! * 0.9
                                  : AppTextStyles.bodySmall(context).fontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '$consumed Days',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: availableWidth < 150 
                                  ? AppTextStyles.bodySmall(context).fontSize! * 0.9
                                  : AppTextStyles.bodySmall(context).fontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const TableCell(child: SizedBox()),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell(context, 'Allocated Quota', '$allocatedQuota Days'),
            _buildTableCell(context, 'Annual Quota', '$annualQuota Days'),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        _buildTableCell(context, label, value),
      ],
    );
  }

  Widget _buildTableCell(BuildContext context, String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        
        // Calculate responsive padding and spacing - use smaller percentages for tight spaces
        // For very small widths (< 150px), use minimal padding
        final horizontalPadding = availableWidth < 150 
            ? (availableWidth * 0.02).clamp(4.0, 6.0)
            : (availableWidth * 0.03).clamp(6.0, 10.0);
        final verticalPadding = MediaQuery.of(context).size.height * 0.012;
        final spacing = availableWidth < 150 
            ? (availableWidth * 0.01).clamp(2.0, 4.0)
            : (availableWidth * 0.015).clamp(4.0, 6.0);
        
        // Calculate available width after padding
        final contentWidth = availableWidth - (horizontalPadding * 2) - spacing;
        
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    fontSize: availableWidth < 150 
                        ? AppTextStyles.labelSmall(context).fontSize! * 0.9
                        : AppTextStyles.labelSmall(context).fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                flex: 1,
                child: Text(
                  value,
                  style: AppTextStyles.labelSmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: availableWidth < 150 
                        ? AppTextStyles.labelSmall(context).fontSize! * 0.9
                        : AppTextStyles.labelSmall(context).fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

