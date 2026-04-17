import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../core/utils/app_spacing.dart';
import '../../domain/models/visit_model.dart';

class VisitCard extends StatelessWidget {
  final VisitModel visit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddActivity;

  const VisitCard({
    super.key,
    required this.visit,
    required this.onEdit,
    required this.onDelete,
    required this.onAddActivity,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = visit.type?.label ?? 'Visit';
    final statusLabel = visit.status?.label ?? '';
    final participant =
        visit.participants.isNotEmpty ? visit.participants.first.user : null;
    final scheduleLabel =
        visit.scheduledDate != null
            ? DateFormat('dd/MM/yyyy').format(visit.scheduledDate!)
            : '--/--/----';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPaddingSmall,
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
          AppSpacing.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
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
                _buildChip(
                  context,
                  label: statusLabel,
                  textColor: _statusColor(visit.status),
                  backgroundColor: _statusBackground(visit.status),
                ),
            ],
          ),
          AppSpacing.vMd,
          Row(
            children: [
              _buildUserAvatar(context, participant),
              AppSpacing.hSm,
              Expanded(
                child: Text(
                  participant?.fullName ?? visit.createdBy.fullName,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: AppTextStyles.bodySmall(context).fontSize,
                color: AppColors.textSecondary,
              ),
              AppSpacing.hXs,
              Text(
                scheduleLabel,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
              if (visit.startTime != null) ...[
                AppSpacing.hSm,
                const Icon(
                  Icons.access_time_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.hXs,
                Text(
                  visit.startTime!,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ],
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

  Widget _buildUserAvatar(BuildContext context, VisitUserModel? user) {
    if (user?.imageUrl != null && user!.imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.imageUrl!,
          width: 20,
          height: 20,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallbackAvatar(context, user),
        ),
      );
    }

    return _fallbackAvatar(context, user);
  }

  Widget _fallbackAvatar(BuildContext context, VisitUserModel? user) {
    return CircleAvatar(
      radius: 10,
      backgroundColor:
          _parseColor(user?.profileColor) ?? AppColors.primaryLight,
      child: Text(
        user?.initials ?? '?',
        style: AppTextStyles.bodySmall(context).copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }

  Color _statusColor(VisitStatus? status) {
    return switch (status) {
      VisitStatus.planned => AppColors.info,
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
      null => AppColors.backgroundMedium,
    };
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length != 6 && normalized.length != 8) {
      return null;
    }
    final buffer = StringBuffer();
    if (normalized.length == 6) {
      buffer.write('ff');
    }
    buffer.write(normalized);
    return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0);
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
