import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/utils/app_spacing.dart';
import '../../../domain/entities/announcement_entity.dart';

Future<void> showReportedBySheet(BuildContext context, {
  required List<ReportedByEntity> reporters,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReportedBySheet(reporters: reporters),
  );
}

class ReportedBySheet extends StatelessWidget {
  final List<ReportedByEntity> reporters;

  const ReportedBySheet({super.key, required this.reporters});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.xl),
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              AppSpacing.vSm,
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  children: [
                    _ReportedByHeader(count: reporters.length),
                    AppSpacing.vXl,
                    if (reporters.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Text(
                          'No reporting details available right now.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      ...reporters.map(
                            (reporter) =>
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              child: _ReportedByTile(reporter: reporter),
                            ),
                      ),
                    AppSpacing.vMd
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportedByHeader extends StatelessWidget {
  final int count;

  const _ReportedByHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final subtitle =
    count <= 0
        ? 'This post has not been reported yet.'
        : count == 1
        ? 'This post has been reported by 1 employee for following reason'
        : 'This post has been reported by $count employees for following reasons';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.sectionLarge,
          height: AppSpacing.sectionLarge,
          decoration: BoxDecoration(
            color: AppColors.attendanceLightBlueBg,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: const Icon(
            Icons.outlined_flag_rounded,
            color: AppColors.info,
            size: 28,
          ),
        ),
        AppSpacing.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reported By',
                style: AppTextStyles.heading3(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              AppSpacing.vXs,
              Text(
                subtitle,
                style: AppTextStyles.bodyMediumHeading(
                  context,
                ).copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _ReportedByTile extends StatelessWidget {
  final ReportedByEntity reporter;

  const _ReportedByTile({required this.reporter});

  @override
  Widget build(BuildContext context) {
    final name =
    reporter.fullName
        .trim()
        .isEmpty
        ? 'Unknown User'
        : reporter.fullName.trim();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportedByAvatar(
            fullName: name,
            profileColor: reporter.profileColor,
          ),
          AppSpacing.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          if ((reporter.designation ?? '')
                              .trim()
                              .isNotEmpty) ...[
                            AppSpacing.vXxs,
                            Text(
                              reporter.designation!.trim(),
                              style: AppTextStyles.bodySmall(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AppSpacing.hMd,
                    Text(
                      _formatRelativeTime(reporter.reportedAt),
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSm,
                Text(
                  reporter.reason
                      .trim()
                      .isEmpty
                      ? 'No reason provided'
                      : reporter.reason.trim(),
                  style: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(color: AppColors.textPrimary, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(String? rawDate) {
    if (rawDate == null || rawDate
        .trim()
        .isEmpty) {
      return '';
    }

    try {
      final reportedAt = DateTime.parse(rawDate).toLocal();
      final difference = DateTime.now().difference(reportedAt);

      if (difference.inSeconds < 60) {
        return 'Just now';
      }
      if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes minute${minutes == 1 ? '' : 's'} ago';
      }
      if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours hour${hours == 1 ? '' : 's'} ago';
      }
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } catch (_) {
      return '';
    }
  }
}

class _ReportedByAvatar extends StatelessWidget {
  final String fullName;
  final String? profileColor;

  const _ReportedByAvatar({required this.fullName, required this.profileColor});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: _parseColor(profileColor),
      child: Text(
        _initials(fullName),
        style: AppTextStyles.bodyLarge(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _parseColor(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return AppColors.info;
    }

    try {
      return Color(int.parse(value.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.info;
    }
  }
}
