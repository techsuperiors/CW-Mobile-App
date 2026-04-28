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
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../bloc/wfh_request_bloc.dart';
import '../../bloc/wfh_request_event.dart';
import '../../bloc/wfh_request_state.dart';
import '../../data/datasources/wfh_remote_datasource.dart';
import '../../data/repositories/wfh_repository_impl.dart';
import '../../domain/usecases/get_wfh_requests.dart';
import '../../domain/usecases/get_wfh_request_stats.dart';
import '../../models/wfh_request_model.dart';
import '../widgets/wfh_request_card.dart';
import 'apply_wfh_page.dart';
import 'wfh_detail_page.dart';

class WfhPageListing extends StatefulWidget {
  const WfhPageListing({super.key});

  @override
  State<WfhPageListing> createState() => _WfhPageListingState();
}

class _WfhPageListingState extends State<WfhPageListing>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 5;
  final TextEditingController _searchController = TextEditingController();
  late final WfhRequestBloc _wfhRequestBloc;
  late TabController _tabController;
  late int _lastHandledTabIndex;

  static const List<StatusTabDefinition<WfhStatus>> _tabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: WfhStatus.pending),
    StatusTabDefinition(label: 'Approved', status: WfhStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: WfhStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: networkInfo,
      onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );
    final remoteDataSource = WfhRemoteDataSourceImpl(apiClient: apiClient);
    final repository = WfhRepositoryImpl(remoteDataSource: remoteDataSource);
    _wfhRequestBloc = WfhRequestBloc(
      getWfhRequestsUseCase: GetWfhRequestsUseCase(repository),
      getWfhRequestStatsUseCase: GetWfhRequestStatsUseCase(repository),
    );
    _tabController = TabController(length: _tabs.length, vsync: this);
    _lastHandledTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _wfhRequestBloc.close();
    super.dispose();
  }

  WfhStatus? get _selectedTabStatus => _tabs[_tabController.index].status;

  void _handleTabChange() {
    if (!mounted || _lastHandledTabIndex == _tabController.index) {
      return;
    }

    _lastHandledTabIndex = _tabController.index;
    setState(() {});

    _wfhRequestBloc.add(
      LoadWfhRequests(
        clientId: _resolveClientId(),
        status: _selectedTabStatus,
        limit: _pageSize,
      ),
    );
  }

  Future<void> _refreshTabData({
    required int clientId,
    required WfhStatus? status,
  }) async {
    _wfhRequestBloc.add(
      LoadWfhRequests(
        clientId: clientId,
        status: status,
        limit: _pageSize,
        forceRefresh: true,
      ),
    );

    await _wfhRequestBloc.stream.firstWhere((state) {
      if (state is WfhRequestLoaded) {
        return !state.isRefreshing && state.statusFilter == status;
      }
      return state is WfhRequestError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final clientId = _resolveClientId();

    if (_wfhRequestBloc.state is WfhRequestInitial) {
      _wfhRequestBloc.add(
        LoadWfhRequests(
          clientId: clientId,
          status: _selectedTabStatus,
          limit: _pageSize,
        ),
      );
    }

    return BlocProvider.value(
      value: _wfhRequestBloc,
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
            AppStrings.wfh,
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
                  _buildSearchAndFilterSection(blocContext, clientId),
                  SizedBox(height: screenHeight * 0.01),
                  Expanded(
                    child: BlocBuilder<WfhRequestBloc, WfhRequestState>(
                      builder: (context, state) {
                        if (state is WfhRequestLoading ||
                            state is WfhRequestInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is WfhRequestError) {
                          return ApiErrorState(
                            title: 'Unable to load WFH requests',
                            rawMessage: state.message,
                            onRetry:
                                () => context.read<WfhRequestBloc>().add(
                                  LoadWfhRequests(
                                    clientId: clientId,
                                    status: _selectedTabStatus,
                                    limit: _pageSize,
                                    forceRefresh: true,
                                  ),
                                ),
                          );
                        }

                        final loaded = state as WfhRequestLoaded;
                        return StatusTabbedSection<WfhStatus, WfhRequestModel>(
                          controller: _tabController,
                          tabs: _tabs,
                          items: loaded.wfhRequests,
                          searchQuery: loaded.searchQuery?.toLowerCase() ?? '',
                          statusSelector: (item) => item.status,
                          matchesSearch: (item, query) {
                            if (query.isEmpty) return true;
                            return (item.subject?.toLowerCase().contains(query) ??
                                    false) ||
                                item.reason.toLowerCase().contains(query);
                          },
                          tabColorBuilder: _getTabColor,
                          countOverrides: {
                            null: loaded.totalCount,
                            WfhStatus.pending: loaded.pendingCount,
                            WfhStatus.approved: loaded.approvedCount,
                            WfhStatus.rejected: loaded.rejectedCount,
                          },
                          emptyBuilder:
                              (context) => _buildEmpty(
                                context,
                                screenWidth,
                                screenHeight,
                              ),
                          tabContentBuilder: (context, tab) {
                            final rawTabState =
                                tab.status == loaded.statusFilter
                                    ? loaded
                                    : _wfhRequestBloc.getCachedWfhRequests(
                                      status: tab.status,
                                    );

                            if (rawTabState == null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final tabState = _wfhRequestBloc.buildWfhViewState(
                              baseState: rawTabState,
                              searchQuery: loaded.searchQuery,
                            );

                            return _buildWfhTabContent(
                              context,
                              clientId: clientId,
                              screenHeight: screenHeight,
                              viewState: tabState,
                              isCurrentTab: tab.status == loaded.statusFilter,
                            );
                          },
                          listBuilder: (context, list) =>
                              const SizedBox.shrink(),
                        );
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

  Widget _buildWfhTabContent(
    BuildContext context, {
    required int clientId,
    required double screenHeight,
    required WfhRequestLoaded viewState,
    required bool isCurrentTab,
  }) {
    if (isCurrentTab && viewState.isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isCurrentTab && viewState.contentErrorMessage != null) {
      return ApiErrorState(
        title: 'Unable to load WFH requests',
        rawMessage: viewState.contentErrorMessage!,
        onRetry:
            () => context.read<WfhRequestBloc>().add(
              LoadWfhRequests(
                clientId: clientId,
                status: viewState.statusFilter,
                limit: _pageSize,
                forceRefresh: true,
              ),
            ),
      );
    }

    if (viewState.filteredWfhRequests.isEmpty) {
      return _buildEmpty(
        context,
        MediaQuery.of(context).size.width,
        screenHeight,
      );
    }

    final grouped = _groupByMonth(viewState.filteredWfhRequests);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isCurrentTab &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            viewState.hasMore &&
            !viewState.isLoadingMore) {
          context.read<WfhRequestBloc>().add(
            LoadMoreWfhRequests(
              clientId: clientId,
              limit: _pageSize,
            ),
          );
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh:
            () => _refreshTabData(clientId: clientId, status: viewState.statusFilter),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
          itemCount: grouped.length + (viewState.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= grouped.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final entry = grouped[index];
            if (entry is String) {
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : screenHeight * 0.014,
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
                    builder: (_) => WfhDetailPage(wfhRequest: req),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<WfhRequestBloc>().add(
                    LoadWfhRequests(
                      clientId: clientId,
                      status: viewState.statusFilter,
                      limit: _pageSize,
                      forceRefresh: true,
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  List<dynamic> _groupByMonth(List<WfhRequestModel> requests) {
    final result = <dynamic>[];
    String? lastMonth;

    for (final req in requests) {
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
      return DateFormat('MMMM yyyy').format(req.appliedDate);
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
        return const Color(0xFFE91E8C);
      case 1:
        return const Color(0xFF0086C9);
      case 2:
        return const Color(0xFF12B76A);
      case 3:
        return const Color(0xFFF04438);
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
          Expanded(
            child: Container(
              height: screenHeight * 0.050,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                    borderRadius: BorderRadius.circular(8),
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
          SizedBox(width: screenWidth * 0.042),
          if (_canRaiseWfhRequest(context))
            PermissionGuard(
              requiredPermission: "Attendance:WFH Request:Write",
              child: SizedBox(
                height: screenHeight * 0.050,
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
                            status: _selectedTabStatus,
                            limit: _pageSize,
                            forceRefresh: true,
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

  bool _canRaiseWfhRequest(BuildContext context) {
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is! UserProfileLoaded) {
      return false;
    }

    return profileState.profile.enabledWorkFromHome;
  }
}
