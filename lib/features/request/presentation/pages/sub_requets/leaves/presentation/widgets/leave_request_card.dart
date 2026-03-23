import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/leave_entity.dart';

/// Card widget for displaying leave request information
class LeaveRequestCard extends StatelessWidget {
  final LeaveEntity leaveRequest;
  final VoidCallback? onTap;

  const LeaveRequestCard({super.key, required this.leaveRequest, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get status color
    final statusColor = _getStatusColor(leaveRequest.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: EdgeInsets.only(
          bottom: screenHeight * 0.008, // 1.2% of screen height
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
                width: screenWidth * 0.032,
                // 3.2% of screen width - increased for better visibility
                decoration: BoxDecoration(
                  color: statusColor,
                  // Use status color (blue for pending, green for approved)
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
                    horizontal: screenWidth * 0.022, // 4.2% of screen width
                    vertical: screenHeight * 0.012, // 1.8% of screen height
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leave details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Leave type
                            Text(
                              leaveRequest.subject ?? leaveRequest.reason,

                              style: AppTextStyles.bodyMedium(context).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(
                              height: screenHeight * 0.006,
                            ), // 0.6% of screen height
                            // Date range with calendar icon
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size:
                                      screenWidth *
                                      0.032, // 3.2% of screen width
                                  color:
                                      statusColor, // Use status color for calendar icon
                                ),
                                SizedBox(
                                  width: screenWidth * 0.016,
                                ), // 1.6% of screen width
                                Flexible(
                                  child: Text(
                                    _getDateRange(
                                      leaveRequest.fromDate,
                                      leaveRequest.toDate,
                                    ),
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
                            SizedBox(
                              height: screenHeight * 0.006,
                            ), // 0.6% of screen height
                            // Reason
                            Text(
                              leaveRequest.leaveType,
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
                      SizedBox(
                        width: screenWidth * 0.021,
                      ), // 2.1% of screen width
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
                          leaveRequest.status.displayName,
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

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return const Color(0xFF0086C9); // Blue
      case LeaveStatus.approved:
        return const Color(0xFF12B76A); // Green
      case LeaveStatus.rejected:
        return const Color(0xFFF04438); // Red
      case LeaveStatus.withdrawn:
        return const Color(0xFFF79009); // Orange
    }
  }

  String _getDateRange(DateTime fromDate, DateTime? toDate) {
    // Basic date formatting, you might want to use DateFormat from intl here
    final from =
        "${fromDate.day.toString().padLeft(2, '0')} ${_getMonthName(fromDate.month)}";
    if (toDate != null && toDate != fromDate) {
      final to =
          "${toDate.day.toString().padLeft(2, '0')} ${_getMonthName(toDate.month)}";
      return "$from - $to";
    }
    return from;
  }

  String _getMonthName(int month) {
    const monthNames = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return monthNames[month];
  }
}
