import 'package:collectivWork/features/services/presentation/pages/sub_services/visit/subservices/sub_visits/presentation/widgets/pending_visit_activity_card.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/visit/subservices/sub_visits/presentation/widgets/planned_visit_activity_card.dart';
import 'package:collectivWork/features/services/presentation/pages/sub_services/visit/subservices/sub_visits/presentation/widgets/start_visit_activity_card.dart';
import 'package:flutter/material.dart';
import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../domain/models/visit_model.dart';
import 'activity_chip.dart';
import 'completed_visit_activity_card.dart';

class VisitActivityCard extends StatelessWidget {
  final VisitActivityModel activity;
  final VisitActivityDetailModel? activityDetail;
  final String? detailError;
  final VoidCallback? onDeleteActivity;
  final VoidCallback? onCompleteActivity;
  final VoidCallback? onCancelActivity;
  final VoidCallback? onRetryLoadDetails;
  final VoidCallback? onStartActivity;
  final VoidCallback? onViewDetails;
  final bool isLoadingDetails;
  final bool isStarting;
  final bool isCompleting;
  final bool isDeleting;
  final DateTime? visitScheduledDate;

  const VisitActivityCard({
    super.key,
    required this.activity,
    this.activityDetail,
    this.detailError,
    this.onDeleteActivity,
    this.onCompleteActivity,
    this.onCancelActivity,
    this.onRetryLoadDetails,
    this.onStartActivity,
    this.onViewDetails,
    this.isLoadingDetails = false,
    this.isStarting = false,
    this.isCompleting = false,
    this.isDeleting = false,
    this.visitScheduledDate,
  });

  @override
  Widget build(BuildContext context) {
    if (_isCompletedActivity && activityDetail != null) {
      return CompletedVisitActivityCard(
        activity: activity,
        activityDetail: activityDetail!,
        scheduledDate: visitScheduledDate,
        onViewDetails: onViewDetails,
      );
    }

    if (_isCompletedActivity && isLoadingDetails) {
      return _ActivityLoadingCard(title: activity.displayTitle);
    }

    if (_isCompletedActivity && detailError != null) {
      return _ActivityDetailErrorCard(
        title: activity.displayTitle,
        message: detailError!,
        onRetry: onRetryLoadDetails,
      );
    }

    if (_isPendingActivity) {
      return PendingVisitActivityCard(
        activity: activity,
        scheduledDate: visitScheduledDate,
        onViewDetails: onViewDetails,
      );
    }

    if (_isStartedActivity && activityDetail != null) {
      return StartedVisitActivityCard(
        activity: activity,
        activityDetail: activityDetail!,
        scheduledDate: visitScheduledDate,
        onViewDetails: onViewDetails,
      );
    }

    if (_isStartedActivity && isLoadingDetails) {
      return _ActivityLoadingCard(title: activity.displayTitle);
    }

    if (_isStartedActivity && detailError != null) {
      return _ActivityDetailErrorCard(
        title: activity.displayTitle,
        message: detailError!,
        onRetry: onRetryLoadDetails,
      );
    }

    if (_isPlannedActivity) {
      return PlannedVisitActivityCard(
        activity: activity,
        scheduledDate: visitScheduledDate,
        onStartActivity: onStartActivity,
        onViewDetails: onViewDetails,
        isStarting: isStarting,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: AppSpacing.xs,
              decoration: BoxDecoration(
                color: _activityAccentColor(activity.activityStatus),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _titleLine,
                                  style: AppTextStyles.bodyMedium(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),

                              Row(
                                children: [
                                  _buildActivityStatusWidget(context),
                                  if (_isPlannedActivity) ...[
                                    AppSpacing.hSm,
                                    _buildPlannedActivityMenu(context),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vMd,
                if (_secondaryLine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      _secondaryLine,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                if (_addressLine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      'Address: $_addressLine',
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                if (_durationLine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      _durationLine,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _secondaryLine {
    final customer = activity.customer;
    if (customer != null) {
      final parts = [
        customer.customerCode,
        customer.customerType,
        customer.businessDomain,
      ].where((part) => part.trim().isNotEmpty);
      return parts.join(' • ');
    }
    final address = activity.address;
    if (address != null) {
      final parts = [
        address.addressType,
        address.city,
        address.state,
      ].where((part) => part.trim().isNotEmpty);
      return parts.join(' • ');
    }
    return '';
  }

  String get _titleLine {
    final activityType = _activityTypeLabel(activity.activityType);
    final customerName = activity.customer?.customerName.trim() ?? '';
    if (customerName.isNotEmpty) {
      return '$activityType - $customerName';
    }
    return activityType;
  }

  String get _addressLine {
    final address = activity.address;
    if (address != null) {
      return address.locationLabel;
    }
    return '';
  }

  String get _durationLine {
    final duration = activity.estimatedDuration;
    final time = activity.estimatedTime;
    if (duration == null && (time == null || time.isEmpty)) {
      return '';
    }

    final parts = <String>[];
    if (duration != null) {
      parts.add(
        duration >= 60 && duration % 60 == 0
            ? 'Duration: ${duration ~/ 60} hr'
            : 'Duration: $duration minutes',
      );
    }
    if (time != null && time.isNotEmpty) {
      parts.add('Time: $time');
    }
    return parts.join(' • ');
  }

  String _activityTypeLabel(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return '--';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  bool get _isStartedActivity {
    final normalizedStatus = activity.activityStatus.trim().toUpperCase();
    return normalizedStatus == 'STARTED' || normalizedStatus == 'IN PROGRESS';
  }

  bool get _isCompletedActivity {
    return activity.activityStatus.trim().toUpperCase() == 'COMPLETED';
  }

  bool get _isPlannedActivity {
    return activity.activityStatus.trim().toUpperCase() == 'PLANNED';
  }

  bool get _isPendingActivity {
    return activity.activityStatus.trim().toUpperCase() == 'PENDING';
  }

  Widget _buildActivityStatusWidget(BuildContext context) {
    final normalizedStatus = activity.activityStatus.trim().toUpperCase();
    if (normalizedStatus == 'PLANNED' && onStartActivity != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isStarting ? null : onStartActivity,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _activityAccentColor(activity.activityStatus),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isStarting) ...[
                  SizedBox(
                    width: AppTextStyles.bodySmall(context).fontSize,
                    height: AppTextStyles.bodySmall(context).fontSize,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textWhite,
                    ),
                  ),
                  AppSpacing.hXs,
                ] else ...[
                  Icon(
                    Icons.play_circle_outline_rounded,
                    size: AppTextStyles.bodySmall(context).fontSize,
                    color: AppColors.textWhite,
                  ),
                  AppSpacing.hXs,
                ],
                Text(
                  'Start Activity',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ActivityChip(
      label: activity.activityStatus,
      textColor: _activityStatusColor(activity.activityStatus),
      backgroundColor: _activityStatusBackground(activity.activityStatus),
    );
  }

  Widget _buildPlannedActivityMenu(BuildContext context) {
    if (isDeleting) {
      return SizedBox(
        width: AppTextStyles.bodyMedium(context).fontSize,
        height: AppTextStyles.bodyMedium(context).fontSize,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    if (onDeleteActivity == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<_ActivityMenuAction>(
      padding: EdgeInsets.zero,

      constraints: const BoxConstraints(minWidth: 160),
      child: Icon(
        Icons.more_vert,
        size: AppTextStyles.bodyMedium(context).fontSize,
        color: AppColors.textSecondary,
      ),
      onSelected: (value) {
        if (value == _ActivityMenuAction.delete) {
          onDeleteActivity?.call();
        }
      },
      itemBuilder:
          (_) => const [
            PopupMenuItem<_ActivityMenuAction>(
              value: _ActivityMenuAction.delete,
              child: _ActivityMenuItem(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Activity',
                color: AppColors.error,
              ),
            ),
          ],
    );
  }

  Color _activityStatusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'COMPLETED':
        return AppColors.successDark;
      case 'STARTED':
      case 'IN PROGRESS':
        return AppColors.warning;
      case 'PLANNED':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _activityStatusBackground(String status) {
    switch (status.trim().toUpperCase()) {
      case 'COMPLETED':
        return AppColors.serviceGreenBg;
      case 'STARTED':
      case 'IN PROGRESS':
        return AppColors.serviceOrangeBg;
      case 'PLANNED':
        return AppColors.serviceBlueBg;
      default:
        return AppColors.backgroundLight;
    }
  }

  Color _activityAccentColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'COMPLETED':
      case 'STARTED':
      case 'IN PROGRESS':
        return AppColors.success;
      case 'PLANNED':
        return AppColors.info;
      default:
        return AppColors.info;
    }
  }
}

enum _ActivityMenuAction { delete }

class _ActivityMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActivityMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppTextStyles.bodyMedium(context).fontSize,
          color: color,
        ),
        AppSpacing.hSm,
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(context).copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _ActivityLoadingCard extends StatelessWidget {
  final String title;

  const _ActivityLoadingCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(),
          AppSpacing.hMd,
          Expanded(
            child: Text(
              'Loading details for $title',
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityDetailErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _ActivityDetailErrorCard({
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.vSm,
          Text(
            message,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.error),
          ),
          if (onRetry != null) ...[
            AppSpacing.vSm,
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
