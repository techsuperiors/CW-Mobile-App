import 'package:equatable/equatable.dart';

/// Dashboard statistics entity
class DashboardStats extends Equatable {
  final int totalEmployees;
  final int presentToday;
  final int onLeave;
  final int pendingLeaves;
  final double monthlyPayroll;
  final int activeProjects;

  const DashboardStats({
    required this.totalEmployees,
    required this.presentToday,
    required this.onLeave,
    required this.pendingLeaves,
    required this.monthlyPayroll,
    required this.activeProjects,
  });

  @override
  List<Object?> get props => [
        totalEmployees,
        presentToday,
        onLeave,
        pendingLeaves,
        monthlyPayroll,
        activeProjects,
      ];
}

