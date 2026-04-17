import 'package:collectivWork/core/widgets/api_error_state.dart';
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

class DayDetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onDateChanged;
  final AttendanceDetails? attendanceDetails;
  final AttendanceDayDetail? selectedDayDetail;
  final bool isLoading;
  final String? errorMessage;
  final List<CalendarDayEntity> calendarDays;

  const DayDetailsCard({
    super.key,
    required this.selectedDate,
    this.onDateChanged,
    this.attendanceDetails,
    this.selectedDayDetail,
    required this.isLoading,
    this.errorMessage,
    this.calendarDays = const [],
  });

  CalendarDayEntity? _getSelectedCalendarDay() {
    final selectedDateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    for (final day in calendarDays) {
      if (day.date == selectedDateKey) {
        return day;
      }
    }
    return null;
  }

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

  String _valueOrDash(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return '--';
    }
    return trimmed;
  }

  String _formatSecondsValue(int? rawSeconds) {
    if (rawSeconds == null || rawSeconds <= 0) return '--';

    final hours = rawSeconds ~/ 3600;
    final minutes = (rawSeconds % 3600) ~/ 60;
    final seconds = rawSeconds % 60;

    final parts = <String>[];
    if (hours > 0) parts.add('$hours hr');
    if (minutes > 0) parts.add('$minutes min');
    if (seconds > 0 && parts.isEmpty) parts.add('$seconds sec');
    return parts.isEmpty ? '--' : parts.join(' ');
  }

  String _formatDateTimeValue(String? rawValue) {
    final trimmed = rawValue?.trim();
    if (trimmed == null || trimmed.isEmpty) return '--';

    DateTime? parsed;
    try {
      parsed = DateTime.tryParse(trimmed);
    } catch (_) {
      parsed = null;
    }

    if (parsed == null && trimmed.contains(' ')) {
      final normalized = trimmed.replaceFirst(' ', 'T');
      try {
        parsed = DateTime.tryParse(normalized);
      } catch (_) {
        parsed = null;
      }
    }

    if (parsed == null) {
      return trimmed;
    }

    return DateFormat('hh:mm a').format(parsed.toLocal());
  }

  String _formatHourValue(String? rawValue) {
    final trimmed = rawValue?.trim();
    if (trimmed == null || trimmed.isEmpty) return '--';

    final numericValue = num.tryParse(trimmed);
    if (numericValue == null) {
      return trimmed;
    }

    if (numericValue == 0) {
      return '0 min';
    }

    final isLikelySeconds = numericValue >= 60;
    if (!isLikelySeconds) {
      return '$trimmed hr';
    }

    final totalSeconds = numericValue.toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    final parts = <String>[];
    if (hours > 0) parts.add('$hours hr');
    if (minutes > 0) parts.add('$minutes min');
    return parts.isEmpty ? '0 min' : parts.join(' ');
  }

  String _getShiftTiming(CalendarDayEntity? selectedCalendarDay) {
    if (selectedCalendarDay != null &&
        (selectedCalendarDay.shiftPunchIn?.isNotEmpty ?? false) &&
        (selectedCalendarDay.shiftPunchOut?.isNotEmpty ?? false)) {
      return '${selectedCalendarDay.shiftPunchIn} - ${selectedCalendarDay.shiftPunchOut}';
    }

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

  List<_DetailRowData> _buildRows(CalendarDayEntity? selectedCalendarDay) {
    return [
      _DetailRowData(
        label: 'Day',
        value: DateFormat('EEEE').format(selectedDate),
      ),
      _DetailRowData(
        label: 'Punch In mode',
        value: _valueOrDash(selectedCalendarDay?.punchInMode),
      ),
      _DetailRowData(
        label: 'Punch In time',
        value: _formatDateTimeValue(selectedCalendarDay?.punchIn),
      ),
      _DetailRowData(
        label: 'Punch Out mode',
        value: _valueOrDash(selectedCalendarDay?.punchOutMode),
      ),
      _DetailRowData(
        label: 'Punch Out time',
        value: _formatDateTimeValue(selectedCalendarDay?.punchOut),
      ),
      _DetailRowData(
        label: 'Gross hours',
        value: _formatHourValue(selectedCalendarDay?.actualGrossHours),
      ),
      _DetailRowData(
        label: 'Effective hours',
        value: _formatHourValue(selectedCalendarDay?.actualEffectiveHours),
      ),
      _DetailRowData(
        label: 'Break hours',
        value: _formatHourValue(selectedCalendarDay?.actualBreakHours),
      ),
      const _DetailRowData.action(label: 'Action'),
      _DetailRowData(
        label: 'Shift timings',
        value: _getShiftTiming(selectedCalendarDay),
      ),
      _DetailRowData(
        label: 'Overtime hours',
        value: _formatHourValue(selectedCalendarDay?.overtimeHours),
      ),
      _DetailRowData(
        label: 'Late by',
        value: _formatSecondsValue(selectedCalendarDay?.lateBySeconds),
      ),
      _DetailRowData(
        label: 'Early by',
        value: _formatSecondsValue(selectedCalendarDay?.earlyBySeconds),
      ),
      _DetailRowData(
        label: 'Leave Type',
        value: _valueOrDash(selectedCalendarDay?.leaveType),
      ),
      _DetailRowData(
        label: 'Attendance status',
        value: _valueOrDash(selectedCalendarDay?.status),
      ),
    ];
  }

  void _changeSelectedDate(int dayOffset) {
    final nextDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day + dayOffset,
    );
    onDateChanged?.call(nextDate);
  }

  void _changeSelectedMonth(int monthOffset) {
    final targetYear = selectedDate.year;
    final targetMonth = selectedDate.month + monthOffset;
    final maxDayInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final safeDay =
        selectedDate.day > maxDayInTargetMonth
            ? maxDayInTargetMonth
            : selectedDate.day;

    final nextDate = DateTime(targetYear, targetMonth, safeDay);
    onDateChanged?.call(nextDate);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final selectedCalendarDay = _getSelectedCalendarDay();
    final detailRows = _buildRows(selectedCalendarDay);

    if (isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.020),
        padding: EdgeInsets.all(screenWidth * 0.042),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return ApiErrorState(rawMessage: errorMessage, onRetry: () {
        onDateChanged?.call(selectedDate);
      });
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.042),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.0020),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _changeSelectedMonth(-1),
                    child: Icon(
                      Icons.keyboard_double_arrow_left,
                      size: screenWidth * 0.073,
                      color: AppColors.calendararrow,
                    ),
                  ),

                  GestureDetector(
                    onTap: () => _changeSelectedDate(-1),
                    child: Icon(
                      Icons.chevron_left,
                      size: screenWidth * 0.073,
                      color: AppColors.calendararrow,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Text(
                  DateFormat('dd MMM yyyy').format(selectedDate),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading4(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _changeSelectedDate(1),
                    child: Icon(
                      Icons.chevron_right,
                      size: screenWidth * 0.073,
                      color: AppColors.calendararrow,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _changeSelectedMonth(1),
                    child: Icon(
                      Icons.keyboard_double_arrow_right,
                      size: screenWidth * 0.073,
                      color: AppColors.calendararrow,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.03),
          ...detailRows.map((row) {
            final isActionRow = row.isAction;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.33,
                      child: Text(
                        row.label,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          isActionRow
                              ? _buildActionOptions(context)
                              : Text(
                                row.value,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.bodySmall(
                                  context,
                                ).copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                    ),
                  ],
                ),
                Divider(height: screenHeight * 0.03, color: AppColors.border),
              ],
            );
          }),
          SizedBox(height: screenHeight * 0.002),
          ...detailRows.map((row) {
            final isDayRow = row.label == 'Day';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDayRow) ...[
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                    padding: EdgeInsets.all(screenWidth * 0.035),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                    ),
                    child: DayLogsCard(dayDetail: selectedDayDetail),
                  ),
                ],
              ],
            );
          }),
          SizedBox(height: screenHeight * 0.015),
        ],
      ),
    );
  }

  Widget _buildActionOptions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: screenWidth * 0.02,
        runSpacing: screenHeight * 0.004,
        children: [
          PermissionGuard(
            requiredPermission: "Attendance:Regularize:Write",
            child: _buildActionButton(
              context: context,
              icon: Icons.edit,
              label: AppStrings.regularize,
              onTap: () {
                final reason = _getRegularizeBlockReason(selectedDate);
                if (reason != null) {
                  _showBlockedDialog(context, reason);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            ApplyRegularizePage(selectedDate: selectedDate),
                  ),
                );
              },
            ),
          ),
          PermissionGuard(
            anyOf: ["Leave Management:My Leaves:Write"],
            child: _buildActionButton(
              context: context,
              icon: Icons.calendar_today,
              label: AppStrings.applyLeave,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApplyLeavePage(),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: screenWidth * 0.03, color: AppColors.primary),
      label: Text(
        label,
        style: AppTextStyles.buttonSmall(
          context,
        ).copyWith(color: AppColors.primary),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _DetailRowData {
  final String label;
  final String value;
  final bool isAction;

  const _DetailRowData({required this.label, required this.value})
    : isAction = false;

  const _DetailRowData.action({required this.label})
    : value = '',
      isAction = true;
}
