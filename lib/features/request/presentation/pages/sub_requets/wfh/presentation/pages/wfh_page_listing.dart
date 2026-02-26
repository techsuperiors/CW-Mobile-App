import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../bloc/wfh_request_bloc.dart';
import '../../bloc/wfh_request_event.dart';
import '../../bloc/wfh_request_state.dart';
import '../../models/wfh_request_model.dart';
import '../widgets/wfh_request_card.dart';
import 'wfh_detail_page.dart';
import 'apply_wfh_page.dart';

/// WFH listing page showing list of WFH requests
class WfhPageListing extends StatefulWidget {
  const WfhPageListing({super.key});

  @override
  State<WfhPageListing> createState() => _WfhPageListingState();
}

class _WfhPageListingState extends State<WfhPageListing> {
  final TextEditingController _searchController = TextEditingController();
  WfhStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    // BlocProvider will load WFH requests automatically in its create method
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (_) => WfhRequestBloc()..add(const LoadWfhRequests()),
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
                  size: screenWidth * 0.048, // 4.8% of screen width
                ),
                Flexible(
                  child: Text(
                    'Back',
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
            AppStrings.wfh,
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
          builder: (blocContext) => Column(
            children: [
              // Search and filter section
              _buildSearchAndFilterSection(blocContext),
              // Divider
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.012, // 1.2% of screen width
                  vertical: screenHeight * 0.01, // 1% of screen height
                ),
                child: CustomPaint(
                  painter: DottedLinePainter(),
                  size: Size(screenWidth * 0.916, 1), // Account for padding
                ),
              ),
              // WFH requests list
              Expanded(
                child: BlocBuilder<WfhRequestBloc, WfhRequestState>(
                  builder: (context, state) {
                    if (state is WfhRequestLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (state is WfhRequestError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: screenWidth * 0.15,
                              color: AppColors.error,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              state.message,
                              style: AppTextStyles.bodyMedium(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is WfhRequestLoaded) {
                      if (state.filteredWfhRequests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: screenWidth * 0.15,
                                color: AppColors.textTertiary,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                AppStrings.noData,
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.012, // 1.2% of screen width
                          vertical: screenHeight * 0.015, // 1.5% of screen height
                        ),
                        itemCount: state.filteredWfhRequests.length,
                        itemBuilder: (context, index) {
                          return WfhRequestCard(
                            wfhRequest: state.filteredWfhRequests[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WfhDetailPage(
                                    wfhRequest: state.filteredWfhRequests[index],
                                  ),
                                ),
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
              // Divider before bottom nav
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.042,
                ),
                child: CustomPaint(
                  painter: DottedLinePainter(),
                  size: Size(screenWidth * 0.916, 1), // Account for padding
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.012, // 1.2% of screen width
        vertical: screenHeight * 0.015, // 1.5% of screen height
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: screenHeight * 0.055, // 5.5% of screen height
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppStrings.search,
                  hintStyle: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.032),
                    child: Icon(
                      Icons.search,
                      size: screenWidth * 0.048, // 4.8% of screen width
                      color: AppColors.textSecondary,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.032, // 3.2% of screen width
                    vertical: screenHeight * 0.012, // 1.2% of screen height
                  ),
                ),
                style: AppTextStyles.bodyMedium(context),
                onChanged: (value) {
                  context.read<WfhRequestBloc>().add(SearchWfhRequests(value));
                },
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.021), // 2.1% of screen width
          // Filter icon button (square with rounded corners)
          Container(
            width: screenHeight * 0.055, // 5.5% of screen height
            height: screenHeight * 0.055,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showFilterBottomSheet(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Icon(
                    Icons.filter_alt, // Funnel/filter icon
                    size: screenWidth * 0.048, // 4.8% of screen width
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.021), // 2.1% of screen width
          // Add button (green circular button with plus) - opens form page
          Container(
            width: screenHeight * 0.055, // 5.5% of screen height
            height: screenHeight * 0.055,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApplyWfhPage(),
                    ),
                  );
                },
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: screenWidth * 0.053, // 5.3% of screen width
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Get current filter state from bloc using the context that has BlocProvider
    final bloc = context.read<WfhRequestBloc>();
    final currentState = bloc.state;
    WfhStatus? currentFilter;
    if (currentState is WfhRequestLoaded) {
      currentFilter = currentState.statusFilter;
      // Sync local state with bloc state
      _selectedStatusFilter = currentFilter;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (bottomSheetContext, setModalState) => Container(
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
                WfhStatus.pending,
                _selectedStatusFilter == WfhStatus.pending,
                () {
                  setModalState(() {
                    _selectedStatusFilter = WfhStatus.pending;
                  });
                },
              ),
              _buildFilterOption(
                bottomSheetContext,
                'Approved',
                WfhStatus.approved,
                _selectedStatusFilter == WfhStatus.approved,
                () {
                  setModalState(() {
                    _selectedStatusFilter = WfhStatus.approved;
                  });
                },
              ),
              _buildFilterOption(
                bottomSheetContext,
                'Rejected',
                WfhStatus.rejected,
                _selectedStatusFilter == WfhStatus.rejected,
                () {
                  setModalState(() {
                    _selectedStatusFilter = WfhStatus.rejected;
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
                    bloc.add(FilterWfhRequestsByStatus(_selectedStatusFilter));
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
                    style: AppTextStyles.buttonMedium(bottomSheetContext),
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
    WfhStatus? status,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.015,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
