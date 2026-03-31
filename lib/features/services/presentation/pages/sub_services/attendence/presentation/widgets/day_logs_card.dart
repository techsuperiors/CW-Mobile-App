import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../attendance/domain/entities/attendance_day_detail.dart';

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
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          child:
              _isExpanded && hasLogs
                  ? Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.014),
                    child: Column(
                      children: List.generate(timelineEntries.length, (index)
                      {
                        final entry = timelineEntries[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index == timelineEntries.length - 1
                                    ? 0
                                    : screenHeight * 0.026,
                          ),
                          child: _AnimatedTimelineEntry(
                            entry: entry,
                            index: index,
                            totalCount: timelineEntries.length,
                            controller: _controller,
                          ),
                        );
                      }),
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  List<_TimelineLogEntry> _buildTimelineEntries() {
    final logs = widget.dayDetail?.dayLogs ?? const <AttendanceDayLog>[];
    if (logs.isEmpty) return [];

    return logs.expand(_mapDayLogToTimelineEntries).toList();
  }

  List<_TimelineLogEntry> _mapDayLogToTimelineEntries(AttendanceDayLog log) {
    final rawType =
        (log.activityType ?? log.activityAction ?? '').trim().toLowerCase();
    final isPunchIn = rawType.contains('punch in');
    final isPunchOut = rawType.contains('punch out');

    if (isPunchIn || isPunchOut) {
      final actor = _toTitleCase(log.activityBy ?? '');
      final actionText = isPunchIn ? 'Punched In At' : 'Punched Out At';
      final title = actor.isEmpty ? actionText : '$actor $actionText';

      return [
        _TimelineLogEntry(
          title: title,
          subtitle: _formatTimelineTime(log.time),
          location: log.location,
          color: isPunchIn ? AppColors.success : AppColors.error,
        ),
      ];
    }

    final fallbackEntries = <_TimelineLogEntry>[];
    if (log.punchIn != null && log.punchIn!.trim().isNotEmpty) {
      fallbackEntries.add(
        _TimelineLogEntry(
          title: 'Punched In At',
          subtitle: _formatTimelineTime(log.punchIn),
          color: AppColors.success,
        ),
      );
    }
    if (log.punchOut != null && log.punchOut!.trim().isNotEmpty) {
      fallbackEntries.add(
        _TimelineLogEntry(
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

class _AnimatedTimelineEntry extends StatelessWidget {
  final _TimelineLogEntry entry;
  final int index;
  final int totalCount;
  final AnimationController controller;

  const _AnimatedTimelineEntry({
    required this.entry,
    required this.index,
    required this.totalCount,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const timelineDotSize = 16.0;
    const timelineLineWidth = 2.0;
    const timelineRailWidth = 20.0;
    final itemStart = (index * 0.16).clamp(0.0, 0.8);
    final itemEnd = (itemStart + 0.30).clamp(0.0, 1.0);
    final lineStart = (itemStart + 0.10).clamp(0.0, 0.92);
    final lineEnd = (lineStart + 0.22).clamp(0.0, 1.0);

    final fadeAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(itemStart, itemEnd, curve: Curves.easeOutCubic),
    );
    final lineAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(lineStart, lineEnd, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(fadeAnimation),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timelineRailWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1).animate(
                          CurvedAnimation(
                            parent: controller,
                            curve: Interval(
                              itemStart,
                              (itemStart + 0.18).clamp(0.0, 1.0),
                              curve: Curves.easeOutBack,
                            ),
                          ),
                        ),
                        child: Container(
                          width: timelineDotSize,
                          height: timelineDotSize,
                          decoration: BoxDecoration(
                            color: entry.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    if (index != totalCount - 1)
                      Expanded(
                        child: SizedBox(
                          width: timelineDotSize,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizeTransition(
                              sizeFactor: lineAnimation,
                              axis: Axis.vertical,
                              axisAlignment: -1,
                              child: Container(
                                width: timelineLineWidth,
                                color: entry.color.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: AppTextStyles.bodyMediumHeading(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.subtitle != null) ...[
                      SizedBox(height: screenHeight * 0.008),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: Text(
                              entry.subtitle!,
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (entry.location != null &&
                        entry.location!.trim().isNotEmpty) ...[
                      SizedBox(height: screenHeight * 0.006),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: Text(
                              entry.location!,
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineLogEntry {
  final String title;
  final String? subtitle;
  final String? location;
  final Color color;

  const _TimelineLogEntry({
    required this.title,
    this.subtitle,
    this.location,
    required this.color,
  });
}
