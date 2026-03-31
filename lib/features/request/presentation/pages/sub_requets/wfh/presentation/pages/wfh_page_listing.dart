import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../bloc/wfh_request_bloc.dart';
import '../../bloc/wfh_request_event.dart';
import '../../bloc/wfh_request_state.dart';
import '../../data/datasources/wfh_remote_datasource.dart';
import '../../data/repositories/wfh_repository_impl.dart';
import '../../domain/usecases/get_wfh_requests.dart';
import '../../domain/usecases/get_wfh_request_stats.dart';
import '../../models/wfh_request_model.dart';
import '../widgets/wfh_request_card.dart';
import 'wfh_detail_page.dart';
import 'apply_wfh_page.dart';

/// WFH listing page showing list of WFH requests
class WfhPageListing extends StatefulWidget {
  const WfhPageListing({super.key});

  @override
  State<WfhPageListing> createState() => _WfhPageListingState();
}

class _WfhPageListingState extends State<WfhPageListing>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 5;
  final TextEditingController _searchController = TextEditingController();
  WfhStatus? _selectedStatusFilter;
  late TabController _tabController;
  static const List<StatusTabDefinition<WfhStatus>> _tabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: WfhStatus.pending),
    StatusTabDefinition(label: 'Approved', status: WfhStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: WfhStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // BlocProvider will load WFH requests automatically in its create method
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

    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = WfhRemoteDataSourceImpl(apiClient: apiClient);
    final repository = WfhRepositoryImpl(remoteDataSource: remoteDataSource);
    final getWfhRequestsUseCase = GetWfhRequestsUseCase(repository);
    final getWfhRequestStatsUseCase = GetWfhRequestStatsUseCase(repository);
    final clientId = _resolveClientId();

    return BlocProvider(
      create:
          (_) => WfhRequestBloc(
            getWfhRequestsUseCase: getWfhRequestsUseCase,
            getWfhRequestStatsUseCase: getWfhRequestStatsUseCase,
          )..add(LoadWfhRequests(clientId: clientId, limit: _pageSize)),
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
            AppStrings.wfh,
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
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Search and filter section
                  _buildSearchAndFilterSection(blocContext, clientId),
                  SizedBox(height: screenHeight * 0.01),
                  Expanded(
                    child: BlocBuilder<WfhRequestBloc, WfhRequestState>(
                      builder: (context, state) {
                        if (state is WfhRequestLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is WfhRequestError) {
                          return ApiErrorState(
                            title: 'Unable to load WFH requests',
                            rawMessage: state.message,
                            onRetry: () {
                              final bloc = context.read<WfhRequestBloc>();
                              bloc.add(
                                LoadWfhRequests(
                                  clientId: clientId,
                                  limit: _pageSize,
                                ),
                              );
                            },
                          );
                        }

                        if (state is WfhRequestLoaded) {
                          return StatusTabbedSection<
                            WfhStatus,
                            WfhRequestModel
                          >(
                            controller: _tabController,
                            tabs: _tabs,
                            items: state.wfhRequests,
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
                            tabColorBuilder: _getTabColor,
                            countOverrides: {
                              null: state.totalCount,
                              WfhStatus.pending: state.pendingCount,
                              WfhStatus.approved: state.approvedCount,
                              WfhStatus.rejected: state.rejectedCount,
                            },
                            emptyBuilder:
                                (context) => _buildEmpty(
                                  context,
                                  screenWidth,
                                  screenHeight,
                                ),
                            listBuilder: (context, list) {
                              final grouped = _groupByMonth(list);
                              return NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification.metrics.pixels >=
                                          notification.metrics.maxScrollExtent -
                                              200 &&
                                      state.hasMore &&
                                      !state.isLoadingMore) {
                                    context.read<WfhRequestBloc>().add(
                                      const LoadMoreWfhRequests(
                                        limit: _pageSize,
                                      ),
                                    );
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.012,
                                  ),
                                  itemCount:
                                      grouped.length +
                                      (state.isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index >= grouped.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

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

                                    final req = entry as WfhRequestModel;
                                    return WfhRequestCard(
                                      wfhRequest: req,
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => WfhDetailPage(
                                                  wfhRequest: req,
                                                ),
                                          ),
                                        );
                                          if (result == true &&
                                            context.mounted) {
                                          context.read<WfhRequestBloc>().add(
                                            LoadWfhRequests(
                                              clientId: clientId,
                                              limit: _pageSize,
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
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

  int _resolveClientId() {
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) return 0;
    final decoded = decodeData<Map<String, dynamic>>(token);
    final clientId = decoded?['client_id'];
    if (clientId is int) return clientId;
    if (clientId is String) return int.tryParse(clientId) ?? 0;
    return 0;
  }

  /// Returns a flat list of month-header Strings interleaved with WfhRequestModel items
  List<dynamic> _groupByMonth(List<WfhRequestModel> requests) {
    final result = <dynamic>[];
    String? lastMonth;

    for (final req in requests) {
      // Parse the first date from dateRange (assumes ISO or parseable date on model)
      // Fallback: use req.startDate if available, otherwise skip header
      final monthLabel = _monthLabel(req);
      if (monthLabel != lastMonth) {
        result.add(monthLabel);
        lastMonth = monthLabel;
      }
      result.add(req);
    }
    return result;
  }

  String _monthLabel(WfhRequestModel req) {
    try {
      // Try parsing startDate from model; adjust field name as needed
      final date = req.appliedDate; // DateTime
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  Widget _buildEmpty(BuildContext context, double w, double h) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: w * 0.15,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: h * 0.02),
          Text(
            AppStrings.noData,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFE91E8C); // All → Pink
      case 1:
        return const Color(0xFF0086C9); // Pending
      case 2:
        return const Color(0xFF12B76A); // Approved
      case 3:
        return const Color(0xFFF04438); // Rejected
      default:
        return Colors.grey;
    }
  }

  Widget _buildSearchAndFilterSection(BuildContext context, int clientId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
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
                  context.read<WfhRequestBloc>().add(SearchWfhRequests(value));
                },
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.042), // 4.2% of screen width
          // Add button (green circular button with plus) - opens form page
          PermissionGuard(
            requiredPermission: "Attendance:WFH Request:Write",
            child: SizedBox(
              height: screenHeight * 0.050, // 5.0% of screen height

              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ApplyWfhPage(),
                      ),
                    );
                    if (result == true && context.mounted) {
                      context.read<WfhRequestBloc>().add(
                        LoadWfhRequests(
                          clientId: clientId,
                          limit: _pageSize,
                        ),
                      );
                    }
                  },
                  child: SvgPicture.asset(AppAssets.addIcon),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Use the current tab index as the selected filter state
    _selectedStatusFilter = _tabs[_tabController.index].status;

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
                        WfhStatus.pending,
                        _selectedStatusFilter == WfhStatus.pending,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = WfhStatus.pending;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Approved',
                        WfhStatus.approved,
                        _selectedStatusFilter == WfhStatus.approved,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = WfhStatus.approved;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Rejected',
                        WfhStatus.rejected,
                        _selectedStatusFilter == WfhStatus.rejected,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = WfhStatus.rejected;
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
                            // Navigate to the tab selected in the bottom sheet
                            final index = _tabs.indexWhere(
                              (tab) => tab.status == _selectedStatusFilter,
                            );
                            if (index != -1) {
                              _tabController.animateTo(index);
                            }
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
    WfhStatus? status,
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
