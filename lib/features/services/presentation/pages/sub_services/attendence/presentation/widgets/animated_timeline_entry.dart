import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/app_spacing.dart';

class AnimatedTimelineEntry extends StatelessWidget {
  final TimelineLogEntry entry;
  final int index;
  final int totalCount;
  final AnimationController controller;

  const AnimatedTimelineEntry({
    super.key,
    required this.entry,
    required this.index,
    required this.totalCount,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final location = entry.location?.trim();

    const timelineDotSize = 16.0;
    const timelineLineWidth = 2.0;
    const timelineRailWidth = 20.0;

    final itemStart = (index * 0.16).clamp(0.0, 0.8);
    final lineStart = (itemStart + 0.10).clamp(0.0, 0.92);
    final lineEnd = (lineStart + 0.22).clamp(0.0, 1.0);

    final lineAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(lineStart, lineEnd, curve: Curves.easeOutCubic),
    );
    final dotAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        itemStart,
        (itemStart + 0.18).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: timelineRailWidth,
          child: Column(
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(dotAnimation),
                child: Container(
                  width: timelineDotSize,
                  height: timelineDotSize,
                  decoration: BoxDecoration(
                    color: entry.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (index != totalCount - 1)
                AnimatedBuilder(
                  animation: lineAnimation,
                  builder: (context, child) => Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 56 * lineAnimation.value,
                      child: Container(
                        width: timelineLineWidth,
                        color: entry.color.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(width: screenWidth * 0.025),

        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.02),
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
                  _TimelineInfoRow(
                    icon: Icons.access_time_rounded,
                    iconSize: 14,
                    text: entry.subtitle!,
                    screenWidth: screenWidth,
                    textStyle: AppTextStyles.bodyMediumHeading(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
                if (location != null && location.isNotEmpty) ...[
                  SizedBox(height: screenHeight * 0.006),
                  _TimelineInfoRow(
                    icon: Icons.location_on_outlined,
                    iconSize: 18,
                    text: location,
                    screenWidth: screenWidth,
                    textStyle: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineInfoRow extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String text;
  final double screenWidth;
  final TextStyle textStyle;

  const _TimelineInfoRow({
    required this.icon,
    required this.iconSize,
    required this.text,
    required this.screenWidth,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            text,
            style: textStyle,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

class AnimatedTimeline extends StatelessWidget {
  final List<TimelineLogEntry> entries;
  final AnimationController controller;

  const AnimatedTimeline({
    super.key,
    required this.entries,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(entries.length, (index) {
        return AnimatedTimelineEntry(
          entry: entries[index],
          index: index,
          totalCount: entries.length,
          controller: controller,
        );
      }),
    );
  }
}
class TimelineLogEntry {
  final String title;
  final String? subtitle;
  final String? location;
  final Color color;

  const TimelineLogEntry({
    required this.title,
    this.subtitle,
    this.location,
    required this.color,
  });
}
