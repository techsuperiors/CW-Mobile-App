import 'package:collectivWork/features/attendance/data/models/attendance_details_model.dart';
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
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/widgets/status_tabbed_section.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../widgets/request_listing/request_empty_state.dart';
import '../../../../../widgets/request_listing/request_grouping_utils.dart';
import '../../../../../widgets/request_listing/request_tab_theme.dart';
import '../../../leaves/domain/entities/leave_entity.dart';
import '../../bloc/overtime_request_bloc.dart';
import '../../bloc/overtime_request_event.dart';
import '../../bloc/overtime_request_state.dart';
import '../../data/datasources/overtime_remote_datasource.dart';
import '../../data/repositories/overtime_repository_impl.dart';
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
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  OvertimeStatus? _selectedStatusFilter;
  late TabController _tabController;
  static const List<StatusTabDefinition<OvertimeStatus>> _overtimetabs = [
    StatusTabDefinition(label: 'All', status: null),
    StatusTabDefinition(label: 'Pending', status: OvertimeStatus.pending),
    StatusTabDefinition(label: 'Approved', status: OvertimeStatus.approved),
    StatusTabDefinition(label: 'Rejected', status: OvertimeStatus.rejected),
    StatusTabDefinition(label: 'Withdrawn', status: OvertimeStatus.withdrawn),
  ];

  @override
  void initState() {
    super.initState();

    ///For the tab bar and for controlling the behaviour of it
    _tabController = TabController(length: _overtimetabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // BlocProvider will load leave requests automatically in its create method
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
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = OvertimeRemoteDataSourceImpl(apiClient: apiClient);
    final repository = OvertimeRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    return BlocProvider(
      create:
          (_) => OvertimeRequestBloc(
            getOvertimeRequestsUseCase: GetOvertimeRequestsUseCase(repository),
          )..add(const LoadOvertimeRequests()),
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
                  _buildSearchAndFilterSection(blocContext),
                  SizedBox(height: screenHeight*0.01),
                  Expanded(
                    child: BlocBuilder<
                      OvertimeRequestBloc,
                      OvertimeRequestState
                    >(
                      builder: (context, state) {
                        if (state is OvertimeRequestLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is OvertimeRequestError) {
                        return  ApiErrorState(
                            title: 'Unable to load overtime requests',
                            rawMessage: "something went wrong",
                            onRetry: () {
                              context
                                  .read<OvertimeRequestBloc>()
                                  .add(const LoadOvertimeRequests());
                            },
                          );

                        }
                        if (state is OvertimeRequestLoaded) {
                          return StatusTabbedSection<
                            OvertimeStatus,
                            OvertimeRequestModel
                          >(
                            controller: _tabController,
                            tabs: _overtimetabs,
                            items: state.requests,
                            searchQuery: state.searchQuery?.toLowerCase() ?? '',
                            statusSelector: (item) => item.status,
                            // matchesSearch: (item, query) {
                            //   if (query.isEmpty) return true;
                            //   return (item.subject?.toLowerCase().contains(
                            //             query,
                            //           ) ??
                            //           false) ||
                            //       item.status.toLowerCase().contains(query);
                            // },
                            matchesSearch: (item, query) {
                              if (query.isEmpty) return true;
                              return item.subject.toLowerCase().contains(query) ||
                                  item.status.displayName.toLowerCase().contains(query);
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
                                  final req = entry as OvertimeRequestModel;

                                  return OvertimeRequestCard(
                                    request: req,
                                    onTap: () async {
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => OvertimeDetailPage(
                                                overtimeRequest: req,
                                              ),
                                        ),
                                      );
                                      if (result == true && context.mounted) {
                                        context.read<OvertimeRequestBloc>().add(
                                          const LoadOvertimeRequests(),
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
        Expanded(
          child: Container(
            height: screenHeight * 0.050,
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
                  // 👈 curved border
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
        SizedBox(width: screenWidth * 0.042), // 4.2% of screen width

        InkWell(
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const ApplyOvertimePage()),
            );
            if (result == true && context.mounted) {
              context.read<OvertimeRequestBloc>().add(
                const LoadOvertimeRequests(),
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

  void _showFilterBottomSheet(BuildContext context) {
    final bloc = context.read<OvertimeRequestBloc>();
    final currentState = bloc.state;
    if (currentState is OvertimeRequestLoaded) {
      _selectedStatusFilter = currentState.statusFilter;
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Status',
                        style: AppTextStyles.heading4(bottomSheetContext),
                      ),
                      const SizedBox(height: 16),
                      ...[
                        (null, 'All'),
                        (OvertimeStatus.pending, 'Pending'),
                        (OvertimeStatus.approved, 'Approved'),
                        (OvertimeStatus.rejected, 'Rejected'),
                        (OvertimeStatus.withdrawn, 'Withdrawn'),
                      ].map(
                        (entry) => RadioListTile<OvertimeStatus?>(
                          value: entry.$1,
                          groupValue: _selectedStatusFilter,
                          onChanged: (value) {
                            setModalState(() => _selectedStatusFilter = value);
                          },
                          title: Text(entry.$2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            bloc.add(
                              FilterOvertimeRequestsByStatus(
                                _selectedStatusFilter,
                              ),
                            );
                          },
                          child: const Text('Apply Filter'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
