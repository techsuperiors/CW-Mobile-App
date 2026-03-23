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
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/bloc/comp_off_request_bloc.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/bloc/comp_off_request_event.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/bloc/comp_off_request_state.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/data/datasources/comp_off_remote_datasource.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/data/repositories/comp_off_repository_impl.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/domain/usecases/get_comp_off_requests.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/domain/usecases/get_team_comp_off_requests.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/models/comp_off_request_model.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/presentation/pages/comp_off_detail_page.dart';
import 'package:collectivWork/features/request/presentation/pages/sub_requets/comp_off/presentation/widgets/comp_off_request_card.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_empty_state.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_grouping_utils.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_tab_theme.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CompOffApprovalPageListing extends StatefulWidget {
  const CompOffApprovalPageListing({super.key});

  @override
  State<CompOffApprovalPageListing> createState() =>
      _CompOffApprovalPageListingState();
}

class _CompOffApprovalPageListingState extends State<CompOffApprovalPageListing>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  final List<StatusTabDefinition<CompOffStatus>> _tabs = const [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: CompOffStatus.pending),
    StatusTabDefinition(label: 'Approved', status: CompOffStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: CompOffStatus.rejected),
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
    final hasAccess = PermissionChecker.hasPermission(
      context,
      anyOf: ModulePermissions.compOffApproval,
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
            'Comp-Off Approval',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: const AccessDeniedView(
          title: 'Approval Access Required',
          message:
              'You do not have permission to view team comp-off approvals.',
        ),
      );
    }
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = CompOffRemoteDataSourceImpl(apiClient: apiClient);
    final repository = CompOffRepositoryImpl(remoteDataSource: remoteDataSource);

    return BlocProvider(
      create:
          (_) => CompOffRequestBloc(
            getCompOffRequestsUseCase: GetCompOffRequestsUseCase(repository),
            getTeamCompOffRequestsUseCase: GetTeamCompOffRequestsUseCase(
              repository,
            ),
          )..add(const LoadTeamCompOffRequests()),
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
                    style: AppTextStyles.bodyLarge(context).copyWith(
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
            'Comp-Off Approval',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Builder(
          builder:
              (blocContext) => Column(
                children: [
                  _buildSearchSection(blocContext),
                  SizedBox(height: screenHeight * 0.01),
                  Expanded(
                    child: BlocBuilder<CompOffRequestBloc, CompOffRequestState>(
                      builder: (context, state) {
                        if (state is CompOffRequestLoading ||
                            state is CompOffRequestInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (state is CompOffRequestError) {
                          return ApiErrorState(
                            rawMessage: state.message,
                            onRetry:
                                () => context
                                    .read<CompOffRequestBloc>()
                                    .add(const LoadTeamCompOffRequests()),
                          );
                        }

                        final loaded = state as CompOffRequestLoaded;
                        final items =
                            loaded.requests
                                .where(
                                  (request) =>
                                      request.status != CompOffStatus.withdrawn,
                                )
                                .toList();

                        return StatusTabbedSection<
                          CompOffStatus,
                          CompOffRequestModel
                        >(
                          controller: _tabController,
                          tabs: _tabs,
                          items: items,
                          searchQuery: loaded.searchQuery?.toLowerCase() ?? '',
                          statusSelector: (item) => item.status,
                          matchesSearch: (item, query) {
                            if (query.isEmpty) return true;
                            return item.subject.toLowerCase().contains(query) ||
                                item.reason.toLowerCase().contains(query);
                          },
                          tabColorBuilder: RequestTabTheme.colorForIndex,
                          emptyBuilder: (context) => const RequestEmptyState(),
                          listBuilder: (context, list) {
                            final grouped = RequestGroupingUtils.groupByMonth(
                              items: list,
                              dateSelector: (item) => item.createdAt,
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

                                final req = entry as CompOffRequestModel;
                                return CompOffRequestCard(
                                  request: req,
                                  onTap: () async {
                                    final refresh = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => CompOffDetailPage(
                                              request: req,
                                              isApprovalMode: true,
                                            ),
                                      ),
                                    );
                                    if (refresh == true && context.mounted) {
                                      context.read<CompOffRequestBloc>().add(
                                        const LoadTeamCompOffRequests(),
                                      );
                                    }
                                  },
                                );
                              },
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

  Widget _buildSearchSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
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
        onChanged: (value) {
          context.read<CompOffRequestBloc>().add(SearchCompOffRequests(value));
        },
      ),
    );
  }
}
