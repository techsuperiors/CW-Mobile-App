import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:collectivWork/core/constants/app_colors.dart';
import 'package:collectivWork/core/constants/app_text_styles.dart';
import 'package:collectivWork/core/constants/module_permissions.dart';
import 'package:collectivWork/core/network/api_client.dart';
import 'package:collectivWork/core/network/network_info.dart';
import 'package:collectivWork/core/utils/permission_checker.dart';
import 'package:collectivWork/core/widgets/access_denied_view.dart';
import 'package:collectivWork/core/widgets/api_error_state.dart';
import 'package:collectivWork/core/widgets/responsive_scaffold.dart';
import 'package:collectivWork/core/widgets/status_tabbed_section.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/bloc/wfh_request_bloc.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/bloc/wfh_request_event.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/bloc/wfh_request_state.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/data/datasources/wfh_remote_datasource.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/data/repositories/wfh_repository_impl.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/domain/usecases/get_team_wfh_requests.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/domain/usecases/get_wfh_request_stats.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/domain/usecases/get_wfh_requests.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/models/wfh_request_model.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/presentation/pages/wfh_detail_page.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/wfh/presentation/widgets/wfh_request_card.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_filter_button.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_empty_state.dart';
import 'package:collectivWork/features/user/presentation/bloc/user_profile_bloc.dart';
import 'package:collectivWork/features/user/presentation/bloc/user_profile_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/utils/navigation_helper.dart';
import '../../../../../home/presentation/widgets/bottom_nav_bar.dart';

class WfhApprovalPageListing extends StatefulWidget {
  const WfhApprovalPageListing({super.key});

  @override
  State<WfhApprovalPageListing> createState() => _WfhApprovalPageListingState();
}

class _WfhApprovalPageListingState extends State<WfhApprovalPageListing>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late final WfhRequestBloc _wfhRequestBloc;
  RequestAudienceScope _selectedScope = RequestAudienceScope.allUsers;
  static const int _pageSize = 5;
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
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = WfhRemoteDataSourceImpl(apiClient: apiClient);
    final repository = WfhRepositoryImpl(remoteDataSource: remoteDataSource);
    _wfhRequestBloc = WfhRequestBloc(
      getWfhRequestsUseCase: GetWfhRequestsUseCase(repository),
      getWfhRequestStatsUseCase: GetWfhRequestStatsUseCase(repository),
      getTeamWfhRequestsUseCase: GetTeamWfhRequestsUseCase(repository),
    );
    _tabController = TabController(length: _tabs.length, vsync: this);
    _lastHandledTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
  }

  WfhStatus? get _selectedTabStatus => _tabs[_tabController.index].status;

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _searchController.dispose();
    _tabController.dispose();
    _wfhRequestBloc.close();
    super.dispose();
  }

  Future<void> _refreshTabData({
    required int clientId,
    required RequestAudienceScope scope,
    required WfhStatus? status,
  }) async {
    _wfhRequestBloc.add(
      LoadTeamWfhRequests(
        clientId: clientId,
        scope: scope,
        status: status,
        limit: _pageSize,
        forceRefresh: true,
      ),
    );

    await _wfhRequestBloc.stream.firstWhere((state) {
      if (state is WfhRequestLoaded) {
        return !state.isRefreshing &&
            state.selectedScope == scope &&
            state.statusFilter == status;
      }

      return state is WfhRequestError;
    });
  }

  void _handleTabChange() {
    if (!mounted || _lastHandledTabIndex == _tabController.index) {
      return;
    }

    _lastHandledTabIndex = _tabController.index;
    setState(() {});

    final currentState = _wfhRequestBloc.state;
    final scope =
        currentState is WfhRequestLoaded
            ? currentState.selectedScope
            : _selectedScope;

    _wfhRequestBloc.add(
      LoadTeamWfhRequests(
        clientId: _resolveClientId(context),
        scope: scope,
        status: _selectedTabStatus,
        limit: _pageSize,
      ),
    );
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
        rawMessage: viewState.contentErrorMessage!,
        onRetry:
            () => context.read<WfhRequestBloc>().add(
              LoadTeamWfhRequests(
                clientId: clientId,
                scope: viewState.selectedScope,
                status: viewState.statusFilter,
                limit: _pageSize,
                forceRefresh: true,
              ),
            ),
      );
    }

    final visibleRequests = viewState.filteredWfhRequests;
    if (visibleRequests.isEmpty) {
      return const RequestEmptyState();
    }

    final grouped = _groupByMonth(visibleRequests);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isCurrentTab &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            viewState.hasMore &&
            !viewState.isLoadingMore) {
          context.read<WfhRequestBloc>().add(
            LoadMoreTeamWfhRequests(
              clientId: clientId,
              limit: _pageSize,
            ),
          );
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh:
            () => _refreshTabData(
              clientId: clientId,
              scope: viewState.selectedScope,
              status: viewState.statusFilter,
            ),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
          itemCount: grouped.length + (viewState.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= grouped.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                child: const Center(child: CircularProgressIndicator()),
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
                  style: AppTextStyles.bodySmall(context).copyWith(
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
                          isApprovalMode: true,
                        ),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<WfhRequestBloc>().add(
                    LoadTeamWfhRequests(
                      clientId: clientId,
                      scope: viewState.selectedScope,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasAccess = PermissionChecker.hasPermission(
      context,
      anyOf: ModulePermissions.wfhApproval,
    );

    if (!hasAccess) {
      return ResponsiveScaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            'WFH Approval',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 4,
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: const AccessDeniedView(
          title: 'Approval Access Required',
          message: 'You do not have permission to view team WFH approvals.',
        ),
      );
    }

    final clientId = _resolveClientId(context);
    final allowAllUsers = _allowAllUsers(context);
    final availableScopes =
        allowAllUsers
            ? RequestAudienceScope.values
            : const [
              RequestAudienceScope.myReportees,
              RequestAudienceScope.myIndirectReportees,
            ];

    if (!allowAllUsers &&
        _selectedScope == RequestAudienceScope.allUsers) {
      _selectedScope = RequestAudienceScope.myReportees;
    }

    if (_wfhRequestBloc.state is WfhRequestInitial) {
      _wfhRequestBloc.add(
        LoadTeamWfhRequests(
          clientId: clientId,
          scope: _selectedScope,
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
            'WFH Approval',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 4,
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: Builder(
          builder:
              (blocContext) => Column(
                children: [
                  _buildSearchSection(
                    blocContext,
                    availableScopes,
                  ),
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
                            rawMessage: state.message,
                            onRetry:
                                () => context
                                    .read<WfhRequestBloc>()
                                    .add(
                                      LoadTeamWfhRequests(
                                        clientId: clientId,
                                        scope: _selectedScope,
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
                          countOverrides: {
                            null: loaded.totalCount,
                            WfhStatus.pending: loaded.pendingCount,
                            WfhStatus.approved: loaded.approvedCount,
                            WfhStatus.rejected: loaded.rejectedCount,
                          },
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
                          tabContentBuilder: (context, tab) {
                            final rawTabState =
                                tab.status == loaded.statusFilter
                                    ? loaded
                                    : _wfhRequestBloc.getCachedTeamWfhRequests(
                                      scope: _selectedScope,
                                      status: tab.status,
                                    );

                            if (rawTabState == null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final tabState =
                                _wfhRequestBloc.buildTeamWfhViewState(
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
                          emptyBuilder: (context) => const RequestEmptyState(),
                          listBuilder: (context, list) => const SizedBox.shrink(),
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
      final date = req.appliedDate;
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
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

  bool _allowAllUsers(BuildContext context) {
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is! UserProfileLoaded) {
      return false;
    }

    return profileState.profile.allowAllUsers;
  }

  int _resolveClientId(BuildContext context) {
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is! UserProfileLoaded) {
      return 0;
    }

    return profileState.profile.clientId;
  }

  Widget _buildSearchSection(
    BuildContext context,
    List<RequestAudienceScope> availableScopes,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
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
        SizedBox(width: screenWidth * 0.03),
        RequestAudienceFilterButton(
          selectedScope: _selectedScope,
          availableScopes: availableScopes,
          onSelected: (scope) {
            if (scope == _selectedScope) return;
            setState(() {
              _selectedScope = scope;
            });
            context.read<WfhRequestBloc>().add(
              LoadTeamWfhRequests(
                clientId: _resolveClientId(context),
                scope: scope,
                status: _selectedTabStatus,
                limit: _pageSize,
              ),
            );
          },
        ),
      ],
    );
  }
}
