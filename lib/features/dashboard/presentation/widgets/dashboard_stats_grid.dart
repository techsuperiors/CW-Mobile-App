import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/dashboard_stats.dart';
import 'dashboard_stat_card.dart';

/// Dashboard statistics grid widget
class DashboardStatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const DashboardStatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        DashboardStatCard(
          title: AppStrings.totalEmployees,
          value: stats.totalEmployees.toString(),
          icon: Icons.people,
          color: AppColors.statBlue,
        ),
        DashboardStatCard(
          title: AppStrings.presentToday,
          value: stats.presentToday.toString(),
          icon: Icons.check_circle,
          color: AppColors.statGreen,
        ),
        DashboardStatCard(
          title: AppStrings.onLeave,
          value: stats.onLeave.toString(),
          icon: Icons.beach_access,
          color: AppColors.statOrange,
        ),
        DashboardStatCard(
          title: AppStrings.pendingLeaves,
          value: stats.pendingLeaves.toString(),
          icon: Icons.pending,
          color: AppColors.statAmber,
        ),
        DashboardStatCard(
          title: AppStrings.monthlyPayroll,
          value: '${AppStrings.currencySymbol}${stats.monthlyPayroll.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet,
          color: AppColors.statPurple,
        ),
        DashboardStatCard(
          title: AppStrings.activeProjects,
          value: stats.activeProjects.toString(),
          icon: Icons.work,
          color: AppColors.statTeal,
        ),
      ],
    );
  }
}

