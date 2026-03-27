import 'package:collectivWork/core/extension/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:collectivWork/core/network/api_client.dart';
import 'package:collectivWork/core/network/network_info.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/data/datasources/leaves_remote_datasource.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/data/repositories/leaves_repository_impl.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/usecases/get_leave_history_usecase.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/bloc/leave_history/leave_history_bloc.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/bloc/leave_history/leave_history_event.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/pages/leave_history_page.dart';
import 'donut_chart_widget.dart';

/// Card widget for displaying leave type information with donut chart
class LeaveTypeCard extends StatelessWidget {
  final String title;
  final double totalLeaves;
  final double consumed;
  final double allocatedQuota;
  final double annualQuota;
  final double? accruedSoFar; // allocated_leave = Accrued So Far
  final Color color;
  final bool isLOP;

  const LeaveTypeCard({
    super.key,
    required this.title,
    required this.totalLeaves,
    required this.consumed,
    required this.allocatedQuota,
    required this.annualQuota,
    this.accruedSoFar,
    required this.color,
    this.isLOP = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = accruedSoFar ?? allocatedQuota;
    final percentage = base > 0
        ? ((base - consumed) / base).clamp(0.0, 1.0)
        : 0.0;
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
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.042,
      ), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Info Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title.capitalizeFirst(),
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showbottombalancehistory(context);
                },
                child: Container(
                  width:
                      MediaQuery.of(context).size.width *
                      0.072, // ~5.3% of screen width
                  height: MediaQuery.of(context).size.height * 0.032,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppAssets.iconInfo,
                      width:
                          MediaQuery.of(context).size.width *
                          0.040, // ~3.2% of screen width
                      height: MediaQuery.of(context).size.width * 0.040,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryLight,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.025,
          ), // 2.5% of screen height
          // Donut Chart
          Center(
            child: DonutChartWidget(
              percentage: percentage,
              totalLeaves: isLOP?allocatedQuota:totalLeaves,
              color: color,
              islop: isLOP,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.025,
          ), // 2.5% of screen height
          // Statistics Table
          isLOP ? _buildLOPTable(context) : _buildRegularTable(context),
        ],
      ),
    );
  }
  void _showbottombalancehistory(BuildContext context){
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final networkInfo = NetworkInfoImpl(Connectivity());
        final apiClient = ApiClient(
          dio: Dio(),
          networkInfo: networkInfo,
        );
        final remoteDataSource = LeavesRemoteDataSourceImpl(
          apiClient: apiClient,
        );
        final repository = LeavesRepositoryImpl(
          remoteDataSource: remoteDataSource,
          networkInfo: networkInfo,
        );
        final getLeaveHistoryUseCase = GetLeaveHistoryUseCase(
          repository,
        );

        return BlocProvider(
          create: (_) => LeaveHistoryBloc(
            getLeaveHistoryUseCase: getLeaveHistoryUseCase,
          )..add(FetchLeaveHistory(leaveType: title)),
          child: LeaveHistoryPage(leaveType: title),
        );
      },
    );
  }

  Widget _buildLOPTable(context) {
    final currentMonthLop = totalLeaves;
    String _fmt(double v) => '${v.toStringAsFixed(2)} Day(s)';
    return Table(
      border: TableBorder(
        top: const BorderSide(color: AppColors.border, width: 1),
        bottom: const BorderSide(color: AppColors.border, width: 1),
        left: const BorderSide(color: AppColors.border, width: 1),
        right: const BorderSide(color: AppColors.border, width: 1),
        horizontalInside: const BorderSide(color: AppColors.border, width: 1),
      ),
      children: [
        _buildTableRow(context, 'LOP This Month', _fmt(currentMonthLop)),
        _buildTableRow(context, 'Total LOP Days', _fmt(allocatedQuota)),
      ],
    );
  }

  Widget _buildRegularTable(context) {
    String _fmt(double? v) =>
        v != null ? '${v.toStringAsFixed(2)} Day(s)' : '-- Day(s)';
    return Table(
      border: TableBorder(
        top: const BorderSide(color: AppColors.border, width: 1),
        bottom: const BorderSide(color: AppColors.border, width: 1),
        left: const BorderSide(color: AppColors.border, width: 1),
        right: const BorderSide(color: AppColors.border, width: 1),
        horizontalInside: const BorderSide(color: AppColors.border, width: 1),
      ),
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      children: [
        // Row 1: Accrued So Far | Consumed
        TableRow(
          children: [
            _buildTableCell(
              context,
              'Accrued So Far',
              _fmt(accruedSoFar),
              showRightBorder: true,
            ),
            _buildTableCell(context, 'Consumed', _fmt(consumed)),
          ],
        ),
        // Row 2: Allocated Quota | Annual Quota
        TableRow(
          children: [
            _buildTableCell(
              context,
              'Allocated Quota',
              _fmt(allocatedQuota),
              showRightBorder: true,
            ),
            _buildTableCell(context, 'Annual Quota', _fmt(annualQuota)),
          ],
        ),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, String label, String value) {
    return TableRow(children: [_buildTableCell(context, label, value)]);
  }

  Widget _buildTableCell(
    BuildContext context,
    String label,
    String value, {
    bool showRightBorder = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showRightBorder
            ? const Border(right: BorderSide(color: AppColors.border, width: 1))
            : null,
      ),
      child: LayoutBuilder(
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
          final contentWidth =
              availableWidth - (horizontalPadding * 2) - spacing;

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
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  flex: 2,
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
      ),
    );
  }
}
