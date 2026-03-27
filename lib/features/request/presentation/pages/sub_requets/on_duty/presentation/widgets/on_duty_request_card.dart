import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../models/on_duty_request_model.dart';

/// Card widget for displaying On-Duty request information
class OnDutyRequestCard extends StatelessWidget {
  final OnDutyRequestModel onDutyRequest;
  final VoidCallback? onTap;

  const OnDutyRequestCard({super.key, required this.onDutyRequest, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final statusColor = _getStatusColor(onDutyRequest.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.012),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.none,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored left border
              Container(
                width: screenWidth * 0.032,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.022,
                    vertical: screenHeight * 0.018,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // On-Duty details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // No. of Days
                            Text(
                              onDutyRequest.subject ?? onDutyRequest.reason,
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            // Date range with calendar icon
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: screenWidth * 0.032,
                                  color: statusColor,
                                ),
                                SizedBox(width: screenWidth * 0.016),
                                Flexible(
                                  child: Text(
                                    onDutyRequest.dateRange,
                                    style: AppTextStyles.bodySmall(
                                      context,
                                    ).copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: statusColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            // Subject/Reason
                            Text(
                              'No. of Days ${onDutyRequest.numberOfDays.toString().padLeft(2, '0')}',

                              style: AppTextStyles.bodySmall(context).copyWith(
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.021),
                      // Status badge
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.25,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.027,
                          vertical: screenHeight * 0.004,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          onDutyRequest.status.displayName,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OnDutyStatus status) {
    switch (status) {
      case OnDutyStatus.pending:
        return AppColors
            .approvalSheetPending; // 0xFF2196F3 ya 0xFF0086C9
      case OnDutyStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case OnDutyStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case OnDutyStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
    }
  }
}
