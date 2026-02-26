import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../widgets/leave_type_card.dart';

/// Leave Request page showing different leave types with statistics
class LeaveRequestPage extends StatelessWidget {
  const LeaveRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                size: MediaQuery.of(context).size.width * 0.048, // ~4.8% of screen width
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
          AppStrings.leaveRequest,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: (index) {
          // Handle navigation if needed
          // For now, just keep Services active
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.01,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loss of Pay (LOP) Card
            LeaveTypeCard(
              title: 'Loss of Pay (LOP)',
              totalLeaves: 6,
              consumed: 2,
              allocatedQuota: 10,
              annualQuota: 10,
              color: const Color(0xFF1976D2), // Dark blue for LOP
              isLOP: true,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Emergency Leave (EL) Card
            LeaveTypeCard(
              title: 'Emergency Leave (EL)',
              totalLeaves: 6,
              consumed: 2,
              allocatedQuota: 10,
              annualQuota: 10,
              color: AppColors.attendanceTeal,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Casual Leave (CL) Card
            LeaveTypeCard(
              title: 'Casual Leave (CL)',
              totalLeaves: 6,
              consumed: 2,
              allocatedQuota: 10,
              annualQuota: 10,
              color: AppColors.leavePaternity,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Sick Leave (SL) Card
            LeaveTypeCard(
              title: 'Sick Leave (SL)',
              totalLeaves: 6,
              consumed: 2,
              allocatedQuota: 10,
              annualQuota: 10,
              color: AppColors.leavePaidHoliday,
            ),
          ],
        ),
      ),
    );
  }
}

