import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../models/wfh_request_model.dart';

/// Card widget for displaying WFH request information
class WfhRequestCard extends StatelessWidget {
  final WfhRequestModel wfhRequest;
  final VoidCallback? onTap;

  const WfhRequestCard({
    super.key,
    required this.wfhRequest,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get status color
    final statusColor = _getStatusColor(wfhRequest.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.only(
          bottom: screenHeight * 0.012, // 1.2% of screen height
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
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
                width: screenWidth * 0.032, // 3.2% of screen width
                decoration: BoxDecoration(
                  color: statusColor, // Use status color (blue for pending, green for approved, red for rejected)
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
                    horizontal: screenWidth * 0.022, // 2.2% of screen width
                    vertical: screenHeight * 0.018, // 1.8% of screen height
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // WFH details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // No. of Days
                            Text(
                              'No. of Days ${wfhRequest.numberOfDays.toString().padLeft(2, '0')}',
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.006), // 0.6% of screen height
                            // Date range with calendar icon
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: screenWidth * 0.032, // 3.2% of screen width
                                  color: statusColor, // Use status color for calendar icon
                                ),
                                SizedBox(width: screenWidth * 0.016), // 1.6% of screen width
                                Flexible(
                                  child: Text(
                                    wfhRequest.dateRange,
                                    style: AppTextStyles.bodySmall(context).copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: statusColor, // Use status color for date text
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.006), // 0.6% of screen height
                            // Reason
                            Text(
                              wfhRequest.reason,
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
                      SizedBox(width: screenWidth * 0.021), // 2.1% of screen width
                      // Status badge (white text on colored background)
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.25, // Prevent overflow
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.027, // 2.7% of screen width
                          vertical: screenHeight * 0.008, // 0.8% of screen height
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          wfhRequest.status.displayName,
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

  Color _getStatusColor(WfhStatus status) {
    switch (status) {
      case WfhStatus.pending:
        return const Color(0xFF2196F3); // Blue
      case WfhStatus.approved:
        return const Color(0xFF4CAF50); // Green
      case WfhStatus.rejected:
        return const Color(0xFFE53935); // Red
    }
  }
}
