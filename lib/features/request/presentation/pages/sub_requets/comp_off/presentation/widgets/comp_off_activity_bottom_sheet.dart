import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/comp_off_detail.dart';

class CompOffActivityBottomSheet extends StatelessWidget {
  final ScrollController? scrollController;
  final List<CompOffActivity> activity;

  const CompOffActivityBottomSheet({
    super.key,
    this.scrollController,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
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
                        child: Row(
                          children: [
                            Container(
                              width: screenWidth*0.02,
                              height: screenHeight*0.02,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    _formatAction(item),
                                    style: AppTextStyles.bodyMediumHeading(
                                      context,
                                    ).copyWith(color: AppColors.textPrimary),
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
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _formatAction(CompOffActivity activity) {
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
