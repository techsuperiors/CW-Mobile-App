import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../../dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../../dashboard/domain/usecases/get_dashboard_stats.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../services/presentation/pages/services_page.dart';
import '../widgets/bottom_nav_bar.dart';

/// Home page with bottom navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Services is the default active page

  final List<Widget> _pages = [
    const ServicesPage(), // Services (index 0)
    const PlaceholderPage(title: AppStrings.posts), // Posts (index 1)
    const AttendancePage(), // Home (index 2)
    const PlaceholderPage(title: AppStrings.request), // Request (index 3)
    const PlaceholderPage(title: AppStrings.approval), // Approval (index 4)
  ];

  @override
  Widget build(BuildContext context) {
    // Create DashboardBloc only when HomePage is accessed (lazy initialization)
    return BlocProvider(
      create: (_) {
        final networkInfo = NetworkInfoImpl(Connectivity());
        final dashboardRemoteDataSource = DashboardRemoteDataSourceImpl();
        final dashboardRepository = DashboardRepositoryImpl(
          remoteDataSource: dashboardRemoteDataSource,
          networkInfo: networkInfo,
        );
        final getDashboardStats = GetDashboardStats(dashboardRepository);
        return DashboardBloc(getDashboardStats: getDashboardStats);
      },
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

/// Placeholder page for features not yet implemented
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.construction,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '$title ${AppStrings.feature}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.comingSoon,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

