import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../widgets/request_listing/request_empty_state.dart';
import '../../../../../widgets/request_listing/request_grouping_utils.dart';
import '../../../../../widgets/request_listing/request_tab_theme.dart';
import '../../../leaves/domain/entities/leave_entity.dart';
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
  RegularizeStatus? _selectedStatusFilter;
  late TabController _tabController;
  final List<StatusTabDefinition<RegularizeStatus>> _tabsregulrize = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: RegularizeStatus.pending),
    StatusTabDefinition(label: 'Approved', status: RegularizeStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: RegularizeStatus.rejected),
    StatusTabDefinition(label: 'Withdrawn', status: RegularizeStatus.withdrawn),
  ];

  @override
  void initState() {
    super.initState();

    ///For the tab bar and for controlling the behaviour of it
    _tabController = TabController(length: _tabsregulrize.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // BlocProvider will load regularize requests automatically in its create method
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

    return BlocProvider(
      create:
          (_) => RegularizeRequestBloc()..add(const LoadRegularizeRequests()),
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
                          return
                            ApiErrorState(
                              title: 'Unable to load regularize requests',
                              rawMessage: state.message,
                              onRetry: () {
                                final bloc =
                                context.read<RegularizeRequestBloc>();
                                bloc.add(const LoadRegularizeRequests());
                              },
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
                            emptyBuilder: (context) => RequestEmptyState(),
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
                                        context
                                            .read<RegularizeRequestBloc>()
                                            .add(
                                              const LoadRegularizeRequests(),
                                            );
                                      }
                                    },
                                  );
                                },
                              );
                            },
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
                      const LoadRegularizeRequests(),
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

  void _showFilterBottomSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get current filter state from bloc using the context that has BlocProvider
    final bloc = context.read<RegularizeRequestBloc>();
    final currentState = bloc.state;
    RegularizeStatus? currentFilter;
    if (currentState is RegularizeRequestLoaded) {
      currentFilter = currentState.statusFilter;
      // Sync local state with bloc state
      _selectedStatusFilter = currentFilter;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (bottomSheetContext) => StatefulBuilder(
            builder:
                (bottomSheetContext, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.042),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Status',
                        style: AppTextStyles.heading4(bottomSheetContext),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Filter options
                      _buildFilterOption(
                        bottomSheetContext,
                        'All',
                        null,
                        _selectedStatusFilter == null,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = null;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Pending',
                        RegularizeStatus.pending,
                        _selectedStatusFilter == RegularizeStatus.pending,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = RegularizeStatus.pending;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Approved',
                        RegularizeStatus.approved,
                        _selectedStatusFilter == RegularizeStatus.approved,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = RegularizeStatus.approved;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Rejected',
                        RegularizeStatus.rejected,
                        _selectedStatusFilter == RegularizeStatus.rejected,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = RegularizeStatus.rejected;
                          });
                        },
                      ),
                      _buildFilterOption(
                        bottomSheetContext,
                        'Withdrawn',
                        RegularizeStatus.withdrawn,
                        _selectedStatusFilter == RegularizeStatus.withdrawn,
                        () {
                          setModalState(() {
                            _selectedStatusFilter = RegularizeStatus.withdrawn;
                          });
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            // Use the bloc instance from the outer context
                            bloc.add(
                              FilterRegularizeRequestsByStatus(
                                _selectedStatusFilter,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.018,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Apply Filter',
                            style: AppTextStyles.buttonMedium(
                              bottomSheetContext,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    String label,
    RegularizeStatus? status,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.032),
            Text(
              label,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for dotted line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
