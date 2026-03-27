import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../models/regularize_request_model.dart';

/// Card widget for displaying regularize request information
class RegularizeRequestCard extends StatelessWidget {
  final RegularizeRequestModel regularizeRequest;
  final VoidCallback? onTap;

  const RegularizeRequestCard({
    super.key,
    required this.regularizeRequest,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get status color
    final statusColor = _getStatusColor(regularizeRequest.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.only(
          bottom: screenHeight * 0.010, // 1.2% of screen height
        ),
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
                width: screenWidth * 0.032, // 3.2% of screen width
                decoration: BoxDecoration(
                  color: statusColor,
                  // Use status color (blue for pending, green for approved, red for rejected)
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
                    vertical: screenHeight * 0.012,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Regularize details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Request Type (Punch-In, Punch-Out, Both)
                            Text(
                              regularizeRequest.reason,
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            // 0.6% of screen height
                            // Date range with calendar icon
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: screenWidth * 0.038,
                                  // 3.2% of screen width
                                  color:
                                      statusColor, // Use status color for calendar icon
                                ),
                                SizedBox(width: screenWidth * 0.005),
                                // 1.6% of screen width
                                Flexible(
                                  child: Text(
                                    regularizeRequest.dateRange,
                                    style: AppTextStyles.bodySmall(
                                      context,
                                    ).copyWith(
                                      fontWeight: FontWeight.w400,
                                      color:
                                          statusColor, // Use status color for date text
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            // 0.6% of screen height
                            // Reason
                            Text(
                              regularizeRequest.requestType.displayName,
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
                      // 2.1% of screen width
                      // Status badge (white text on colored background)
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.25, // Prevent overflow
                        ),

                        padding: EdgeInsets.symmetric(
                          horizontal:
                          screenWidth * 0.027, // 2.7% of screen width
                          vertical:
                          screenHeight * 0.004, // 0.8% of screen height
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          regularizeRequest.status.displayName,
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
  Color _getStatusColor(RegularizeStatus status) {
    switch (status) {
      case RegularizeStatus.pending:
        return AppColors.approvalSheetPending; //
      case RegularizeStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case RegularizeStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case RegularizeStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
    }
  }
}
