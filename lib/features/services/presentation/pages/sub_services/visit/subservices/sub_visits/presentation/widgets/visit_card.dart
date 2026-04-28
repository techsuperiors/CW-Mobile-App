import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../domain/models/visit_model.dart';

class VisitCard extends StatelessWidget {
  final VisitModel visit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddActivity;
  final VoidCallback? onStartedTap;

  const VisitCard({
    super.key,
    required this.visit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onAddActivity,
    this.onStartedTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = visit.type?.label ?? 'Visit';
    final statusLabel = visit.status?.label ?? '';
    final statusMetaColor = _statusMetaColor(visit.status);
    final scheduleLabel =
        visit.scheduledDate != null
            ? DateFormat('dd/MM/yyyy').format(visit.scheduledDate!)
            : '--/--/----';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.cardPaddingSmall,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        visit.visitTitle,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    PopupMenuButton<_VisitCardMenuAction>(
                      padding: EdgeInsets.zero,

                      icon: Icon(
                        Icons.more_vert,
                        size: AppTextStyles.bodyMedium(context).fontSize,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case _VisitCardMenuAction.edit:
                            onEdit();
                            break;
                          case _VisitCardMenuAction.delete:
                            onDelete();
                            break;
                          case _VisitCardMenuAction.addActivity:
                            onAddActivity();
                            break;
                        }
                      },
                      itemBuilder:
                          (context) => const [
                            PopupMenuItem<_VisitCardMenuAction>(
                              value: _VisitCardMenuAction.edit,
                              child: _VisitMenuItem(
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                              ),
                            ),
                            PopupMenuItem<_VisitCardMenuAction>(
                              value: _VisitCardMenuAction.delete,
                              child: _VisitMenuItem(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                color: AppColors.error,
                              ),
                            ),
                            PopupMenuItem<_VisitCardMenuAction>(
                              value: _VisitCardMenuAction.addActivity,
                              child: _VisitMenuItem(
                                icon: Icons.playlist_add_outlined,
                                label: 'Add Activity',
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                AppSpacing.vXxs,

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // spacing: AppSpacing.sm,
                  // runSpacing: AppSpacing.sm,
                  children: [
                    _buildChip(
                      context,
                      label: typeLabel,
                      textColor:
                          visit.type == VisitType.customer
                              ? AppColors.successDark
                              : AppColors.info,
                      backgroundColor:
                          visit.type == VisitType.customer
                              ? AppColors.serviceGreenBg
                              : AppColors.serviceBlueBg,
                    ),
                    if (statusLabel.isNotEmpty)
                      _buildStatusWidget(
                        context,
                        status: visit.status,
                        statusLabel: statusLabel,
                      ),
                  ],
                ),
                AppSpacing.vMd,

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppTextStyles.bodySmall(context).fontSize,
                      color: statusMetaColor,
                    ),
                    AppSpacing.hXs,
                    Text(
                      scheduleLabel,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: statusMetaColor),
                    ),
                    if (visit.startTime != null) ...[
                      AppSpacing.hSm,
                      Icon(
                        Icons.access_time_outlined,
                        size: AppTextStyles.bodySmall(context).fontSize,
                        color: statusMetaColor,
                      ),
                      AppSpacing.hXs,
                      Text(
                        visit.startTime!,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: statusMetaColor),
                      ),
                    ],
                  ],
                ),
                AppSpacing.vXs,

                // Row(
                //   children: [
                //     _buildUserAvatar(context, participant),
                //     AppSpacing.hSm,
                //     Expanded(
                //       child: Text(
                //         participant?.fullName ?? visit.createdBy.fullName,
                //         style: AppTextStyles.bodySmall(context).copyWith(
                //           color: AppColors.textSecondary,
                //           fontWeight: FontWeight.w500,
                //         ),
                //         overflow: TextOverflow.ellipsis,
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall(
          context,
        ).copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusWidget(
    BuildContext context, {
    required VisitStatus? status,
    required String statusLabel,
  }) {
    if (status == VisitStatus.started && onStartedTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onStartedTap,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  size: AppTextStyles.bodySmall(context).fontSize,
                  color: AppColors.textWhite,
                ),
                AppSpacing.hXs,
                Text(
                  'Start Visit',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildChip(
      context,
      label: statusLabel,
      textColor: _statusColor(status),
      backgroundColor: _statusBackground(status),
    );
  }

  Color _statusColor(VisitStatus? status) {
    return switch (status) {
      VisitStatus.planned => AppColors.primary,
      VisitStatus.started => AppColors.warning,
      VisitStatus.completed => AppColors.successDark,
      VisitStatus.cancelled => AppColors.error,
      null => AppColors.textSecondary,
    };
  }

  Color _statusBackground(VisitStatus? status) {
    return switch (status) {
      VisitStatus.planned => AppColors.serviceBlueBg,
      VisitStatus.started => AppColors.serviceOrangeBg,
      VisitStatus.completed => AppColors.serviceGreenBg,
      VisitStatus.cancelled => AppColors.servicePinkDarkBg,
      null => AppColors.backgroundLight,
    };
  }

  Color _statusMetaColor(VisitStatus? status) {
    return switch (status) {
      VisitStatus.planned => AppColors.primary,
      VisitStatus.started => AppColors.primary,
      VisitStatus.completed => AppColors.successDark,
      VisitStatus.cancelled => AppColors.error,
      null => AppColors.textSecondary,
    };
  }
}

enum _VisitCardMenuAction { edit, delete, addActivity }

class _VisitMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _VisitMenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
        AppSpacing.hSm,
        Text(
          label,
          style: AppTextStyles.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w500,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
