import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../data/tickets_data.dart';
import '../widgets/ticket_summary_card.dart';
import '../widgets/priority_tickets_chart.dart';
import '../widgets/ticket_card.dart';
import '../../domain/models/ticket_model.dart';

/// Tickets page with tabs
class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ResponsiveScaffold(
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
        onTap: (index) {},
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyTicketsTab(context),
          _buildAssignedTicketsTab(context),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final summaries = TicketsData.getTicketSummaries();
    final tickets = TicketsData.getMyTickets();

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
          const PriorityTicketsChart(),
          SizedBox(height: screenHeight * 0.02),
          // Ticket List
          ...tickets.map((ticket) => TicketCard(ticket: ticket)),
        ],
      ),
    );
  }

  Widget _buildAssignedTicketsTab(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final tickets = TicketsData.getAssignedTickets();

    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight * 0.01),
          // Ticket List
          ...tickets.map((ticket) => TicketCard(ticket: ticket)),
        ],
      ),
    );
  }
}

