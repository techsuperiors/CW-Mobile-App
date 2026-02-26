import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/dashboard_stats_grid.dart';
import '../widgets/dashboard_chart_section.dart';
import '../../../attendance/presentation/widgets/leaves_summary.dart';

/// Dashboard page with responsive layout
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // DashboardBloc is already provided by HomePage, trigger the load once
    context.read<DashboardBloc>().add(const LoadDashboardStats());
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
        title: AppStrings.dashboard,
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: LoadingWidget());
            } else if (state is DashboardError) {
              return ErrorDisplayWidget(message: state.message);
            } else if (state is DashboardLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<DashboardBloc>().add(const RefreshDashboardStats());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Grid
                      DashboardStatsGrid(stats: state.stats),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03), // 3% of screen height
                      // Leave Summary
                      const LeavesSummary(),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03), // 3% of screen height
                      // Charts Section
                      DashboardChartSection(stats: state.stats),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      );
  }
}

