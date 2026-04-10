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
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/bloc/on_duty_request_bloc.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/bloc/on_duty_request_event.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/bloc/on_duty_request_state.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/data/datasources/on_duty_remote_datasource.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/data/repositories/on_duty_repository_impl.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/domain/usecases/get_on_duty_requests.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/domain/usecases/get_on_duty_request_stats.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/domain/usecases/get_team_on_duty_requests.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/models/on_duty_request_model.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/presentation/pages/on_duty_detail_page.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/on_duty/presentation/widgets/on_duty_request_card.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_filter_button.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_empty_state.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_grouping_utils.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_tab_theme.dart';
import 'package:collectivWork/features/user/presentation/bloc/user_profile_bloc.dart';
import 'package:collectivWork/features/user/presentation/bloc/user_profile_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../core/utils/navigation_helper.dart';
import '../../../../../home/presentation/widgets/bottom_nav_bar.dart';

class OnDutyApprovalPageListing extends StatefulWidget {
  const OnDutyApprovalPageListing({super.key});

  @override
  State<OnDutyApprovalPageListing> createState() =>
      _OnDutyApprovalPageListingState();
}

class _OnDutyApprovalPageListingState extends State<OnDutyApprovalPageListing>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  RequestAudienceScope _selectedScope = RequestAudienceScope.allUsers;
  static const int _pageSize = 50;

  static const List<StatusTabDefinition<OnDutyStatus>> _tabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: OnDutyStatus.pending),
    StatusTabDefinition(label: 'Approved', status: OnDutyStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: OnDutyStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
    final hasAccess = PermissionChecker.hasPermission(
      context,
      anyOf: ModulePermissions.onDutyApproval,
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
            'On Duty Approval',
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
          message: 'You do not have permission to view team on duty approvals.',
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
          getOnDutyRequestStatsUseCase: GetOnDutyRequestStatsUseCase(
            repository,
          ),
          getTeamOnDutyRequestsUseCase: GetTeamOnDutyRequestsUseCase(repository),
        )..add(
          LoadTeamOnDutyRequests(
            clientId: clientId,
            scope: _selectedScope,
            limit: _pageSize,
          ),
        );
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
            'On Duty Approval',
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
                    child: BlocBuilder<OnDutyRequestBloc, OnDutyRequestState>(
                      builder: (context, state) {
                        if (state is OnDutyRequestLoading ||
                            state is OnDutyRequestInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is OnDutyRequestError) {
                          return ApiErrorState(
                            rawMessage: state.message,
                            onRetry:
                                () => context
                                    .read<OnDutyRequestBloc>()
                                    .add(
                                      LoadTeamOnDutyRequests(
                                        clientId: clientId,
                                        scope: _selectedScope,
                                        limit: _pageSize,
                                      ),
                                    ),
                          );
                        }

                        final loaded = state as OnDutyRequestLoaded;
                        final items =
                            loaded.onDutyRequests
                                .where(
                                  (request) =>
                                      request.status != OnDutyStatus.withdrawn,
                                )
                                .toList();

                        return StatusTabbedSection<
                          OnDutyStatus,
                          OnDutyRequestModel
                        >(
                          controller: _tabController,
                          tabs: _tabs,
                          items: items,
                          searchQuery: loaded.searchQuery?.toLowerCase() ?? '',
                          countOverrides: {
                            null: loaded.totalCount,
                            OnDutyStatus.pending: loaded.pendingCount,
                            OnDutyStatus.approved: loaded.approvedCount,
                            OnDutyStatus.rejected: loaded.rejectedCount,
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
                          tabColorBuilder: RequestTabTheme.colorForIndex,
                          emptyBuilder: (context) => const RequestEmptyState(),
                          listBuilder: (context, list) {
                            final grouped = RequestGroupingUtils.groupByMonth(
                              items: list,
                              dateSelector: (item) => item.appliedDate,
                            );
                            return NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification.metrics.pixels >=
                                    notification.metrics.maxScrollExtent -
                                        200) {
                                  context.read<OnDutyRequestBloc>().add(
                                    LoadMoreTeamOnDutyRequests(
                                      clientId: clientId,
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
                                    (loaded.isLoadingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= grouped.length) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: screenHeight * 0.02,
                                      ),
                                      child: const Center(
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
                                                onDutyRequest: req,
                                                isApprovalMode: true,
                                              ),
                                        ),
                                      );
                                      if (shouldRefresh == true &&
                                          context.mounted) {
                                        context.read<OnDutyRequestBloc>().add(
                                          LoadTeamOnDutyRequests(
                                            clientId: clientId,
                                            scope: _selectedScope,
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
                context.read<OnDutyRequestBloc>().add(
                  SearchOnDutyRequests(value),
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
            setState(() {
              _selectedScope = scope;
            });
            context.read<OnDutyRequestBloc>().add(
              LoadTeamOnDutyRequests(
                clientId: _resolveClientId(context),
                scope: scope,
                limit: _pageSize,
              ),
            );
          },
        ),
      ],
    );
  }
}
