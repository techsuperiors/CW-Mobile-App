import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../widgets/ticket_summary_card.dart';
import '../widgets/priority_tickets_chart.dart';
import '../widgets/ticket_card.dart';
import '../../domain/models/ticket_model.dart';
import '../bloc/ticket_bloc.dart';
import '../bloc/ticket_event.dart';
import '../bloc/ticket_state.dart';
import '../utils/ticket_mapper.dart';
import '../../data/datasources/ticket_remote_datasource.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/usecases/get_ticket_list_usecase.dart';
import '../../domain/usecases/get_ticket_stats_usecase.dart';
import '../../domain/usecases/get_ticket_details_usecase.dart';
import '../../domain/usecases/upload_ticket_file_usecase.dart';
import '../../domain/repositories/ticket_repository.dart';

/// Tickets page with tabs
class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TicketBloc _ticketBloc;
  int _currentTabIndex = 0;
  String? _lastLoadedRequestType; // Track which request type was last loaded
  TicketStats? _ticketStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_currentTabIndex != _tabController.index) {
        final previousIndex = _currentTabIndex;
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        // Load tickets when tab changes
        _loadTicketsForCurrentTab();
      }
    });

    // Initialize dependencies
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = TicketRemoteDataSourceImpl(apiClient);
    final repository = TicketRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    final getTicketListUseCase = GetTicketListUseCase(repository);
    final getTicketStatsUseCase = GetTicketStatsUseCase(repository);
    final getTicketDetailsUseCase = GetTicketDetailsUseCase(repository);
    final uploadTicketFileUseCase = UploadTicketFileUseCase(repository);
    _ticketBloc = TicketBloc(
      getTicketListUseCase: getTicketListUseCase,
      getTicketStatsUseCase: getTicketStatsUseCase,
      getTicketDetailsUseCase: getTicketDetailsUseCase,
      uploadTicketFileUseCase: uploadTicketFileUseCase,
    );

    // Load initial tickets and stats for My Ticket tab
    _ticketBloc.add(const LoadTicketData('my_ticket'));
    _lastLoadedRequestType = 'my_ticket';
  }

  void _loadTicketsForCurrentTab() {
    if (_currentTabIndex == 0) {
      // My Ticket tab - load both ticket list and stats
      if (_lastLoadedRequestType != 'my_ticket') {
        _ticketBloc.add(const LoadTicketData('my_ticket'));
        _lastLoadedRequestType = 'my_ticket';
      }
    } else if (_currentTabIndex == 1) {
      // Assigned Ticket tab - only load ticket list, stats remain the same
      if (_lastLoadedRequestType != 'assigned_ticket') {
        _ticketBloc.add(const LoadTicketList('assigned_ticket'));
        _lastLoadedRequestType = 'assigned_ticket';
      }
    }
  }

  void _refreshCurrentTab() {
    if (_currentTabIndex == 0) {
      // Refresh My Ticket tab with both list and stats
      _ticketBloc.add(const LoadTicketData('my_ticket'));
      _lastLoadedRequestType = 'my_ticket';
    } else if (_currentTabIndex == 1) {
      // Refresh Assigned Ticket tab
      _ticketBloc.add(const LoadTicketList('assigned_ticket'));
      _lastLoadedRequestType = 'assigned_ticket';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ticketBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider.value(
      value: _ticketBloc,
      child: ResponsiveScaffold(
      appBar: AppBar(
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
                  AppStrings.services,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w500,
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
          AppStrings.tickets,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.success,
          indicatorWeight: 3,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextStyles.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium(context),
          tabs: const [
            Tab(text: 'My Ticket'),
            Tab(text: 'Assigned Ticket'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyTicketsTab(context),
          _buildAssignedTicketsTab(context),
        ],
      ),
    ));
  }

  /// Convert ticket stats to summary cards
  List<TicketSummary> _statsToSummaries(TicketStats? stats) {
    if (stats == null) {
      // Return empty summaries if stats not loaded yet
      return [
        TicketSummary(
          type: 'Open Tickets',
          count: 0,
          icon: Icons.description,
          color: AppColors.primary,
        ),
        TicketSummary(
          type: 'In-Progress Tickets',
          count: 0,
          icon: Icons.access_time,
          color: AppColors.warning,
        ),
        TicketSummary(
          type: 'Resolved Tickets',
          count: 0,
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
        TicketSummary(
          type: 'Escalated Tickets',
          count: 0,
          icon: Icons.priority_high,
          color: AppColors.error,
        ),
      ];
    }

    return [
      TicketSummary(
        type: 'Open Tickets',
        count: stats.open,
        icon: Icons.description,
        color: AppColors.primary,
      ),
      TicketSummary(
        type: 'In-Progress Tickets',
        count: stats.inProgress,
        icon: Icons.access_time,
        color: AppColors.warning,
      ),
      TicketSummary(
        type: 'Resolved Tickets',
        count: stats.resolved,
        icon: Icons.check_circle,
        color: AppColors.success,
      ),
      TicketSummary(
        type: 'Escalated Tickets',
        count: stats.escalated,
        icon: Icons.priority_high,
        color: AppColors.error,
      ),
    ];
  }

  Widget _buildMyTicketsTab(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocBuilder<TicketBloc, TicketState>(
      bloc: _ticketBloc,
      buildWhen: (previous, current) {
        // Always rebuild when on my_ticket tab (index 0)
        if (_currentTabIndex == 0) {
          // Rebuild for combined state with my_ticket
          if (current is TicketDataLoaded) {
            return current.requestType == 'my_ticket';
          }
          // Rebuild for ticket list with my_ticket
          if (current is TicketLoaded) {
            return current.requestType == 'my_ticket';
          }
          // Rebuild when stats are loaded
          if (current is TicketStatsLoaded) {
            return true;
          }
          // Always rebuild for loading and error states
          if (current is TicketLoading || current is TicketError) {
            return true;
          }
          // If state shows wrong tab data, rebuild to show loader
          if (current is TicketDataLoaded && current.requestType != 'my_ticket') {
            return true;
          }
          if (current is TicketLoaded && current.requestType != 'my_ticket') {
            return true;
          }
          return false;
        }
        // Don't rebuild my_ticket tab when on assigned_ticket tab
        return false;
      },
      builder: (context, state) {
        // Check if state is for wrong tab - if so, show loader
        // The _loadTicketsForCurrentTab() should have already triggered reload
        if (state is TicketDataLoaded && state.requestType != 'my_ticket' && _currentTabIndex == 0) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (state is TicketLoaded && state.requestType != 'my_ticket' && _currentTabIndex == 0) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Show loader while loading
        if (state is TicketLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is TicketError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _ticketBloc.add(const LoadTicketData('my_ticket'));
                    _lastLoadedRequestType = 'my_ticket';
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<TicketModel> tickets = [];
        TicketStats? stats;
        
        // Handle combined state (both ticket list and stats) - preferred state
        if (state is TicketDataLoaded && state.requestType == 'my_ticket') {
          tickets = TicketMapper.toTicketModelList(state.ticketList.tickets);
          _ticketStats = state.stats;
          stats = state.stats;
        } 
        // Handle separate states (for tab switching or partial updates)
        else if (state is TicketLoaded && state.requestType == 'my_ticket') {
          tickets = TicketMapper.toTicketModelList(state.ticketList.tickets);
          stats = _ticketStats; // Use cached stats
        }
        // Handle stats only update
        else if (state is TicketStatsLoaded) {
          _ticketStats = state.stats;
          stats = state.stats;
        } 
        // Initial state or loading - use cached data if available
        else {
          stats = _ticketStats; // Use cached stats
        }

        final summaries = _statsToSummaries(stats);

        return SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              ...summaries.map((summary) => Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.015),
                    child: TicketSummaryCard(summary: summary),
                  )),
              SizedBox(height: screenHeight * 0.02),
              // Priority Tickets Chart
              PriorityTicketsChart(tickets: tickets),
              SizedBox(height: screenHeight * 0.02),
              // Ticket List
              if (tickets.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(screenHeight * 0.05),
                    child: Text(
                      'No tickets found',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...tickets.map((ticket) => TicketCard(
                      ticket: ticket,
                      onRefresh: _refreshCurrentTab,
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignedTicketsTab(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocBuilder<TicketBloc, TicketState>(
      bloc: _ticketBloc,
      buildWhen: (previous, current) {
        // Only rebuild if it's for assigned_ticket
        if (current is TicketDataLoaded) {
          return current.requestType == 'assigned_ticket';
        }
        if (current is TicketLoaded) {
          return current.requestType == 'assigned_ticket';
        }
        return current is TicketLoading || current is TicketError;
      },
      builder: (context, state) {
        // Show loader while loading assigned tickets
        if (state is TicketLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is TicketError && _currentTabIndex == 1) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _ticketBloc.add(const LoadTicketList('assigned_ticket'));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        List<TicketModel> tickets = [];
        
        // Handle combined state (shouldn't happen for assigned, but handle it)
        if (state is TicketDataLoaded && state.requestType == 'assigned_ticket') {
          tickets = TicketMapper.toTicketModelList(state.ticketList.tickets);
        }
        // Handle separate ticket list state
        else if (state is TicketLoaded && state.requestType == 'assigned_ticket') {
          tickets = TicketMapper.toTicketModelList(state.ticketList.tickets);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.01),
              // Ticket List
              if (tickets.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(screenHeight * 0.05),
                    child: Text(
                      'No assigned tickets found',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...tickets.map((ticket) => TicketCard(
                      ticket: ticket,
                      onRefresh: _refreshCurrentTab,
                    )),
            ],
          ),
        );
      },
    );
  }
}

