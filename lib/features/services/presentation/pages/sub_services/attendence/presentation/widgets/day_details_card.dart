import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../attendance/domain/entities/attendance_details.dart';
import '../../../../../../../request/presentation/pages/sub_requets/leaves/presentation/pages/apply_leave_page.dart';
import '../../../../../../../request/presentation/pages/sub_requets/regularize/presentation/pages/apply_regularize_page.dart';

/// Day details card showing shift timings, logs, and actions
class DayDetailsCard extends StatelessWidget {
  final DateTime selectedDate;
  final AttendanceDetails? attendanceDetails;
  final bool isLoading;
  final String? errorMessage;

  const DayDetailsCard({
    super.key,
    required this.selectedDate,
    this.attendanceDetails,
    required this.isLoading,
    this.errorMessage,
  });

  /// Format time from API response
  String? _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final utcDateTime = DateTime.parse(timeString);
      final localDateTime = utcDateTime.toLocal();
      final hour = localDateTime.hour;
      final minute = localDateTime.minute;
      final second = localDateTime.second;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      final displaySecond = second.toString().padLeft(2, '0');
      return '$displayHour:$displayMinute:$displaySecond $period';
    } catch (e) {
      return timeString;
    }
  }

  /// Get punch in/out logs from activity array
  List<String> _getPunchInLogs() {
    if (attendanceDetails?.activity == null) return [];
    final logs = <String>[];
    for (var activity in attendanceDetails!.activity!) {
      if (activity.activityType == 'Punch In' && activity.time != null) {
        final formatted = _formatTime(activity.time);
        if (formatted != null) logs.add(formatted);
      }
    }
    return logs;
  }

  List<String> _getPunchOutLogs() {
    if (attendanceDetails?.activity == null) return [];
    final logs = <String>[];
    for (var activity in attendanceDetails!.activity!) {
      if (activity.activityType == 'Punch Out' && activity.time != null) {
        final formatted = _formatTime(activity.time);
        if (formatted != null) logs.add(formatted);
      }
    }
    return logs;
  }

  /// Get shift timing for selected date
  String _getShiftTiming() {
    if (attendanceDetails?.shift?.shiftDayTiming == null) {
      return '09:30 AM - 07:30 PM'; // Default
    }
    
    final dayName = DateFormat('EEEE').format(selectedDate);
    final dayTiming = attendanceDetails!.shift!.shiftDayTiming.firstWhere(
      (timing) => timing.day == dayName,
      orElse: () => attendanceDetails!.shift!.shiftDayTiming.first,
    );
    
    return '${dayTiming.punchIn} - ${dayTiming.punchOut}';
  }

  /// Format break time
  String _formatBreakTime() {
    if (attendanceDetails?.breakTime == null) return '--';
    final breakTimeSeconds = int.tryParse(attendanceDetails!.breakTime ?? '0') ?? 0;
    final minutes = breakTimeSeconds ~/ 60;
    return '$minutes min';
  }

  /// Format hours
  String _formatHours(double? hours) {
    if (hours == null) return '--';
    final hrs = hours.toInt();
    final mins = ((hours - hrs) * 60).toInt();
    if (mins == 0) {
      return '$hrs hr';
    }
    return '$hrs hr $mins min';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
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
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.error,
            ),
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
            color: Colors.black.withOpacity(0.05),
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
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (attendanceDetails?.punchType == 'remote' || 
                  attendanceDetails?.wfhShowPunch == true)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AppStrings.wfh,
                    style: AppTextStyles.labelSmall(context).copyWith(
                      color: AppColors.success,
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
                    attendanceDetails?.shift?.shiftDayTiming.isNotEmpty == true
                        ? attendanceDetails!.shift!.shiftDayTiming.first.grossHours
                        : '--',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
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
                    attendanceDetails?.shift?.shiftDayTiming.isNotEmpty == true
                        ? attendanceDetails!.shift!.shiftDayTiming.first.effectiveHours
                        : '--',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
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
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApplyRegularizePage(selectedDate: selectedDate),
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
                    style: AppTextStyles.buttonSmall(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
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
                    style: AppTextStyles.buttonSmall(context).copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                    alignment: Alignment.centerLeft,
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
          _buildSectionTitle(context, 'Day Logs'),
          SizedBox(height: screenHeight * 0.01),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Punch-in
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getPunchInLogs().isEmpty
                      ? [_buildLogEntry(context, '--:--:--', true, true)]
                      : _getPunchInLogs()
                          .map((log) => _buildLogEntry(context, log, true, false))
                          .toList(),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              // Right Column: Punch-out
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getPunchOutLogs().isEmpty
                      ? [_buildLogEntry(context, '--:--:--', false, true)]
                      : _getPunchOutLogs()
                          .map((log) => _buildLogEntry(context, log, false, false))
                          .toList(),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
            ],
          ),
          // Adjusted Logs (if available)
          if (attendanceDetails?.punchIn != null || attendanceDetails?.punchOut != null)
            SizedBox(height: screenHeight * 0.02),
          if (attendanceDetails?.punchIn != null || attendanceDetails?.punchOut != null)
            Divider(color: AppColors.border, height: 1),
          if (attendanceDetails?.punchIn != null || attendanceDetails?.punchOut != null)
            SizedBox(height: screenHeight * 0.02),
          if (attendanceDetails?.punchIn != null || attendanceDetails?.punchOut != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Adjusted Logs'),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Adjusted Punch-in
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLogEntry(
                            context,
                            attendanceDetails?.formattedPunchIn ?? '--:--:--',
                            true,
                            attendanceDetails?.punchIn == null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    // Right Column: Adjusted Punch-out
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLogEntry(
                            context,
                            attendanceDetails?.formattedPunchOut ?? '--:--:--',
                            false,
                            attendanceDetails?.punchOut == null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Divider(color: AppColors.border, height: 1),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          SizedBox(height: screenHeight * 0.02),
          // Divider
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          // Actual Hours and Break Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Actual Gross hour and Break Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actual Gross hour',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      _formatHours(attendanceDetails?.grossHours),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    // Break Time with icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'T',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Break Time',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              _formatBreakTime(),
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Right Column: Actual Effective hour
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Actual Effective hour',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      _formatHours(attendanceDetails?.effectiveHours),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium(context).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, String time, bool isPunchIn, bool isDashed) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.008),
      child: Row(
        children: [
          // Checkmark for punch-in, upward arrow for punch-out
          if (isPunchIn)
            Text(
              '✓',
              style: TextStyle(
                fontSize: AppTextStyles.bodySmall(context).fontSize,
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '↗',
              style: TextStyle(
                fontSize: AppTextStyles.bodySmall(context).fontSize,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          SizedBox(width: screenWidth * 0.02),
          if (isDashed)
            Expanded(
              child: Text(
                time,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Text(
              time,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for dashed lines
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
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

