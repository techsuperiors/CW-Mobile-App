import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/bloc/leave_request_bloc.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/bloc/leave_request_state.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_tab_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../widgets/request_listing/request_empty_state.dart';
import '../../../../../widgets/request_listing/request_grouping_utils.dart';
import '../../../wfh/models/wfh_request_model.dart';
import '../../domain/entities/leave_entity.dart';
import '../../data/datasources/leaves_remote_datasource.dart';
import '../../data/repositories/leaves_repository_impl.dart';
import '../../domain/usecases/get_leaves_usecase.dart';
import '../../domain/usecases/apply_leave_usecase.dart';
import '../bloc/leave_request_event.dart';
import '../widgets/leave_request_card.dart';
import 'apply_leave_page.dart';
import 'leave_detail_page.dart';

/// Apply Leave listing page showing list of leave requests
class ApplyLeavePageListing extends StatefulWidget {
  const ApplyLeavePageListing({super.key});

  @override
  State<ApplyLeavePageListing> createState() => _ApplyLeavePageListingState();
}

class _ApplyLeavePageListingState extends State<ApplyLeavePageListing>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  LeaveStatus? _selectedStatusFilter;
  late TabController _tabController;
  static const List<StatusTabDefinition<LeaveStatus>> _tabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: LeaveStatus.pending),
    StatusTabDefinition(label: 'Approved', status: LeaveStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: LeaveStatus.rejected),
    StatusTabDefinition(label: 'Withdrawn', status: LeaveStatus.withdrawn),
  ];

  @override
  void initState() {
    super.initState();

    ///For the tab bar and for controlling the behaviour of it
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // BlocProvider will load leave requests automatically in its create method
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (_) {
        final networkInfo = NetworkInfoImpl(Connectivity());
        final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
        final remoteDataSource = LeavesRemoteDataSourceImpl(
          apiClient: apiClient,
        );
        final repository = LeavesRepositoryImpl(
          remoteDataSource: remoteDataSource,
          networkInfo: networkInfo,
        );
        final getLeavesUseCase = GetLeavesUseCase(repository);
        final applyLeaveUseCase = ApplyLeaveUseCase(repository);
        return LeaveRequestBloc(
          getLeavesUseCase: getLeavesUseCase,
          applyLeaveUseCase: applyLeaveUseCase,
        )..add(const LoadLeaveRequests());
      },
      child: ResponsiveScaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          forceMaterialTransparency: true,
          elevation: 0,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).colorScheme.primary,
                  size: screenWidth * 0.048, // 4.8% of screen width
                ),
                Flexible(
                  child: Text(
                    'Back',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          leadingWidth: 110,
          title: Text(
            AppStrings.applyLeave,
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 3, // Request is active
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: Builder(
          builder:
              (blocContext) => Column(
                children: [
                  // Search and filter section
                  _buildSearchAndFilterSection(blocContext),
                  SizedBox(height: screenHeight * 0.015),
                  // Leave requests list
                  Expanded(
                    child: BlocBuilder<LeaveRequestBloc, LeaveRequestState>(
                      builder: (context, state) {
                        if (state is LeaveRequestLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is LeaveRequestError) {
                          return ApiErrorState(
                            rawMessage: state.message,
                            onRetry: () {
                              final bloc = context.read<LeaveRequestBloc>();
                              bloc.add(const LoadLeaveRequests());
                            },
                          );
                        }

                        if (state is LeaveRequestLoaded) {
                          return StatusTabbedSection<LeaveStatus, LeaveEntity>(
                            controller: _tabController,
                            tabs: _tabs,
                            items: state.leaveRequests,
                            searchQuery: state.searchQuery?.toLowerCase() ?? '',
                            statusSelector: (item) => item.status,
                            matchesSearch: (item, query) {
                              if (query.isEmpty) return true;
                              return (item.subject?.toLowerCase().contains(
                                        query,
                                      ) ??
                                      false) ||
                                  item.reason.toLowerCase().contains(query);
                            },
                            tabColorBuilder: RequestTabTheme.colorForIndex,
                            emptyBuilder: (context) => RequestEmptyState(),
                            listBuilder: (context, list) {
                              final grouped = RequestGroupingUtils.groupByMonth(
                                items: list,
                                dateSelector: (item) => item.appliedDate,
                              );
                              return ListView.builder(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.012,
                                ),
                                itemCount: grouped.length,
                                itemBuilder: (context, index) {
                                  final entry = grouped[index];
                                  if (entry is String) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top:
                                            index == 0
                                                ? 0
                                                : screenHeight * 0.014,
                                        bottom: screenHeight * 0.010,
                                      ),
                                      child: Text(
                                        entry,
                                        style: AppTextStyles.bodySmall(
                                          context,
                                        ).copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  }
                                  final req = entry as LeaveEntity;

                                  return LeaveRequestCard(
                                    leaveRequest: req,
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => LeaveDetailPage(
                                                leaveRequest: req,
                                              ),
                                        ),
                                      );
                                      if (result == true && context.mounted) {
                                        context.read<LeaveRequestBloc>().add(
                                          const LoadLeaveRequests(),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      children: [
        // Search bar
        Expanded(
          child: Container(
            height: screenHeight * 0.050,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2), // light grey background
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              style: AppTextStyles.bodyMedium(context),
              decoration: InputDecoration(
                hintText: AppStrings.search,
                hintStyle: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.textTertiary),

                prefixIcon: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: SvgPicture.asset(
                    AppAssets.searchIcon,
                    width: screenWidth * 0.045,
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // 👈 curved border
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),

                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.010,
                ),
              ),

              onChanged: (value) {
                context.read<LeaveRequestBloc>().add(
                  SearchLeaveRequests(value),
                );
              },
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // 4.2% of screen width
        // SizedBox(width: screenWidth * 0.021), // 2.1% of screen width
        // Add button (green circular button with plus) - opens form page
        PermissionGuard(
          anyOf: ["Leave Management:My Leaves:Write"],
          child: SizedBox(
            height: screenHeight * 0.050, // 5.0% of screen height

            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApplyLeavePage(),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<LeaveRequestBloc>().add(
                    const LoadLeaveRequests(),
                  );
                }
              },
              customBorder: const CircleBorder(),
              child: SvgPicture.asset(AppAssets.addIcon),
            ),
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get current filter state from bloc using the context that has BlocProvider
    final bloc = context.read<LeaveRequestBloc>();
    final currentState = bloc.state;
    LeaveStatus? currentFilter;
    if (currentState is LeaveRequestLoaded) {
      currentFilter = currentState.statusFilter;
      // Sync local state with bloc state
      _selectedStatusFilter = currentFilter;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (bottomSheetContext) => StatefulBuilder(
            builder:
                (bottomSheetContext, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.042),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Status',
                        style: AppTextStyles.heading4(bottomSheetContext),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Filter options
                      _buildFilterOption(
                        bottomSheetContext,
                        'All',
                        null,
                        _selectedStatusFilter == null,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = null;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Pending',
                        LeaveStatus.pending,
                        _selectedStatusFilter == LeaveStatus.pending,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = LeaveStatus.pending;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Approved',
                        LeaveStatus.approved,
                        _selectedStatusFilter == LeaveStatus.approved,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = LeaveStatus.approved;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Rejected',
                        LeaveStatus.rejected,
                        _selectedStatusFilter == LeaveStatus.rejected,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = LeaveStatus.rejected;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Withdrawn',
                        LeaveStatus.withdrawn,
                        _selectedStatusFilter == LeaveStatus.withdrawn,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = LeaveStatus.withdrawn;
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            // Use the bloc instance from the outer context
                            bloc.add(
                              FilterLeaveRequestsByStatus(
                                _selectedStatusFilter,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.018,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Apply Filter',
                            style: AppTextStyles.buttonMedium(
                              bottomSheetContext,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String label,
    LeaveStatus? status,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.032),
            Text(
              label,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for dotted line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
