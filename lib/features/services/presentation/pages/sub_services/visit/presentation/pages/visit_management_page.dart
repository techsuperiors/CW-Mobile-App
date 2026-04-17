import 'package:collectivWork/core/utils/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../request/presentation/widgets/request_listing/request_empty_state.dart';
import '../../data/datasources/visit_remote_datasource.dart';
import '../../data/repositories/visit_repository_impl.dart';
import '../../domain/models/visit_model.dart';
import '../../domain/usecases/create_visit_usecase.dart';
import '../../domain/usecases/get_visits_usecase.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../widgets/create_visit_activity_sheet.dart';
import '../widgets/create_visit_sheet.dart';
import '../widgets/visit_card.dart';

class VisitManagementPage extends StatefulWidget {
  const VisitManagementPage({super.key});

  static Widget withDependencies({
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  }) {
    final remoteDataSource = VisitRemoteDataSourceImpl(apiClient: apiClient);
    final repository = VisitRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );

    return BlocProvider(
      create:
          (_) => VisitBloc(
            getVisitsUseCase: GetVisitsUseCase(repository),
            getVisitTotalCountUseCase: GetVisitTotalCountUseCase(repository),
            getVisitEmployeesUseCase: GetVisitEmployeesUseCase(repository),
            getVisitCustomersUseCase: GetVisitCustomersUseCase(repository),
            getVisitAddressesUseCase: GetVisitAddressesUseCase(repository),
            createVisitUseCase: CreateVisitUseCase(repository),
            createVisitActivityUseCase: CreateVisitActivityUseCase(repository),
            currentUserId: _resolveUserIdFromToken(),
          )..add(const LoadMyVisits()),
      child: const VisitManagementPage(),
    );
  }

  @override
  State<VisitManagementPage> createState() => _VisitManagementPageState();
}

class _VisitManagementPageState extends State<VisitManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(() {
      if (!mounted) return;
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    final visitBloc = context.read<VisitBloc>();
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      final state = visitBloc.state;
      if (state.teamVisits.isEmpty && !state.isTeamVisitsLoading) {
        visitBloc.add(const LoadTeamVisits());
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openCreateVisitSheet() async {
    final visitBloc = context.read<VisitBloc>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => BlocProvider.value(
            value: visitBloc,
            child: const CreateVisitSheet(),
          ),
    );

    if (result == true && mounted) {
      visitBloc.add(const LoadMyVisits(forceRefresh: true));
      if (_tabController.index == 1) {
        visitBloc.add(const LoadTeamVisits(forceRefresh: true));
      }
    }
  }

  Future<void> _openCreateVisitActivitySheet(VisitModel visit) async {
    final visitBloc = context.read<VisitBloc>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => BlocProvider.value(
            value: visitBloc,
            child: CreateVisitActivitySheet(visit: visit),
          ),
    );

    if (result == true && mounted) {
      visitBloc.add(const LoadMyVisits(forceRefresh: true));
      if (_tabController.index == 1) {
        visitBloc.add(const LoadTeamVisits(forceRefresh: true));
      }
    }
  }

  void _showPendingActionMessage(String actionLabel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$actionLabel will be added shortly.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider.value(
      value: context.read<VisitBloc>(),
      child: ResponsiveScaffold(
        backgroundColor: AppColors.backgroundMedium,
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
            'Visit Management',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: BlocBuilder<VisitBloc, VisitState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildTabs(context, state),
                SizedBox(height: screenHeight * 0.02),
                _buildSearchAndFilterSection(context),
                SizedBox(height: screenHeight * 0.002),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVisitListContent(
                        context,
                        isLoading: state.isMyVisitsLoading,
                        errorMessage: state.myVisitsError,
                        visits: _filterVisits(state.myVisits),
                        onRefresh:
                            () async => context.read<VisitBloc>().add(
                              const LoadMyVisits(forceRefresh: true),
                            ),
                      ),
                      _buildVisitListContent(
                        context,
                        isLoading: state.isTeamVisitsLoading,
                        errorMessage: state.teamVisitsError,
                        visits: _filterVisits(state.teamVisits),
                        onRefresh:
                            () async => context.read<VisitBloc>().add(
                              const LoadTeamVisits(forceRefresh: true),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
            height: screenHeight * 0.050,
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
              style: AppTextStyles.bodyMedium(context),
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

              onChanged: (value) {},
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // 4.2% of screen width

        SizedBox(
          height: screenHeight * 0.050, // 5.0% of screen height

          child: InkWell(
            onTap: () async {
              _openCreateVisitSheet();
            },
            customBorder: const CircleBorder(),
            child: SvgPicture.asset(AppAssets.addIcon),
          ),
        ),
        SizedBox(
          height: screenHeight * 0.050, // 5.0% of screen height

          child: InkWell(
            onTap: () async {},
            customBorder: const CircleBorder(),
            child: SvgPicture.asset(AppAssets.filterIcon),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context, VisitState state) {
    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium(
          context,
        ).copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.bodyMedium(context),
        tabs: [
          Tab(
            text:
                'My Visit ${state.myVisitCount > 0 ? '(${state.myVisitCount})' : ''}',
          ),
          Tab(
            text:
                'Team Visit ${state.teamVisitCount > 0 ? '(${state.teamVisitCount})' : ''}',
          ),
        ],
      ),
    );
  }

  Widget _buildVisitListContent(
    BuildContext context, {
    required bool isLoading,
    required String? errorMessage,
    required List<VisitModel> visits,
    required Future<void> Function() onRefresh,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && visits.isEmpty) {
      return ApiErrorState(
        title: 'Unable to load visits',
        rawMessage: errorMessage,
        onRetry: onRefresh,
      );
    }

    if (visits.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 240, child: RequestEmptyState())],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.sm,
        ),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final visit = visits[index];
          return VisitCard(
            visit: visit,
            onEdit: () => _showPendingActionMessage('Edit'),
            onDelete: () => _showPendingActionMessage('Delete'),
            onAddActivity: () => _openCreateVisitActivitySheet(visit),
          );
        },
      ),
    );
  }

  List<VisitModel> _filterVisits(List<VisitModel> visits) {
    if (_searchQuery.isEmpty) return visits;
    return visits
        .where((visit) {
          final participantNames = visit.participants
              .map((participant) => participant.user.fullName.toLowerCase())
              .join(' ');
          return visit.visitTitle.toLowerCase().contains(_searchQuery) ||
              (visit.description?.toLowerCase().contains(_searchQuery) ??
                  false) ||
              participantNames.contains(_searchQuery) ||
              (visit.type?.label.toLowerCase().contains(_searchQuery) ?? false);
        })
        .toList(growable: false);
  }
}

int _resolveUserIdFromToken() {
  final token = TokenStorage.getToken();
  if (token == null || token.isEmpty) {
    return 0;
  }
  final decoded = decodeData<Map<String, dynamic>>(token);
  final userId = decoded?['user_id'];
  if (userId is int) {
    return userId;
  }
  if (userId is String) {
    return int.tryParse(userId.trim()) ?? 0;
  }
  return 0;
}
