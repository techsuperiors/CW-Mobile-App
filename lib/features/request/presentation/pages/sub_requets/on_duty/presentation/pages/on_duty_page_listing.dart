import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../widgets/request_listing/request_empty_state.dart';
import '../../../../../widgets/request_listing/request_grouping_utils.dart';
import '../../../../../widgets/request_listing/request_tab_theme.dart';
import '../../bloc/on_duty_request_bloc.dart';
import '../../bloc/on_duty_request_event.dart';
import '../../bloc/on_duty_request_state.dart';
import '../../data/datasources/on_duty_remote_datasource.dart';
import '../../data/repositories/on_duty_repository_impl.dart';
import '../../domain/usecases/get_on_duty_requests.dart';
import '../../models/on_duty_request_model.dart';
import '../widgets/on_duty_request_card.dart';
import 'on_duty_detail_page.dart';
import 'on_duty_request_page.dart';

/// On-Duty listing page showing list of On-Duty requests
class OnDutyPageListing extends StatefulWidget {
  const OnDutyPageListing({super.key});

  @override
  State<OnDutyPageListing> createState() => _OnDutyPageListingState();
}

class _OnDutyPageListingState extends State<OnDutyPageListing>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  OnDutyStatus? _selectedStatusFilter;
  late TabController _tabController;
  static const List<StatusTabDefinition<OnDutyStatus>> _tabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: OnDutyStatus.pending),
    StatusTabDefinition(label: 'Approved', status: OnDutyStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: OnDutyStatus.rejected),
    StatusTabDefinition(label: 'Withdrawn', status: OnDutyStatus.withdrawn),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    ///For the tab bar and for controlling the behaviour of it
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
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
        final remoteDataSource = OnDutyRemoteDataSourceImpl(
          apiClient: apiClient,
        );
        final repository = OnDutyRepositoryImpl(
          remoteDataSource: remoteDataSource,
        );

        return OnDutyRequestBloc(
          getOnDutyRequestsUseCase: GetOnDutyRequestsUseCase(repository),
        )..add(const LoadOnDutyRequests());
      },
      child: ResponsiveScaffold(
        backgroundColor: AppColors.backgroundLight,

        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
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
                  size: screenWidth * 0.048,
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
            'On Duty',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 3,
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: Builder(
          builder:
              (blocContext) => Column(
                children: [
                  // Search and filter section
                  _buildSearchAndFilterSection(blocContext),
                  SizedBox(
                    height: 0.01 * screenHeight,
                  ), // On-Duty requests list
                  Expanded(
                    child: BlocBuilder<OnDutyRequestBloc, OnDutyRequestState>(
                      builder: (context, state) {
                        if (state is OnDutyRequestLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is OnDutyRequestError) {
                          return ApiErrorState(
                            rawMessage: state.message,
                            onRetry: () {
                              final bloc = context.read<OnDutyRequestBloc>();
                              bloc.add(const LoadOnDutyRequests());
                            },
                          );
                        }

                        if (state is OnDutyRequestLoaded) {
                          return StatusTabbedSection<
                            OnDutyStatus,
                            OnDutyRequestModel
                          >(
                            controller: _tabController,
                            tabs: _tabs,
                            items: state.onDutyRequests,
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
                                  final req = entry as OnDutyRequestModel;

                                  return OnDutyRequestCard(
                                    onDutyRequest: req,
                                    onTap: () async {
                                      final shouldRefresh = await Navigator.push<
                                        bool
                                      >(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => OnDutyDetailPage(
                                                onDutyRequest:
                                                    req,
                                              ),
                                        ),
                                      );
                                      if (shouldRefresh == true &&
                                          context.mounted) {
                                        context.read<OnDutyRequestBloc>().add(
                                          const LoadOnDutyRequests(),
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

                  // Divider before bottom nav
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
            // padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
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
              decoration: InputDecoration(
                hintText: 'Search',
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
              style: AppTextStyles.bodyMedium(context),
              onChanged: (value) {
                context.read<OnDutyRequestBloc>().add(
                  SearchOnDutyRequests(value),
                );
              },
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // 4.2% of screen width

        GestureDetector(
          onTap: () async {
            final refresh = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const OnDutyRequestPage()),
            );
            if (refresh == true && context.mounted) {
              context.read<OnDutyRequestBloc>().add(const LoadOnDutyRequests());
            }
          },
          child: SizedBox(
            height: screenHeight * 0.050,

            child: SvgPicture.asset(AppAssets.addIcon),
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bloc = context.read<OnDutyRequestBloc>();
    final currentState = bloc.state;
    if (currentState is OnDutyRequestLoaded) {
      _selectedStatusFilter = currentState.statusFilter;
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
                      _buildFilterOption(
                        bottomSheetContext,
                        'All',
                        null,
                        _selectedStatusFilter == null,
                        () {
                          setModalState(() => _selectedStatusFilter = null);
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Pending',
                        OnDutyStatus.pending,
                        _selectedStatusFilter == OnDutyStatus.pending,
                        () {
                          setModalState(
                            () => _selectedStatusFilter = OnDutyStatus.pending,
                          );
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Approved',
                        OnDutyStatus.approved,
                        _selectedStatusFilter == OnDutyStatus.approved,
                        () {
                          setModalState(
                            () => _selectedStatusFilter = OnDutyStatus.approved,
                          );
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Rejected',
                        OnDutyStatus.rejected,
                        _selectedStatusFilter == OnDutyStatus.rejected,
                        () {
                          setModalState(
                            () => _selectedStatusFilter = OnDutyStatus.rejected,
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            bloc.add(
                              FilterOnDutyRequestsByStatus(
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
    OnDutyStatus? status,
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
class _DottedLinePainter extends CustomPainter {
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
