import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../utils/error_message_mapper.dart';

class ApiErrorState extends StatelessWidget {
  final String? rawMessage;
  final VoidCallback? onRetry;
  final String title;
  final String? description;

  const ApiErrorState({
    super.key,
    required this.rawMessage,
    this.onRetry,
    this.title = 'Something went wrong',
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final message = ErrorMessageMapper.toUserFriendlyMessage(rawMessage);
    final resolvedDescription = description ?? message;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: sw * 0.002,
          vertical: sh * 0.002,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sync_problem,
              size: MediaQuery.of(context).size.width * 0.15,
              color: AppColors.attendanceGreyDepth,
            ),
            SizedBox(height: sh * 0.01),
            Text(
              title,
              style: AppTextStyles.heading4(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: sh * 0.01),
            Text(
              resolvedDescription,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: sh * 0.02),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
