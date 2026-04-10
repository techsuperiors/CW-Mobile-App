import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:collectivWork/core/constants/app_colors.dart';
import 'package:collectivWork/core/constants/app_text_styles.dart';
import 'package:collectivWork/core/constants/module_permissions.dart';
import 'package:collectivWork/core/network/api_client.dart';
import 'package:collectivWork/core/network/network_info.dart';
import 'package:collectivWork/core/utils/data_encoder.dart';
import 'package:collectivWork/core/utils/permission_checker.dart';
import 'package:collectivWork/core/utils/token_storage.dart';
import 'package:collectivWork/core/widgets/access_denied_view.dart';
import 'package:collectivWork/core/widgets/api_error_state.dart';
import 'package:collectivWork/core/widgets/responsive_scaffold.dart';
import 'package:collectivWork/core/widgets/status_tabbed_section.dart';
import 'package:collectivWork/features/user/presentation/bloc/user_profile_bloc.dart';
import 'package:collectivWork/features/user/presentation/bloc/user_profile_state.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/data/datasources/leaves_remote_datasource.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/data/repositories/leaves_repository_impl.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/entities/leave_entity.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/usecases/apply_leave_usecase.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/usecases/get_leaves_usecase.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/domain/usecases/get_team_leave_requests_usecase.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/bloc/leave_request_bloc.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/bloc/leave_request_event.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/bloc/leave_request_state.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/pages/leave_detail_page.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/leaves/presentation/widgets/leave_request_card.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_filter_button.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_empty_state.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_grouping_utils.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_tab_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../core/utils/navigation_helper.dart';
import '../../../../../home/presentation/widgets/bottom_nav_bar.dart';

class LeaveApprovalPageListing extends StatefulWidget {
  const LeaveApprovalPageListing({super.key});

  @override
  State<LeaveApprovalPageListing> createState() =>
      _LeaveApprovalPageListingState();
}

class _LeaveApprovalPageListingState extends State<LeaveApprovalPageListing>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  static const int _pageSize = 5;
  RequestAudienceScope _selectedScope = RequestAudienceScope.allUsers;

  static const List<StatusTabDefinition<LeaveStatus>> _tabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: LeaveStatus.pending),
    StatusTabDefinition(label: 'Approved', status: LeaveStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: LeaveStatus.rejected),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
    final clientId = _resolveClientId();
    final allowAllUsers = _allowAllUsers(context);
    if (!allowAllUsers && _selectedScope == RequestAudienceScope.allUsers) {
      _selectedScope = RequestAudienceScope.myReportees;
    }
    final availableScopes =
        allowAllUsers
            ? RequestAudienceScope.values
            : const [
              RequestAudienceScope.myReportees,
              RequestAudienceScope.myIndirectReportees,
            ];
    final hasAccess = PermissionChecker.hasPermission(
      context,
      anyOf: ModulePermissions.leaveApproval,
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
            'Leave Approval',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: const AccessDeniedView(
          title: 'Approval Access Required',
          message: 'You do not have permission to view team leave approvals.',
        ),
      );
    }

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
        return LeaveRequestBloc(
          getLeavesUseCase: GetLeavesUseCase(repository),
          getTeamLeaveRequestsUseCase: GetTeamLeaveRequestsUseCase(repository),
          applyLeaveUseCase: ApplyLeaveUseCase(repository),
        )..add(
          LoadTeamLeaveRequests(
            clientId: clientId,
            scope: _selectedScope,
            limit: _pageSize,
          ),
        );
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
            'Leave Approval',
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
                    clientId,
                    availableScopes,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Expanded(
                    child: BlocBuilder<LeaveRequestBloc, LeaveRequestState>(
                      builder: (context, state) {
                        if (state is LeaveRequestLoading ||
                            state is LeaveRequestInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is LeaveRequestError) {
                          return ApiErrorState(
                            rawMessage: state.message,
                            onRetry:
                                () => context.read<LeaveRequestBloc>().add(
                                  LoadTeamLeaveRequests(
                                    clientId: clientId,
                                    scope: _selectedScope,
                                    limit: _pageSize,
                                  ),
                                ),
                          );
                        }

                        final loaded = state as LeaveRequestLoaded;

                        return StatusTabbedSection<LeaveStatus, LeaveEntity>(
                          controller: _tabController,
                          tabs: _tabs,
                          items: loaded.leaveRequests,
                          searchQuery: loaded.searchQuery?.toLowerCase() ?? '',
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
                          countOverrides:
                          {
                            null: loaded.totalLeaveRequest,
                            LeaveStatus.pending: loaded.pendingListCount,
                            LeaveStatus.approved: loaded.approvedListCount,
                            LeaveStatus.rejected: loaded.rejectListCount,
                          },
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
                                            200 &&
                                    loaded.hasMore &&
                                    !loaded.isLoadingMore) {
                                  context.read<LeaveRequestBloc>().add(
                                    LoadMoreTeamLeaveRequests(
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
                                                isApprovalMode: true,
                                              ),
                                        ),
                                      );
                                      if (result == true && context.mounted) {
                                        context.read<LeaveRequestBloc>().add(
                                          LoadTeamLeaveRequests(
                                            clientId: clientId,
                                            scope: loaded.selectedScope,
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

  Widget _buildSearchSection(
    BuildContext context,
    int clientId,
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
                context.read<LeaveRequestBloc>().add(
                  SearchLeaveRequests(value),
                );
              },
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // 4.2% of screen width
        RequestAudienceFilterButton(
          selectedScope: _selectedScope,
          availableScopes: availableScopes,
          onSelected: (scope) {
            if (scope == _selectedScope) return;
            setState(() {
              _selectedScope = scope;
            });
            context.read<LeaveRequestBloc>().add(
              LoadTeamLeaveRequests(
                clientId: clientId,
                scope: scope,
                limit: _pageSize,
              ),
            );
          },
        ),
      ],
    );
  }

  int _resolveClientId() {
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return 0;
    }

    final decoded = decodeData<Map<String, dynamic>>(token);
    final clientId = decoded?['client_id'];
    if (clientId is int) return clientId;
    if (clientId is String) return int.tryParse(clientId) ?? 0;
    return 0;
  }

  bool _allowAllUsers(BuildContext context) {
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is UserProfileLoaded) {
      return profileState.profile.allowAllUsers;
    }
    return false;
  }
}
