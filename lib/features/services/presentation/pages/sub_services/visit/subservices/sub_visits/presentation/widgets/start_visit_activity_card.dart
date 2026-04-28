import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../domain/models/visit_model.dart';
import 'activity_chip.dart';

class StartedVisitActivityCard extends StatelessWidget {
  final VisitActivityModel activity;
  final VisitActivityDetailModel activityDetail;
  final DateTime? scheduledDate;
  final VoidCallback? onViewDetails;

  const StartedVisitActivityCard({
    super.key,
    required this.activity,
    required this.activityDetail,
    this.scheduledDate,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final activityType = _activityTypeLabel(activityDetail.activityType);
    final customerName = activityDetail.customer?.customerName.trim() ?? '';
    final addressLine = _address;
    final scheduledTime = _scheduledTimeRange;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppSpacing.md,
            offset: Offset(0, AppSpacing.xs),
          ),
        ],
      ),

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          border: Border(
            top: BorderSide(color: AppColors.successDark, width: AppSpacing.xs),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      activityType,
                      style: AppTextStyles.heading4(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  AppSpacing.hSm,
                  const ActivityChip(
                    label: 'Ongoing',
                    textColor: AppColors.warning,
                    backgroundColor: AppColors.ongoingColorbg,
                  ),
                  AppSpacing.hSm,
                  // const ActivityChip(
                  //   label: '28m :36s',
                  //   textColor: AppColors.textWhite,
                  //   backgroundColor: AppColors.primary,
                  // ),
                ],
              ),
              AppSpacing.vMd,
              _InfoIconRow(
                icon: Icons.person_rounded,
                iconColor: AppColors.serviceBlue,
                child: RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Client - '),
                      TextSpan(
                        text: customerName.isEmpty ? '--' : customerName,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (addressLine.isNotEmpty) ...[
                AppSpacing.vSm,
                _InfoIconRow(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.error,
                  child: Text(
                    addressLine,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              AppSpacing.vSm,
              _InfoIconRow(
                icon: Icons.flag_outlined,
                iconColor: AppColors.textPrimary,
                child: RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Priority - '),
                      TextSpan(
                        text: '--',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vSm,
              _InfoIconRow(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.textPrimary,
                child: RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Date - '),
                      TextSpan(
                        text: _formattedScheduledDate,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vSm,
              _InfoIconRow(
                icon: Icons.schedule_rounded,
                iconColor: AppColors.primary,
                child: RichText(
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'Scheduled Time - '),
                      TextSpan(
                        text: scheduledTime,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vLg,
              Center(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width*0.5,
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.remove_red_eye_outlined,
                          size: AppTextStyles.bodyMedium(context).fontSize,
                          color: AppColors.primary,
                        ),
                        AppSpacing.hXs,
                        Text(
                          'View Details',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _address {
    final customerAddress =
        activityDetail.customer?.addresses.firstOrNull?.locationLabel.trim() ??
        '';
    if (customerAddress.isNotEmpty) return customerAddress;
    final visitAddress = activityDetail.address?.locationLabel.trim() ?? '';
    if (visitAddress.isNotEmpty) return visitAddress;
    return '';
  }

  String get _formattedScheduledDate {
    if (scheduledDate == null) return '--';
    return DateFormat('dd MMMM , yyyy').format(scheduledDate!);
  }

  String get _scheduledTimeRange {
    final start = _formatDisplayTime(activityDetail.estimatedTime) ?? '--';
    final end = _scheduledExitTime ?? '--';
    return '$start - $end';
  }

  String _activityTypeLabel(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return '--';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String? _formatDisplayTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = _parseTime(raw);
    if (parsed == null) return raw;
    return DateFormat('hh:mm a').format(parsed);
  }

  String? get _scheduledExitTime {
    final scheduledTime = activityDetail.estimatedTime;
    final scheduledDuration = activityDetail.estimatedDuration;
    if (scheduledTime == null ||
        scheduledTime.trim().isEmpty ||
        scheduledDuration == null ||
        scheduledDuration <= 0) {
      return null;
    }

    final parsed = _parseTime(scheduledTime);
    if (parsed == null) return null;
    return DateFormat(
      'hh:mm a',
    ).format(parsed.add(Duration(minutes: scheduledDuration)));
  }

  DateTime? _parseTime(String raw) {
    final trimmed = raw.trim();
    final now = DateTime.now();
    for (final pattern in const ['hh:mm a', 'HH:mm:ss', 'HH:mm']) {
      try {
        final parsed = DateFormat(pattern).parseStrict(trimmed);
        return DateTime(
          now.year,
          now.month,
          now.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
        );
      } catch (_) {
        // Try next pattern
      }
    }
    return null;
  }
}

class _InfoIconRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _InfoIconRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppTextStyles.bodyMedium(context).fontSize,
          color: iconColor,
        ),
        AppSpacing.hSm,
        Expanded(child: child),
      ],
    );
  }
}
