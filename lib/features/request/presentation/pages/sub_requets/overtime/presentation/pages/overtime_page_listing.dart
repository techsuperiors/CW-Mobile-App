import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
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
import '../../../../../widgets/request_listing/request_empty_state.dart';
import '../../../../../widgets/request_listing/request_grouping_utils.dart';
import '../../../../../widgets/request_listing/request_tab_theme.dart';
import '../../bloc/overtime_request_bloc.dart';
import '../../bloc/overtime_request_event.dart';
import '../../bloc/overtime_request_state.dart';
import '../../data/datasources/overtime_remote_datasource.dart';
import '../../data/repositories/overtime_repository_impl.dart';
import '../../domain/usecases/get_overtime_request_stats.dart';
import '../../domain/usecases/get_overtime_requests.dart';
import '../../models/overtime_request_model.dart';
import '../widgets/overtime_request_card.dart';
import 'apply_overtime_page.dart';
import 'overtime_detail_page.dart';

class OvertimePageListing extends StatefulWidget {
  const OvertimePageListing({super.key});

  @override
  State<OvertimePageListing> createState() => _OvertimePageListingState();
}

class _OvertimePageListingState extends State<OvertimePageListing>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 5;
  final TextEditingController _searchController = TextEditingController();
  late final OvertimeRequestBloc _overtimeRequestBloc;
  late TabController _tabController;
  late int _lastHandledTabIndex;

  static const List<StatusTabDefinition<OvertimeStatus>> _tabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: OvertimeStatus.pending),
    StatusTabDefinition(label: 'Approved', status: OvertimeStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: OvertimeStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = OvertimeRemoteDataSourceImpl(apiClient: apiClient);
    final repository = OvertimeRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    _overtimeRequestBloc = OvertimeRequestBloc(
      getOvertimeRequestsUseCase: GetOvertimeRequestsUseCase(repository),
      getOvertimeRequestStatsUseCase: GetOvertimeRequestStatsUseCase(
        repository,
      ),
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
    _overtimeRequestBloc.close();
    super.dispose();
  }

  OvertimeStatus? get _selectedTabStatus => _tabs[_tabController.index].status;

  void _handleTabChange() {
    if (!mounted || _lastHandledTabIndex == _tabController.index) {
      return;
    }

    _lastHandledTabIndex = _tabController.index;
    setState(() {});

    _overtimeRequestBloc.add(
      LoadOvertimeRequests(
        clientId: _resolveClientId(),
        status: _selectedTabStatus,
        limit: _pageSize,
      ),
    );
  }

  Future<void> _refreshTabData({
    required int clientId,
    required OvertimeStatus? status,
  }) async {
    _overtimeRequestBloc.add(
      LoadOvertimeRequests(
        clientId: clientId,
        status: status,
        limit: _pageSize,
        forceRefresh: true,
      ),
    );

    await _overtimeRequestBloc.stream.firstWhere((state) {
      if (state is OvertimeRequestLoaded) {
        return !state.isRefreshing && state.statusFilter == status;
      }
      return state is OvertimeRequestError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final clientId = _resolveClientId();

    if (_overtimeRequestBloc.state is OvertimeRequestInitial) {
      _overtimeRequestBloc.add(
        LoadOvertimeRequests(
          clientId: clientId,
          status: _selectedTabStatus,
          limit: _pageSize,
        ),
      );
    }

    return BlocProvider.value(
      value: _overtimeRequestBloc,
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
            'Overtime',
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
                    child:
                        BlocBuilder<OvertimeRequestBloc, OvertimeRequestState>(
                          builder: (context, state) {
                            if (state is OvertimeRequestLoading ||
                                state is OvertimeRequestInitial) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (state is OvertimeRequestError) {
                              return ApiErrorState(
                                title: 'Unable to load overtime requests',
                                rawMessage: state.message,
                                onRetry:
                                    () => context
                                        .read<OvertimeRequestBloc>()
                                        .add(
                                          LoadOvertimeRequests(
                                            clientId: clientId,
                                            status: _selectedTabStatus,
                                            limit: _pageSize,
                                            forceRefresh: true,
                                          ),
                                        ),
                              );
                            }

                            final loaded = state as OvertimeRequestLoaded;
                            return StatusTabbedSection<
                              OvertimeStatus,
                              OvertimeRequestModel
                            >(
                              controller: _tabController,
                              tabs: _tabs,
                              items: loaded.requests,
                              searchQuery:
                                  loaded.searchQuery?.toLowerCase() ?? '',
                              statusSelector: (item) => item.status,
                              matchesSearch: (item, query) {
                                if (query.isEmpty) return true;
                                return item.subject.toLowerCase().contains(
                                      query,
                                    ) ||
                                    item.status.displayName.toLowerCase()
                                        .contains(query);
                              },
                              tabColorBuilder: RequestTabTheme.colorForIndex,
                              countOverrides: {
                                null: loaded.totalCount,
                                OvertimeStatus.pending: loaded.pendingCount,
                                OvertimeStatus.approved: loaded.approvedCount,
                                OvertimeStatus.rejected: loaded.rejectedCount,
                              },
                              emptyBuilder: (_) => const RequestEmptyState(),
                              tabContentBuilder: (context, tab) {
                                final rawTabState =
                                    tab.status == loaded.statusFilter
                                        ? loaded
                                        : _overtimeRequestBloc
                                            .getCachedOvertimeRequests(
                                              status: tab.status,
                                            );

                                if (rawTabState == null) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final tabState = _overtimeRequestBloc
                                    .buildOvertimeViewState(
                                      baseState: rawTabState,
                                      searchQuery: loaded.searchQuery,
                                    );

                                return _buildOvertimeTabContent(
                                  context,
                                  clientId: clientId,
                                  screenHeight: screenHeight,
                                  viewState: tabState,
                                  isCurrentTab:
                                      tab.status == loaded.statusFilter,
                                );
                              },
                              listBuilder: (_, __) => const SizedBox.shrink(),
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

  Widget _buildOvertimeTabContent(
    BuildContext context, {
    required int clientId,
    required double screenHeight,
    required OvertimeRequestLoaded viewState,
    required bool isCurrentTab,
  }) {
    if (isCurrentTab && viewState.isRefreshing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isCurrentTab && viewState.contentErrorMessage != null) {
      return ApiErrorState(
        title: 'Unable to load overtime requests',
        rawMessage: viewState.contentErrorMessage!,
        onRetry:
            () => context.read<OvertimeRequestBloc>().add(
              LoadOvertimeRequests(
                clientId: clientId,
                status: viewState.statusFilter,
                limit: _pageSize,
                forceRefresh: true,
              ),
            ),
      );
    }

    if (viewState.filteredRequests.isEmpty) {
      return const RequestEmptyState();
    }

    final grouped = RequestGroupingUtils.groupByMonth(
      items: viewState.filteredRequests,
      dateSelector: (item) => item.appliedDate,
    );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isCurrentTab &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            viewState.hasMore &&
            !viewState.isLoadingMore) {
          context.read<OvertimeRequestBloc>().add(
            LoadMoreOvertimeRequests(
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
              status: viewState.statusFilter,
            ),
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

            final req = entry as OvertimeRequestModel;
            return OvertimeRequestCard(
              request: req,
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OvertimeDetailPage(overtimeRequest: req),
                  ),
                );
                if (result == true && context.mounted) {
                  context.read<OvertimeRequestBloc>().add(
                    LoadOvertimeRequests(
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

  Widget _buildSearchAndFilterSection(BuildContext context, int clientId) {
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
                context.read<OvertimeRequestBloc>().add(
                  SearchOvertimeRequests(value),
                );
              },
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042),
        InkWell(
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ApplyOvertimePage()),
            );
            if (result == true && context.mounted) {
              context.read<OvertimeRequestBloc>().add(
                LoadOvertimeRequests(
                  clientId: clientId,
                  status: _selectedTabStatus,
                  limit: _pageSize,
                  forceRefresh: true,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: screenHeight * 0.050,
            child: SvgPicture.asset(AppAssets.addIcon),
          ),
        ),
      ],
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
}
