import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// Reusable section header widget
class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsets? padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          EdgeInsets.only(
            bottom: AppTextStyles.getSpacing(context, mobile: 1.0),
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.heading5(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
