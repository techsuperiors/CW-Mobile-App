import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../attendance/domain/entities/attendance_day_detail.dart';
import 'animated_timeline_entry.dart';

class DayLogsCard extends StatefulWidget {
  final AttendanceDayDetail? dayDetail;

  const DayLogsCard({super.key, this.dayDetail});

  @override
  State<DayLogsCard> createState() => _DayLogsCardState();
}

class _DayLogsCardState extends State<DayLogsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    final shouldExpand = !_isExpanded;
    setState(() {
      _isExpanded = shouldExpand;
    });

    if (shouldExpand) {
      _controller.forward(from: 0);
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final timelineEntries = _buildTimelineEntries();
    final hasLogs = timelineEntries.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       GestureDetector(
         behavior: HitTestBehavior.opaque,
          onTap: hasLogs ? _toggleExpanded : null,
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.004),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day Logs',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.004),
                        Text(
                          hasLogs
                              ? (_isExpanded
                                  ? 'Tap to collapse'
                                  : 'Tap to expand ${timelineEntries.length} log items')
                              : 'No details available',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasLogs)
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 28,
                        color: AppColors.calendararrow,
                      ),
                    ),
                ],
              ),
            ),

        ),
        if (_isExpanded && hasLogs)
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.014),
            child: Column(
              children: List.generate(timelineEntries.length, (index) {
                final entry = timelineEntries[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        index == timelineEntries.length - 1
                            ? 0
                            : screenHeight * 0.026,
                  ),
                  child: AnimatedTimelineEntry(
                    entry: entry,
                    index: index,
                    totalCount: timelineEntries.length,
                    controller: _controller,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  List<TimelineLogEntry> _buildTimelineEntries() {
    final logs = widget.dayDetail?.dayLogs ?? const <AttendanceDayLog>[];
    if (logs.isEmpty) return [];

    return logs.expand(_mapDayLogToTimelineEntries).toList();
  }

  List<TimelineLogEntry> _mapDayLogToTimelineEntries(AttendanceDayLog log) {
    final rawType =
        (log.activityType ?? log.activityAction ?? '').trim().toLowerCase();
    final isPunchIn = rawType.contains('punch in');
    final isPunchOut = rawType.contains('punch out');

    if (isPunchIn || isPunchOut) {
      final actor = _toTitleCase(log.activityBy ?? '');
      final actionText = isPunchIn ? 'Punched In At' : 'Punched Out At';
      final title = actor.isEmpty ? actionText : '$actor $actionText';

      return [
        TimelineLogEntry(
          title: title,
          subtitle: _formatTimelineTime(log.time),
          location: log.location,
          color: isPunchIn ? AppColors.success : AppColors.error,
        ),
      ];
    }

    final fallbackEntries = <TimelineLogEntry>[];
    if (log.punchIn != null && log.punchIn!.trim().isNotEmpty) {
      fallbackEntries.add(
        TimelineLogEntry(
          title: 'Punched In At',
          subtitle: _formatTimelineTime(log.punchIn),
          color: AppColors.success,
        ),
      );
    }
    if (log.punchOut != null && log.punchOut!.trim().isNotEmpty) {
      fallbackEntries.add(
        TimelineLogEntry(
          title: 'Punched Out At',
          subtitle: _formatTimelineTime(log.punchOut),
          color: AppColors.error,
        ),
      );
    }
    return fallbackEntries;
  }

  String _toTitleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String? _formatTimelineTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final localDateTime = DateTime.parse(timeString).toLocal();
      return DateFormat('hh:mm a dd MMM yyyy').format(localDateTime);
    } catch (_) {
      return timeString;
    }
  }
}
