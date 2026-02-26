import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Dashboard chart section widget
class DashboardChartSection extends StatelessWidget {
  final DashboardStats stats;

  const DashboardChartSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.analytics,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
        ResponsiveBuilder(
          builder: (context, isMobile) {
              return Column(
                children: [
                  _buildChartCard(context, AppStrings.attendanceOverview),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.015), // 1.5% of screen height
                  _buildChartCard(context, AppStrings.leaveTrends),
                ],
              );

          },
        ),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context, String title) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04), // 4% of screen width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
            // Placeholder for chart - can be replaced with actual chart library
            Container(
              height: MediaQuery.of(context).size.height * 0.19, // 19% of screen height
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  AppStrings.chartPlaceholder,
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

