import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:collectivWork/features/approval/presentation/pages/approval_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/home_page_cubit.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../../dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../../dashboard/domain/usecases/get_dashboard_stats.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../services/presentation/pages/services_page.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../../request/presentation/pages/request_bottom_sheet.dart';

/// Home page with bottom navigation
class HomePage extends StatefulWidget {
  final int? initialTabIndex;

  const HomePage({super.key, this.initialTabIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DashboardBloc _dashboardBloc;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    _dashboardBloc = DashboardBloc(
      getDashboardStats: GetDashboardStats(
        DashboardRepositoryImpl(
          remoteDataSource: DashboardRemoteDataSourceImpl(),
          networkInfo: networkInfo,
        ),
      ),
    );

    _pages = [
      const ServicesPage(),
      PermissionGuard(
        requiredPermission: "Home:Post:Read",
        child: const PlaceholderPage(title: AppStrings.posts),
      ),
      AttendancePage(onOpenDrawer: _openDrawer),
      const PlaceholderPage(title: AppStrings.request),
      const PlaceholderPage(title: AppStrings.approval),
    ];
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dashboardBloc,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: BlocBuilder<HomePageCubit, int>(
          builder: (context, currentIndex) {
            return IndexedStack(index: currentIndex, children: _pages);
          },
        ),
        bottomNavigationBar: BlocBuilder<HomePageCubit, int>(
          builder: (context, currentIndex) {
            return BottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                if (index == 3) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const RequestBottomSheet(),
                  );
                } else {
                  if (index == 4) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const ApprovalBottomSheet(),
                    );
                  } else {
                    context.read<HomePageCubit>().switchTab(index);
                  }
                }
              },
            );
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
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
