import '../../domain/entities/dashboard_stats.dart';

/// Dashboard statistics model
class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalEmployees,
    required super.presentToday,
    required super.onLeave,
    required super.pendingLeaves,
    required super.monthlyPayroll,
    required super.activeProjects,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalEmployees: json['total_employees'] ?? 0,
      presentToday: json['present_today'] ?? 0,
      onLeave: json['on_leave'] ?? 0,
      pendingLeaves: json['pending_leaves'] ?? 0,
      monthlyPayroll: (json['monthly_payroll'] ?? 0).toDouble(),
      activeProjects: json['active_projects'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_employees': totalEmployees,
      'present_today': presentToday,
      'on_leave': onLeave,
      'pending_leaves': pendingLeaves,
      'monthly_payroll': monthlyPayroll,
      'active_projects': activeProjects,
    };
  }
}

