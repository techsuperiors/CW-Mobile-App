import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../utils/error_message_mapper.dart';

class ApiErrorState extends StatelessWidget {
  final String? rawMessage;
  final VoidCallback? onRetry;
  final String title;

  const ApiErrorState({
    super.key,
    required this.rawMessage,
    this.onRetry,
    this.title = 'Something went wrong',
  });

  @override
  Widget build(BuildContext context) {
    final message = ErrorMessageMapper.toUserFriendlyMessage(rawMessage);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sync_problem,
              size: MediaQuery.of(context).size.width * 0.15,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.heading4(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "There is a problem in loading this data...",
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
