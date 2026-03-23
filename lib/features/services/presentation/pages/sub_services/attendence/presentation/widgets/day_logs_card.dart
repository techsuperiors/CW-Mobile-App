import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../attendance/domain/entities/attendance_day_detail.dart';

class DayLogsCard extends StatelessWidget {
  final AttendanceDayDetail? dayDetail;

  const DayLogsCard({super.key, this.dayDetail});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final hasLogs =
        _getPunchInLogs().isNotEmpty || _getPunchOutLogs().isNotEmpty;
    final hasAdjustedLogs =
        dayDetail?.punchIn != null || dayDetail?.punchOut != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Day Logs'),
        SizedBox(height: screenHeight * 0.01),
        if (!hasLogs && !hasAdjustedLogs)
          Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.01),
            child: Text(
              'No details available',
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Punch-in
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    _getPunchInLogs().isEmpty
                        ? [_buildLogEntry(context, '--:--:--', true, true)]
                        : _getPunchInLogs()
                            .map(
                              (log) =>
                                  _buildLogEntry(context, log, true, false),
                            )
                            .toList(),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            // Right Column: Punch-out
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    _getPunchOutLogs().isEmpty
                        ? [_buildLogEntry(context, '--:--:--', false, true)]
                        : _getPunchOutLogs()
                            .map(
                              (log) =>
                                  _buildLogEntry(context, log, false, false),
                            )
                            .toList(),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
          ],
        ),
        // Adjusted Logs (if available)
        if (hasAdjustedLogs) SizedBox(height: screenHeight * 0.02),
        if (hasAdjustedLogs) Divider(color: AppColors.border, height: 1),
        if (hasAdjustedLogs) SizedBox(height: screenHeight * 0.02),
        if (hasAdjustedLogs)
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
                          _formatTime(dayDetail?.punchIn) ?? '--:--:--',
                          true,
                          dayDetail?.punchIn == null,
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
                          _formatTime(dayDetail?.punchOut) ?? '--:--:--',
                          false,
                          dayDetail?.punchOut == null,
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
        if (dayDetail != null) ...[
          SizedBox(height: screenHeight * 0.02),
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      _formatDurationSeconds(dayDetail?.actualGrossHrs),
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: screenHeight * 0.015),
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
                              _formatDurationString(dayDetail?.actualBreakTime),
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                      _formatDurationString(dayDetail?.actualEffectiveHrs),
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium(
        context,
      ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  /// Get punch in/out logs from activity array
  List<String> _getPunchInLogs() {
    return dayDetail?.dayLogs
            .map((log) => _formatTime(log.punchIn))
            .whereType<String>()
            .toList() ??
        [];
  }

  List<String> _getPunchOutLogs() {
    return dayDetail?.dayLogs
            .map((log) => _formatTime(log.punchOut))
            .whereType<String>()
            .toList() ??
        [];
  }

  String? _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final localDateTime = DateTime.parse(timeString).toLocal();
      return DateFormat('h:mm:ss a').format(localDateTime);
    } catch (_) {
      return timeString;
    }
  }

  String _formatDurationSeconds(int? seconds) {
    if (seconds == null) return '--';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? '$hours hr $minutes min' : '$minutes min';
  }

  String _formatDurationString(String? secondsString) {
    if (secondsString == null || secondsString.isEmpty) return '--';
    return _formatDurationSeconds(int.tryParse(secondsString));
  }

  Widget _buildLogEntry(
    BuildContext context,
    String time,
    bool isPunchIn,
    bool isDashed,
  ) {
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
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            Text(
              time,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
