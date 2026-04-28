import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:collectivWork/core/extension/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';

class ActivityChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const ActivityChip({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool iscompleted = label == "Completed";
    final bool isplanned = label == "Planned";
    final bool isongoing = label == "Ongoing";

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      margin: EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        children: [
          iscompleted || isongoing
              ? SizedBox.shrink()
              : SizedBox(
                height: AppSpacing.lg,
                width: AppSpacing.lg,
                child: SvgPicture.asset(
                  isplanned || isongoing
                      ? AppAssets.visit_planned_Icon
                      : AppAssets.inProgressIcon,
                ),
              ),
          AppSpacing.hXs,
          Text(
            label.toLowerCase().capitalizeFirst(),
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
