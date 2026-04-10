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
  RequestAudienceScope _selectedScope = RequestAudienceScope.allUsers;
  static const int _pageSize = 50;

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

    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = WfhRemoteDataSourceImpl(apiClient: apiClient);
    final repository = WfhRepositoryImpl(remoteDataSource: remoteDataSource);
    final getWfhRequestsUseCase = GetWfhRequestsUseCase(repository);
    final getWfhRequestStatsUseCase = GetWfhRequestStatsUseCase(repository);
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
      create:
          (_) =>
              WfhRequestBloc(
                getWfhRequestsUseCase: getWfhRequestsUseCase,
                getWfhRequestStatsUseCase: getWfhRequestStatsUseCase,
                getTeamWfhRequestsUseCase: GetTeamWfhRequestsUseCase(
                  repository,
                ),
              )..add(
                LoadTeamWfhRequests(
                  clientId: clientId,
                  scope: _selectedScope,
                  limit: _pageSize,
                ),
              ),
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
                                        limit: _pageSize,
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
                          emptyBuilder: (context) => _buildEmpty(
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
                                        200) {
                                  context.read<WfhRequestBloc>().add(
                                    LoadMoreTeamWfhRequests(
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
                                        style: AppTextStyles.bodySmall(context)
                                            .copyWith(
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

  Widget _buildEmpty(BuildContext context, double w, double h) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: w * 0.15, color: AppColors.textTertiary),
          SizedBox(height: h * 0.02),
          Text(
            'No Data',
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
            setState(() {
              _selectedScope = scope;
            });
            context.read<WfhRequestBloc>().add(
              LoadTeamWfhRequests(
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
