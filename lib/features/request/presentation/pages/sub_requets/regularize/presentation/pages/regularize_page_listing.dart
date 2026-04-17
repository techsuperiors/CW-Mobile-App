import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../widgets/request_listing/request_empty_state.dart';
import '../../../../../widgets/request_listing/request_grouping_utils.dart';
import '../../../../../widgets/request_listing/request_tab_theme.dart';
import '../../bloc/regularize_request_bloc.dart';
import '../../bloc/regularize_request_event.dart';
import '../../bloc/regularize_request_state.dart';
import '../../models/regularize_request_model.dart';
import '../widgets/regularize_request_card.dart';
import 'apply_regularize_page.dart';
import 'regularize_detail_page.dart';

/// Regularize listing page showing list of regularize requests
class RegularizePageListing extends StatefulWidget {
  const RegularizePageListing({super.key});

  @override
  State<RegularizePageListing> createState() => _RegularizePageListingState();
}

class _RegularizePageListingState extends State<RegularizePageListing>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final RegularizeRequestBloc _regularizeRequestBloc;
  late TabController _tabController;
  static const int _pageSize = 5;
  late int _lastHandledTabIndex;
  static const List<StatusTabDefinition<RegularizeStatus>> _tabsregulrize = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: RegularizeStatus.pending),
    StatusTabDefinition(label: 'Approved', status: RegularizeStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: RegularizeStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    _regularizeRequestBloc = RegularizeRequestBloc();

    _tabController = TabController(length: _tabsregulrize.length, vsync: this);
    _lastHandledTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _regularizeRequestBloc.close();
    super.dispose();
  }

  RegularizeStatus? get _selectedTabStatus => _tabsregulrize[_tabController.index].status;

  int _resolveClientId() {
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) return 0;
    final decoded = decodeData<Map<String, dynamic>>(token);
    final clientId = decoded?['client_id'];
    if (clientId is int) return clientId;
    if (clientId is String) return int.tryParse(clientId) ?? 0;
    return 0;
  }

  void _handleTabChange() {
    if (!mounted || _lastHandledTabIndex == _tabController.index) {
      return;
    }

    _lastHandledTabIndex = _tabController.index;
    setState(() {});

    _regularizeRequestBloc.add(
      LoadRegularizeRequests(
        clientId: _resolveClientId(),
        status: _selectedTabStatus,
        limit: _pageSize,
      ),
    );
  }

  Future<void> _refreshTabData({
    required int clientId,
    required RegularizeStatus? status,
  }) async {
    _regularizeRequestBloc.add(
      LoadRegularizeRequests(
        clientId: clientId,
        status: status,
        limit: _pageSize,
        forceRefresh: true,
      ),
    );

    await _regularizeRequestBloc.stream.firstWhere((state) {
      if (state is RegularizeRequestLoaded) {
        return !state.isRefreshing && state.statusFilter == status;
      }
      return state is RegularizeRequestError;
    });
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
        title: 'Unable to load regularize requests',
        rawMessage: viewState.contentErrorMessage!,
        onRetry:
            () => context.read<RegularizeRequestBloc>().add(
              LoadRegularizeRequests(
                clientId: clientId,
                status: viewState.statusFilter,
                limit: _pageSize,
                forceRefresh: true,
              ),
            ),
      );
    }

    if (viewState.filteredRegularizeRequests.isEmpty) {
      return const RequestEmptyState();
    }

    final grouped = RequestGroupingUtils.groupByMonth(
      items: viewState.filteredRegularizeRequests,
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
            LoadMoreRegularizeRequests(
              clientId: clientId,
              limit: _pageSize,
            ),
          );
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => _refreshTabData(clientId: clientId, status: viewState.statusFilter),
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

            final req = entry as RegularizeRequestModel;
            return RegularizeRequestCard(
              regularizeRequest: req,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RegularizeDetailPage(
                          regularizeRequest: req,
                        ),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<RegularizeRequestBloc>().add(
                    LoadRegularizeRequests(
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final clientId = _resolveClientId();

    if (_regularizeRequestBloc.state is RegularizeRequestInitial) {
      _regularizeRequestBloc.add(
        LoadRegularizeRequests(
          clientId: clientId,
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
            AppStrings.regularize,
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
                  SizedBox(height: screenHeight*0.01),

                  // Regularize requests list
                  Expanded(
                    child: BlocBuilder<
                      RegularizeRequestBloc,
                      RegularizeRequestState
                    >(
                      builder: (context, state) {
                        if (state is RegularizeRequestLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is RegularizeRequestError) {
                          return ApiErrorState(
                            title: 'Unable to load regularize requests',
                            rawMessage: state.message,
                            onRetry:
                                () => context.read<RegularizeRequestBloc>().add(
                                  LoadRegularizeRequests(
                                    clientId: clientId,
                                    status: _selectedTabStatus,
                                    limit: _pageSize,
                                    forceRefresh: true,
                                  ),
                                ),
                          );
                        }

                        if (state is RegularizeRequestLoaded) {
                          return StatusTabbedSection<
                            RegularizeStatus,
                            RegularizeRequestModel
                          >(
                            controller: _tabController,
                            tabs: _tabsregulrize,
                            items: state.regularizeRequests,
                            searchQuery: state.searchQuery?.toLowerCase() ?? '',
                            countOverrides: {
                              null: state.totalCount,
                              RegularizeStatus.pending: state.pendingCount,
                              RegularizeStatus.approved: state.approvedCount,
                              RegularizeStatus.rejected: state.rejectedCount,
                            },
                            statusSelector: (item) => item.status,
                            matchesSearch: (item, query) {
                              if (query.isEmpty) return true;
                              return item.reason.toLowerCase().contains(
                                    query,
                                  ) ||
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
                                  tab.status == state.statusFilter
                                      ? state
                                      : _regularizeRequestBloc.getCachedRegularizeRequests(
                                        status: tab.status,
                                      );

                              if (rawTabState == null) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final tabState = _regularizeRequestBloc.buildRegularizeViewState(
                                baseState: rawTabState,
                                searchQuery: state.searchQuery,
                              );

                              return _buildRegularizeTabContent(
                                context,
                                clientId: clientId,
                                screenHeight: screenHeight,
                                viewState: tabState,
                                isCurrentTab: tab.status == state.statusFilter,
                              );
                            },
                            emptyBuilder: (context) => const RequestEmptyState(),
                            listBuilder: (context, list) =>
                                const SizedBox.shrink(),
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
            height: screenHeight * 0.050, // 5.0% of screen height
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2), // light grey background
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

              style: AppTextStyles.bodyMedium(context),
              onChanged: (value) {
                context.read<RegularizeRequestBloc>().add(
                  SearchRegularizeRequests(value),
                );
              },
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // 4.2% of screen width
        // Add button (green circular button with plus) - opens form page
        PermissionGuard(
          requiredPermission: "Attendance:Regularize:Write",
          child: SizedBox(
            height: screenHeight * 0.050,// 5.0% of screen height


            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApplyRegularizePage(),
                    ),
                  );
                  if (result == true && context.mounted) {
                    context.read<RegularizeRequestBloc>().add(
                      LoadRegularizeRequests(
                        clientId: _resolveClientId(),
                        status: _selectedTabStatus,
                        limit: _pageSize,
                        forceRefresh: true,
                      ),
                    );
                  }
                },
                customBorder: const CircleBorder(),
                child: SvgPicture.asset(AppAssets.addIcon),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
