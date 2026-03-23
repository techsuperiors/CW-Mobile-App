import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../attendance/domain/entities/attendance_regularize_detail.dart';

class RegularizeActivityBottomSheet extends StatelessWidget {
  final ScrollController? scrollController;
  final List<AttendanceRegularizeActivity> activity;

  const RegularizeActivityBottomSheet({
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
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.096,
                    height: screenWidth * 0.096,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.timeline_rounded,
                      size: screenWidth * 0.053,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.021),
                  Text(
                    'Activity',
                    style: AppTextStyles.heading4(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
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
                    final visual = _activityVisual(item.actionType);
                    return Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                            decoration: BoxDecoration(
                              color: visual.$2.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              visual.$1,
                              color: visual.$2,
                              size: screenWidth * 0.046,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.032),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatAction(item),
                                  style: AppTextStyles.bodyMedium(context)
                                      .copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.45,
                                      ),
                                ),
                                SizedBox(height: screenHeight * 0.008),
                                Text(
                                  _formatDate(item.createdAt),
                                  style: AppTextStyles.bodySmall(context)
                                      .copyWith(
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
    );
  }
}

(IconData, Color) _activityVisual(String actionType) {
  switch (actionType.toLowerCase()) {
    case 'update':
      return (Icons.edit_outlined, const Color(0xFF0086C9));
    case 'withdraw':
      return (Icons.remove_circle_outline, const Color(0xFFF04438));
    case 'approve':
      return (Icons.check_circle_outline, const Color(0xFF12B76A));
    case 'reject':
      return (Icons.cancel_outlined, const Color(0xFFF04438));
    case 'create':
    default:
      return (Icons.fiber_manual_record_rounded, AppColors.primary);
  }
}

String _formatAction(AttendanceRegularizeActivity activity) {
  final actorName = activity.actorName;
  var text = activity.action;
  if (actorName.isNotEmpty) {
    text = text.replaceAll(
      RegExp(r"<span class='activityName'>.*?</span>", caseSensitive: false),
      actorName,
    );
  }
  text = text.replaceAll(
    RegExp(r"<span class='activityName'></span>", caseSensitive: false),
    actorName,
  );
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  return text.trim();
}

String _formatDate(DateTime? value) {
  if (value == null) return 'N/A';
  return DateFormat('dd MMM yyyy, hh:mm a').format(value);
}
