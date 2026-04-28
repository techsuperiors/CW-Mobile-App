import 'package:flutter/material.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../core/widgets/common/app_card.dart';
import '../../domain/models/employee_directory_model.dart';

class EmployeeDirectoryCard extends StatelessWidget {
  final EmployeeDirectoryModel employee;
  final VoidCallback? onTap;

  const EmployeeDirectoryCard({super.key, required this.employee, this.onTap});

  @override
  Widget build(BuildContext context) {
    final loginStatusColor = _loginStatusColor(employee.loginStatus);
    final attendanceColor = _attendanceStatusColor(employee.attendanceStatus);
    final avatarSize = AppSpacing.xxl + AppSpacing.xl;

    return AppCard(
      borderRadius: AppSpacing.lg,
      elevation: 1,
      onTap: onTap,
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
        left: AppSpacing.xs,
        right: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSpacing.hXs,
                    Container(
                      width: AppSpacing.sm,
                      height: AppSpacing.sm,
                      decoration: BoxDecoration(
                        color: loginStatusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    AppSpacing.hXs,
                    Flexible(
                      child: Text(
                        employee.loginStatusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: loginStatusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.person_add_alt_1_outlined,
                size: AppTextStyles.bodyMedium(context).fontSize,
                color: AppColors.serviceBlue,
              ),
              AppSpacing.hXs,
            ],
          ),
          AppSpacing.vMd,
          Center(
            child: EmployeeDirectoryAvatar(
              name: employee.fullName,
              imageUrl: employee.imageUrl,
              profileColor: employee.profileColor,
              radius: avatarSize / 2,
            ),
          ),
          AppSpacing.vSm,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                employee.fullName,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${employee.employeeCodeLabel}',
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,

                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          AppSpacing.vMd,
          Text(
            employee.email.isEmpty ? '--' : employee.email,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.vXs,
          Text(
            employee.designationLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          AppSpacing.vXs,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: AppTextStyles.bodySmall(context).fontSize,
                  color: AppColors.textSecondary,
                ),
                AppSpacing.hXs,
                Flexible(
                  child: Text(
                    employee.phoneLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vSm,
          Flexible(
            child: Text(
              employee.attendanceStatusLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: attendanceColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _loginStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'online':
        return AppColors.success;
      case 'away':
        return AppColors.warning;
      case 'offline':
        return AppColors.textTertiary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _attendanceStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.warning;
      case 'late':
        return AppColors.warning;
      case 'half day':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }
}

class EmployeeDirectoryAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String profileColor;
  final double radius;

  const EmployeeDirectoryAvatar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.profileColor,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    final initials = _initials(name);
    final backgroundColor = _parseColor(profileColor) ?? AppColors.primaryLight;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: hasImage ? NetworkImage(imageUrl.trim()) : null,
      child:
          hasImage
              ? null
              : Text(
                initials,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                ),
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
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Color? _parseColor(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final normalized = raw.replaceFirst('#', '');
    final withAlpha = normalized.length == 6 ? 'FF$normalized' : normalized;
    final parsed = int.tryParse(withAlpha, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}
