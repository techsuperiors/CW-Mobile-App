import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/common/shimmer.dart';
import '../../domain/entities/attendance_details.dart';

/// Punch details widget with 2x2 grid layout
class PunchDetails extends StatelessWidget {
  final AttendanceDetails? attendanceDetails;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const PunchDetails({
    super.key,
    this.attendanceDetails,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.042,
      ), // ~4.2% of screen width
      child:
          isLoading
              ? SizedBox(
                // height: screenHeight * 0.15,
                child:  Center(child: _buildPunchGridSkeleton(context)),
              )
              : errorMessage != null
              ? SizedBox(
                height: screenHeight * 0.15,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: AppTextStyles.bodyMediumHeading(
                          context,
                        ).copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onRefresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: screenWidth * 0.027,
                // ~2.7% of screen width
                mainAxisSpacing: screenHeight * 0.015,
                // 1.5% of screen height
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                childAspectRatio: 2.3,
                children: [
                  _buildPunchCard(
                    context,
                    time:
                        (attendanceDetails?.formattedPunchIn == null ||
                                attendanceDetails!.formattedPunchIn.contains(
                                  '-',
                                ))
                            ? 'Not yet'
                            : attendanceDetails!.formattedPunchIn,
                    label: AppStrings.punchIn,
                    icon: AppAssets.iconPunchIn,
                    iconColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    borderColor: AppColors.primary,
                  ),
                  _buildPunchCard(
                    context,

                    time: _getPunchOutDisplay(),
                    label: 'Last Punch Out',
                    icon: AppAssets.iconPunchOut,
                    iconColor: AppColors.success,
                    backgroundColor: AppColors.background,
                    borderColor: AppColors.success,
                  ),
                  _buildPunchCard(
                    context,
                    time: _formatBreakTime(),
                    label: AppStrings.breakTime,
                    icon: AppAssets.iconBreak,
                    iconColor: AppColors.warning,
                    backgroundColor: AppColors.background,
                    borderColor: AppColors.warning,
                  ),
                  _buildPunchCard(
                    context,
                    time: attendanceDetails?.overTime?.total.toString() ?? '-',
                    label: AppStrings.overtime,
                    icon: AppAssets.iconOvertime,
                    iconColor: AppColors.error,
                    backgroundColor: AppColors.background,
                    borderColor: AppColors.error,
                  ),
                ],
              ),
    );
  }

  Widget _buildPunchGridSkeleton(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: MediaQuery.of(context).size.width * 0.027,
        mainAxisSpacing: MediaQuery.of(context).size.height * 0.015,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) => const AppShimmer.custom(
        width: double.infinity,
        height: double.infinity,
        shapeBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  String _formatBreakTime() {
    if (attendanceDetails?.breakTime == null) return '--';
    final breakTimeSeconds =
        int.tryParse(attendanceDetails!.breakTime ?? '0') ?? 0;

    final hours = breakTimeSeconds ~/ 3600;
    final minutes = (breakTimeSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h $minutes min'; // e.g. "1h 30m"
    }
    return '$minutes min'; // e.g. "45m"
  }

  String _getPunchOutDisplay() {
    const String notYet = "Not yet";
    final punchOutStr = attendanceDetails?.punchOut;

    if (punchOutStr == null || punchOutStr.isEmpty || punchOutStr == '-') {
      return notYet;
    }

    return attendanceDetails?.formattedPunchOut ?? notYet;
  }

  Widget _buildPunchCard(
    BuildContext context, {
    required String time,
    required String label,
    required String icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.032), // ~3.2% of screen width
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Icon with optional progress indicator
          SvgPicture.asset(icon, fit: BoxFit.contain),

          SizedBox(width: screenWidth * 0.027), // ~2.7% of screen width
          // Time and label
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.0025),
                // 0.25% of screen height
                Text(
                  label,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
