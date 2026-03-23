import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../core/constants/module_permissions.dart';
import '../../../../../../core/utils/permission_checker.dart';
import '../../../../../../core/widgets/access_denied_view.dart';
import '../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../request/presentation/widgets/request_listing/request_empty_state.dart';
import '../../../../../request/presentation/widgets/request_listing/request_grouping_utils.dart';
import '../../../../../request/presentation/widgets/request_listing/request_tab_theme.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/bloc/regularize_request_bloc.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/bloc/regularize_request_event.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/bloc/regularize_request_state.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/models/regularize_request_model.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/presentation/pages/regularize_detail_page.dart';
import '../../../../../request/presentation/pages/sub_requets/regularize/presentation/widgets/regularize_request_card.dart';

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

  final List<StatusTabDefinition<RegularizeStatus>> _tabs = const [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: RegularizeStatus.pending),
    StatusTabDefinition(label: 'Approved', status: RegularizeStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: RegularizeStatus.rejected),
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
        body: const AccessDeniedView(
          title: 'Approval Access Required',
          message:
              'You do not have permission to view team regularize approvals.',
        ),
      );
    }

    return BlocProvider(
      create:
          (_) => RegularizeRequestBloc()..add(const LoadTeamRegularizeRequests()),
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
            'Regularize Approval',
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
                                    .add(const LoadTeamRegularizeRequests()),
                          );
                        }

                        final loaded = state as RegularizeRequestLoaded;
                        final items =
                            loaded.regularizeRequests
                                .where(
                                  (request) =>
                                      request.status !=
                                      RegularizeStatus.withdrawn,
                                )
                                .toList();

                        return StatusTabbedSection<
                          RegularizeStatus,
                          RegularizeRequestModel
                        >(
                          controller: _tabController,
                          tabs: _tabs,
                          items: items,
                          searchQuery: loaded.searchQuery?.toLowerCase() ?? '',
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
                          emptyBuilder: (context) => const RequestEmptyState(),
                          listBuilder: (context, list) {
                            final grouped = RequestGroupingUtils.groupByMonth(
                              items: list,
                              dateSelector: (item) => item.appliedDate,
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
                                        const LoadTeamRegularizeRequests(),
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
    );
  }
}
