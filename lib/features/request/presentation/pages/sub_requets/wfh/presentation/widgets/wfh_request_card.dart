import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../models/wfh_request_model.dart';

/// Card widget for displaying WFH request information
class WfhRequestCard extends StatelessWidget {
  final WfhRequestModel wfhRequest;
  final VoidCallback? onTap;

  const WfhRequestCard({super.key, required this.wfhRequest, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusColor = _getStatusColor(wfhRequest.status);
    final isPending = wfhRequest.status == WfhStatus.pending;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.010),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isPending
                ? null
                : Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored left accent bar
                Container(
                  width: screenWidth * 0.018,
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
                      horizontal: screenWidth * 0.034,
                      vertical: screenHeight * 0.014,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: title + date + duration
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Subject / Title
                              Text(
                                wfhRequest.subject ?? '',
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: screenHeight * 0.006),
                              // Date range row
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: screenWidth * 0.038,
                                    color: statusColor,
                                  ),
                                  SizedBox(width: screenWidth * 0.014),
                                  Flexible(
                                    child: Text(
                                      wfhRequest.dateRange,
                                      style: AppTextStyles.bodySmall(context).copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: statusColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              // Duration
                              Text(
                                'Duration : ${wfhRequest.numberOfDays} ${wfhRequest.numberOfDays == 1 ? 'day' : 'days'}',
                                style: AppTextStyles.bodySmall(context).copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Container(
                          constraints: BoxConstraints(maxWidth: screenWidth * 0.26),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.030,
                            vertical: screenHeight * 0.002,
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

                        // Status badge
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(WfhStatus status) {
    switch (status) {
      case WfhStatus.pending:
        return AppColors.approvalSheetPending; //
      case WfhStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case WfhStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case WfhStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
    }
  }
}

