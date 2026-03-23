import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/overtime_detail.dart';

class OvertimeActivityBottomSheet extends StatelessWidget {
  final ScrollController? scrollController;
  final List<OvertimeActivity> activity;

  const OvertimeActivityBottomSheet({
    super.key,
    this.scrollController,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.042),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity',
                style: AppTextStyles.heading4(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Flexible(
          child: activity.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
                    child: Text(
                      'No activity found',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.042,
                    0,
                    screenWidth * 0.042,
                    screenHeight * 0.04,
                  ),
                  itemCount: activity.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: screenHeight * 0.02),
                  itemBuilder: (context, index) {
                    final item = activity[index];
                    return Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAction(item),
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: AppColors.textPrimary,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.008),
                          Text(
                            _formatDate(item.createdAt),
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

String _formatAction(OvertimeActivity activity) {
  final actorName = activity.actorName;
  var text = activity.action;
  if (actorName.isNotEmpty) {
    text = text.replaceAll(
      RegExp(r"<span class='activityName'>.*?</span>", caseSensitive: false),
      actorName,
    );
  }
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  return text.trim();
}

String _formatDate(DateTime? value) {
  if (value == null) return 'N/A';
  return DateFormat('dd MMM yyyy, hh:mm a').format(value);
}
