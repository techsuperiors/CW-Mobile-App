import '../../domain/entities/dashboard_stats.dart';
import '../models/dashboard_stats_model.dart';

/// Dashboard remote data source interface
abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats();
}

/// Dashboard remote data source implementation
class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  // Add API client here when ready
  // final ApiClient apiClient;

  // DashboardRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    // TODO: Implement API call
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1));
    return const DashboardStatsModel(
      totalEmployees: 150,
      presentToday: 120,
      onLeave: 15,
      pendingLeaves: 8,
      monthlyPayroll: 2500000.0,
      activeProjects: 12,
    );
  }
}

