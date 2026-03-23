import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_text_styles.dart';


class RequestEmptyState extends StatelessWidget {
  const RequestEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: size.width * 0.15,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            AppStrings.noData,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
