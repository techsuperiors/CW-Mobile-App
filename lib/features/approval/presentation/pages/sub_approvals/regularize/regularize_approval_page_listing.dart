import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../core/constants/module_permissions.dart';
import '../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../core/utils/permission_checker.dart';
import '../../../../../../core/widgets/access_denied_view.dart';
import '../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../request/presentation/widgets/request_listing/request_empty_state.dart';
import '../../../../../request/presentation/widgets/request_listing/request_grouping_utils.dart';
import '../../../../../request/presentation/widgets/request_listing/request_tab_theme.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/bloc/regularize_request_bloc.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/bloc/regularize_request_event.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/bloc/regularize_request_state.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/models/regularize_request_model.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/presentation/pages/regularize_detail_page.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/presentation/widgets/regularize_request_card.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_filter_button.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import 'package:collectivWork/features/user/presentation/bloc/user_profile_bloc.dart';
import 'package:collectivWork/features/user/presentation/bloc/user_profile_state.dart';

class RegularizeApprovalPageListing extends StatefulWidget {
  const RegularizeApprovalPageListing({super.key});

  @override
  State<RegularizeApprovalPageListing> createState() =>
      _RegularizeApprovalPageListingState();
}

class _RegularizeApprovalPageListingState
    extends State<RegularizeApprovalPageListing> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  late final RegularizeRequestBloc _regularizeRequestBloc;
  static const int _pageSize = 5;
  late int _lastHandledTabIndex;

  final List<StatusTabDefinition<RegularizeStatus>> _tabs = const [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: RegularizeStatus.pending),
    StatusTabDefinition(label: 'Approved', status: RegularizeStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: RegularizeStatus.rejected),
  ];

  RequestAudienceScope _selectedScope = RequestAudienceScope.allUsers;

  @override
  void initState() {
    super.initState();
    _regularizeRequestBloc = RegularizeRequestBloc();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _lastHandledTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
  }

  RegularizeStatus? get _selectedTabStatus => _tabs[_tabController.index].status;

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _regularizeRequestBloc.close();
    super.dispose();
  }

  Future<void> _refreshTabData({
    required int clientId,
    required RequestAudienceScope scope,
    required RegularizeStatus? status,
  }) async {
    _regularizeRequestBloc.add(
      LoadTeamRegularizeRequests(
        clientId: clientId,
        scope: scope,
        status: status,
        limit: _pageSize,
        forceRefresh: true,
      ),
    );

    await _regularizeRequestBloc.stream.firstWhere((state) {
      if (state is RegularizeRequestLoaded) {
        return !state.isRefreshing &&
            state.selectedScope == scope &&
            state.statusFilter == status;
      }

      return state is RegularizeRequestError;
    });
  }

  void _handleTabChange() {
    if (!mounted || _lastHandledTabIndex == _tabController.index) {
      return;
    }

    _lastHandledTabIndex = _tabController.index;
    setState(() {});

    final currentState = _regularizeRequestBloc.state;
    final scope =
        currentState is RegularizeRequestLoaded
            ? currentState.selectedScope
            : _selectedScope;

    _regularizeRequestBloc.add(
      LoadTeamRegularizeRequests(
        clientId: _resolveClientId(context),
        scope: scope,
        status: _selectedTabStatus,
        limit: _pageSize,
      ),
    );
  }

  Widget _buildRegularizeTabContent(
    BuildContext context, {
    required int clientId,
    required double screenHeight,
    required RegularizeRequestLoaded viewState,
    required bool isCurrentTab,
  }) {
    if (isCurrentTab && viewState.isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isCurrentTab && viewState.contentErrorMessage != null) {
      return ApiErrorState(
        rawMessage: viewState.contentErrorMessage!,
        onRetry:
            () => context.read<RegularizeRequestBloc>().add(
              LoadTeamRegularizeRequests(
                clientId: clientId,
                scope: viewState.selectedScope,
                status: viewState.statusFilter,
                limit: _pageSize,
                forceRefresh: true,
              ),
            ),
      );
    }

    final visibleRequests =
        viewState.filteredRegularizeRequests
            .where((request) => request.status != RegularizeStatus.withdrawn)
            .toList();

    if (visibleRequests.isEmpty) {
      return const RequestEmptyState();
    }

    final grouped = RequestGroupingUtils.groupByMonth(
      items: visibleRequests,
      dateSelector: (item) => item.appliedDate,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isCurrentTab &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            viewState.hasMore &&
            !viewState.isLoadingMore) {
          context.read<RegularizeRequestBloc>().add(
            LoadMoreTeamRegularizeRequests(
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
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final request = entry as RegularizeRequestModel;
            return RegularizeRequestCard(
              regularizeRequest: request,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RegularizeDetailPage(
                          regularizeRequest: request,
                          isApprovalMode: true,
                        ),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<RegularizeRequestBloc>().add(
                    LoadTeamRegularizeRequests(
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
      anyOf: ModulePermissions.regularizeApproval,
    );

    if (!hasAccess) {
      return ResponsiveScaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          forceMaterialTransparency: true,
          elevation: 0,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            'Regularize Approval',
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
          message:
              'You do not have permission to view team regularize approvals.',
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

    if (_regularizeRequestBloc.state is RegularizeRequestInitial) {
      _regularizeRequestBloc.add(
        LoadTeamRegularizeRequests(
          clientId: clientId,
          scope: _selectedScope,
          status: _selectedTabStatus,
          limit: _pageSize,
        ),
      );
    }

    return BlocProvider.value(
      value: _regularizeRequestBloc,
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
            'Regularize Approval',
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
                  _buildSearchSection(blocContext, availableScopes),
                  SizedBox(height: screenHeight * 0.01),
                  Expanded(
                    child: BlocBuilder<
                      RegularizeRequestBloc,
                      RegularizeRequestState
                    >(
                      builder: (context, state) {
                        if (state is RegularizeRequestLoading ||
                            state is RegularizeRequestInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is RegularizeRequestError) {
                          return ApiErrorState(
                            rawMessage: state.message,
                            onRetry:
                                () => context
                                    .read<RegularizeRequestBloc>()
                                    .add(
                                      LoadTeamRegularizeRequests(
                                        clientId: clientId,
                                        scope: _selectedScope,
                                        status: _selectedTabStatus,
                                        limit: _pageSize,
                                        forceRefresh: true,
                                      ),
                                    ),
                          );
                        }

                        final loaded = state as RegularizeRequestLoaded;

                        return StatusTabbedSection<
                          RegularizeStatus,
                          RegularizeRequestModel
                        >(
                          controller: _tabController,
                          tabs: _tabs,
                          items: loaded.regularizeRequests,
                          searchQuery: loaded.searchQuery?.toLowerCase() ?? '',
                          countOverrides: {
                            null: loaded.totalCount,
                            RegularizeStatus.pending: loaded.pendingCount,
                            RegularizeStatus.approved: loaded.approvedCount,
                            RegularizeStatus.rejected: loaded.rejectedCount,
                          },
                          statusSelector: (item) => item.status,
                          matchesSearch: (item, query) {
                            if (query.isEmpty) return true;
                            return item.reason.toLowerCase().contains(query) ||
                                (item.description?.toLowerCase().contains(
                                      query,
                                    ) ??
                                    false) ||
                                item.requestType.displayName
                                    .toLowerCase()
                                    .contains(query) ||
                                (item.regularizedBy?.toLowerCase().contains(
                                      query,
                                    ) ??
                                    false);
                          },
                          tabColorBuilder: RequestTabTheme.colorForIndex,
                          tabContentBuilder: (context, tab) {
                            final rawTabState =
                                tab.status == loaded.statusFilter
                                    ? loaded
                                    : _regularizeRequestBloc
                                        .getCachedTeamRegularizeRequests(
                                          scope: _selectedScope,
                                          status: tab.status,
                                        );

                            if (rawTabState == null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final tabState =
                                _regularizeRequestBloc
                                    .buildTeamRegularizeViewState(
                                      baseState: rawTabState,
                                      searchQuery: loaded.searchQuery,
                                    );

                            return _buildRegularizeTabContent(
                              context,
                              clientId: clientId,
                              screenHeight: screenHeight,
                              viewState: tabState,
                              isCurrentTab: tab.status == loaded.statusFilter,
                            );
                          },
                          emptyBuilder: (context) => const RequestEmptyState(),
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
              style: AppTextStyles.bodyMedium(context),
              onChanged: (value) {
                context.read<RegularizeRequestBloc>().add(
                  SearchRegularizeRequests(value),
                );
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
            context.read<RegularizeRequestBloc>().add(
              LoadTeamRegularizeRequests(
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
