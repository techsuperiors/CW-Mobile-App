import 'package:collectivWork/core/constants/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../request/presentation/widgets/request_listing/request_empty_state.dart';
import '../../../../../../../request/presentation/widgets/request_listing/request_grouping_utils.dart';
import '../../../../../../../request/presentation/widgets/request_listing/request_tab_theme.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../data/expense_remote_data.dart';
import '../../data/models/expense_item_model.dart';
import 'edit_expense_page.dart';
import 'expense_detail_page.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage>
    with TickerProviderStateMixin {
  late final TabController _topTabController;
  late final TabController _statusTabController;
  final TextEditingController _searchController = TextEditingController();
  final ExpenseRemoteData _remoteData = ExpenseRemoteData(
    apiClient: ApiClient(
      dio: Dio(),
      networkInfo: NetworkInfoImpl(Connectivity()),
    ),
  );

  Future<List<ExpenseItemModel>>? _reimbursementFuture;
  int? _loadedUserId;

  static const List<StatusTabDefinition<ExpenseApprovalStatus>> _statusTabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(
      label: 'Pending',
      status: ExpenseApprovalStatus.pending,
    ),
    StatusTabDefinition(
      label: 'Approved',
      status: ExpenseApprovalStatus.approved,
    ),
    StatusTabDefinition(
      label: 'Rejected',
      status: ExpenseApprovalStatus.rejected,
    ),
    StatusTabDefinition(
      label: 'Withdrawn',
      status: ExpenseApprovalStatus.withdrawn,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _topTabController = TabController(length: 2, vsync: this);
    _topTabController.addListener(() {
      if (mounted) setState(() {});
    });
    _statusTabController = TabController(
      length: _statusTabs.length,
      vsync: this,
    );
    _statusTabController.addListener(() {
      if (mounted) setState(() {});
    });
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _topTabController.dispose();
    _statusTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _ensureLoaded(int userId) {
    if (_loadedUserId == userId && _reimbursementFuture != null) return;
    _loadedUserId = userId;
    _reimbursementFuture = _remoteData.getReimbursements(userId: userId);
  }

  void _reload() {
    if (_loadedUserId == null) return;
    setState(() {
      _reimbursementFuture = _remoteData.getReimbursements(
        userId: _loadedUserId!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return ResponsiveScaffold(
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
          AppStrings.expenses,
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _topTabController,
            automaticIndicatorColorAdjustment: false,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [Tab(text: 'Reimbursement'), Tab(text: 'Approval')],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: TabBarView(
        controller: _topTabController,
        children: [
          BlocBuilder<UserProfileBloc, UserProfileState>(
            builder: (context, state) {
              if (state is! UserProfileLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              _ensureLoaded(state.profile.userId);
              return Column(
                children: [
                  _buildToolbar(context),
                  SizedBox(height: screenHeight * 0.02),
                  Expanded(
                    child: FutureBuilder<List<ExpenseItemModel>>(
                      future: _reimbursementFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return ApiErrorState(
                            rawMessage: snapshot.error.toString(),
                            onRetry: _reload,
                          );
                        }
                        final items = snapshot.data ?? const [];
                        return StatusTabbedSection<
                          ExpenseApprovalStatus,
                          ExpenseItemModel
                        >(
                          controller: _statusTabController,
                          tabs: _statusTabs,
                          items: items,
                          searchQuery:
                              _searchController.text.trim().toLowerCase(),
                          statusSelector: (item) => item.approvalStatus,
                          matchesSearch: (item, query) {
                            if (query.isEmpty) return true;
                            return item.expenseName.toLowerCase().contains(
                                  query,
                                ) ||
                                item.expenseType.toLowerCase().contains(
                                  query,
                                ) ||
                                (item.invoiceNumber?.toLowerCase().contains(
                                      query,
                                    ) ??
                                    false);
                          },
                          tabColorBuilder: RequestTabTheme.colorForIndex,
                          emptyBuilder: (context) => const RequestEmptyState(),
                          listBuilder: (context, filteredItems) {
                            final grouped = RequestGroupingUtils.groupByMonth(
                              items: filteredItems,
                              dateSelector: (item) => item.fromDate,
                            );
                            return ListView.builder(
                              padding: EdgeInsets.only(
                                bottom: screenHeight * 0.01,
                              ),
                              itemCount: grouped.length,
                              itemBuilder: (context, index) {
                                final entry = grouped[index];
                                if (entry is String) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top: index == 0 ? 0 : 14,
                                      bottom: 10,
                                      left: 14,
                                      right: 14,
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
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.002,
                                    vertical: screenHeight * 0.006,
                                  ),
                                  child: _ExpenseCard(
                                    item: entry as ExpenseItemModel,
                                    onTap: () async {
                                      final shouldRefresh =
                                          await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ExpenseDetailPage(
                                                expense: entry,
                                              ),
                                        ),
                                      );
                                      if (shouldRefresh == true && mounted) {
                                        _reload();
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const _ApprovalPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.060,
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
                  vertical: MediaQuery.of(context).size.height * 0.010,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.042),
        SizedBox(
          height: screenHeight * 0.060, // 5.0% of screen height
          child: InkWell(
            onTap: () async {
              final state = context.read<UserProfileBloc>().state;
              if (state is! UserProfileLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User profile is still loading.'),
                  ),
                );
                return;
              }
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseFormPage(userId: state.profile.userId),
                ),
              );
            },
            customBorder: const CircleBorder(),
            child: SvgPicture.asset(AppAssets.addIcon),
          ),
        ),
      ],
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseItemModel item;
  final VoidCallback onTap;

  const _ExpenseCard({required this.item, required this.onTap});

  Color get _accentColor {
    switch (item.approvalStatus) {
      case ExpenseApprovalStatus.approved:
        return const Color(0xFF12B76A);
      case ExpenseApprovalStatus.rejected:
      case ExpenseApprovalStatus.withdrawn:
        return const Color(0xFFF04438);
      case ExpenseApprovalStatus.pending:
      case ExpenseApprovalStatus.unknown:
        return const Color(0xFF0086C9);
    }
  }

  String get _statusLabel {
    return item.approvalStatusLabel;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.02,
                height: screenHeight * 0.14,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.016,
                    horizontal: screenWidth * 0.04,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.expenseName,
                              style: AppTextStyles.bodyMediumHeading(
                                context,
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding:  EdgeInsets.symmetric(
                              horizontal: screenWidth*0.02,
                              vertical: screenHeight*0.003,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel,
                              style: AppTextStyles.labelSmall(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                       SizedBox(height: screenHeight*0.008),
                      Text(
                        'Amount : ${NumberFormat.currency(symbol: '₹ ', decimalDigits: 0).format(item.amount)}',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textPrimary),
                      ),
                      SizedBox(height: screenHeight*0.004),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: _accentColor,
                          ),
                           SizedBox(width: screenWidth*0.02),
                          Text(
                            '${DateFormat('MMM d').format(item.fromDate)} to ${DateFormat('MMM d').format(item.toDate)}',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: _accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                       SizedBox(height: screenHeight*0.004),
                      Text(
                        'Duration : ${item.durationDays} ${item.durationDays == 1 ? 'day' : 'days'}',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovalPlaceholder extends StatelessWidget {
  const _ApprovalPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.approval_outlined,
              size: 56,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 14),
            Text(
              'Approval tab is ready for integration.',
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Reimbursement listing is live. Approval data API is still needed to populate this tab.',
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
