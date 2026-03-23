import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/attendence/presentation/widgets/day_logs_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../attendance/domain/entities/attendance_day_detail.dart';
import '../../../../../../../attendance/domain/entities/attendance_details.dart';
import '../../../../../../../calendar/domain/entities/calendar_day_entity.dart';
import '../../../../../../../request/presentation/pages/sub_requets/leaves/presentation/pages/apply_leave_page.dart';
import '../../../../../../../request/presentation/pages/sub_requets/regularize/presentation/pages/apply_regularize_page.dart';

/// Day details card showing shift timings, logs, and actions
class DayDetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final AttendanceDetails? attendanceDetails;
  final AttendanceDayDetail? selectedDayDetail;
  final bool isLoading;
  final String? errorMessage;
  final List<CalendarDayEntity> calendarDays; // ADD THIS

  const DayDetailsCard({
    super.key,
    required this.selectedDate,
    this.attendanceDetails,
    this.selectedDayDetail,
    required this.isLoading,
    this.errorMessage,
    this.calendarDays = const [], // ADD THIS
  });

  /// Get shift timing for selected date
  String _getShiftTiming() {
    final shiftTiming = selectedDayDetail?.shiftTiming;
    if (shiftTiming != null &&
        shiftTiming.punchIn.isNotEmpty &&
        shiftTiming.punchOut.isNotEmpty) {
      return '${shiftTiming.punchIn} - ${shiftTiming.punchOut}';
    }

    if (attendanceDetails?.shift?.shiftDayTiming == null) {
      return '--';
    }
    final dayName = DateFormat('EEEE').format(selectedDate);
    final dayTiming = attendanceDetails!.shift!.shiftDayTiming.firstWhere(
      (timing) => timing.day == dayName,
      orElse: () => attendanceDetails!.shift!.shiftDayTiming.first,
    );

    return '${dayTiming.punchIn} - ${dayTiming.punchOut}';
  }

  /// Returns a block reason string, or null if regularization is allowed.
  String? _getRegularizeBlockReason(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final isBlocked = calendarDays.any(
      (d) => d.date.startsWith(dateStr) && (d.status == 'Leave' || d.isHoliday),
    );
    if (isBlocked) {
      return 'Regularization is not allowed on leave or holiday dates.';
    }
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly.isAfter(todayOnly)) {
      return 'Regularization is not allowed for future dates.';
    }
    return null;
  }

  void _showBlockedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cannot Regularize'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _getExpectedGrossHours() {
    final shiftTiming = selectedDayDetail?.shiftTiming;
    if (shiftTiming != null && shiftTiming.grossHours.isNotEmpty) {
      return shiftTiming.grossHours;
    }
    return '--';
  }

  String _getExpectedEffectiveHours() {
    final shiftTiming = selectedDayDetail?.shiftTiming;
    if (shiftTiming != null && shiftTiming.effectiveHours.isNotEmpty) {
      return shiftTiming.effectiveHours;
    }
    return '--';
  }

  _StatusChipData? _getStatusChipData() {
    final detail = selectedDayDetail;
    if (detail == null) return null;

    final status = (detail.status ?? '').trim();
    if (detail.holiday || status.toLowerCase() == 'holiday') {
      return _StatusChipData(
        label: 'Holiday',
        backgroundColor: AppColors.error.withValues(alpha: 0.15),
        textColor: AppColors.error,
      );
    }

    switch (status.toLowerCase()) {
      case 'present':
        return _StatusChipData(
          label: 'Present',
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          textColor: AppColors.success,
        );
      case 'leave':
        return _StatusChipData(
          label: 'Leave',
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          textColor: AppColors.warning,
        );
      case 'wfh':
        return _StatusChipData(
          label: AppStrings.wfh,
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          textColor: AppColors.success,
        );
      case 'absent':
        return _StatusChipData(
          label: 'Absent',
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          textColor: AppColors.error,
        );
      case 'holiday':
        return _StatusChipData(
          label: 'Holiday',
          backgroundColor: AppColors.error.withValues(alpha: 0.15),
          textColor: AppColors.error,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusChip = _getStatusChipData();

    final formattedDate = DateFormat('d MMMM yyyy').format(selectedDate);

    if (isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.020),
        padding: EdgeInsets.all(screenWidth * 0.042),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.020),
        padding: EdgeInsets.all(screenWidth * 0.042),
        child: Center(
          child: Text(
            errorMessage!,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.error),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.020),
      padding: EdgeInsets.all(screenWidth * 0.042),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date title
          Text(
            formattedDate,
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // TSC Shift Timings
          Text(
            'TSC Shift Timings',
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getShiftTiming(),
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
              if (statusChip != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: statusChip.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusChip.label,
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: statusChip.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // Expected Hours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expected Gross hours',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    _getExpectedGrossHours(),
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expected Effective hours',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    _getExpectedEffectiveHours(),
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PermissionGuard(
                requiredPermission: "Attendance:Regularize:Write",
                child: Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      final reason = _getRegularizeBlockReason(selectedDate);
                      if (reason != null) {
                        _showBlockedDialog(context, reason);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ApplyRegularizePage(
                                selectedDate: selectedDate,
                              ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.edit,
                      size: screenWidth * 0.03,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      AppStrings.regularize,
                      style: AppTextStyles.buttonSmall(
                        context,
                      ).copyWith(color: AppColors.primary),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.012,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              PermissionGuard(
                anyOf: ["Leave Management:My Leaves:Write"],
                child: Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ApplyLeavePage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.calendar_today,
                      size: screenWidth * 0.03,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      AppStrings.applyLeave,
                      style: AppTextStyles.buttonSmall(
                        context,
                      ).copyWith(color: AppColors.primary),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.012,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.025),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),

          // Day Logs
          DayLogsCard(dayDetail: selectedDayDetail),
        ],
      ),
    );
  }
}

class _StatusChipData {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusChipData({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.border
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
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
