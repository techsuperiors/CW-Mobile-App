import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/common/app_avatar.dart';
import '../../domain/entities/announcement_entity.dart';

class PostOverviewTile extends StatelessWidget {
  final AnnouncementEntity announcement;
  final String? statusLabel;
  final Color? statusColor;

  const PostOverviewTile({
    super.key,
    required this.announcement,
    this.statusLabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final author = announcement.createdByUser;
    final title = _resolveTitle(announcement);
    final preview = _resolvePreview(announcement);
    final authorName = author?.fullName.trim().isNotEmpty == true
        ? author!.fullName.trim()
        : 'User';

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppSpacing.md,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                imageUrl: author?.imageUrl,
                firstName: author?.firstName,
                lastName: author?.lastName,
                name: authorName,
                radius: AppSpacing.md,
                backgroundColor: AppColors.backgroundMedium,
              ),
              AppSpacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.vXs,
                    Text(
                      _formatDate(announcement.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (statusLabel != null && statusLabel!.trim().isNotEmpty)
                _StatusChip(
                  label: statusLabel!,
                  color: statusColor ?? AppColors.attendanceTeal,
                ),
            ],
          ),
          AppSpacing.vMd,
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (preview.isNotEmpty) ...[
            AppSpacing.vSm,
            Text(
              preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _resolveTitle(AnnouncementEntity announcement) {
    final subject = announcement.subject.trim();
    if (subject.isNotEmpty) return subject;

    final question = (announcement.question ?? '').trim();
    if (question.isNotEmpty) return question;

    return 'Untitled post';
  }

  static String _resolvePreview(AnnouncementEntity announcement) {
    final description = announcement.description.trim();
    if (description.isNotEmpty) return description;

    final question = (announcement.question ?? '').trim();
    if (question.isNotEmpty && question != _resolveTitle(announcement)) {
      return question;
    }

    return '';
  }

  static String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM yyyy, h:mm a').format(date);
    } catch (_) {
      return rawDate;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall(context).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
