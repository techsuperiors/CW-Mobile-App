import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../data/models/expense_item_model.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseItemModel item;
  final VoidCallback onTap;

  const ExpenseCard({required this.item, required this.onTap});

  Color get _accentColor {
    switch (item.approvalStatus) {
      case ExpenseApprovalStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case ExpenseApprovalStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case ExpenseApprovalStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
      case ExpenseApprovalStatus.pending:
        return AppColors.approvalSheetPending; //
      case ExpenseApprovalStatus.unknown:
        return const Color(0xFF0086C9);
    }
  }

  String get _statusLabel {
    return item.approvalStatusLabel;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.02,
                height: screenHeight * 0.14,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.016,
                    horizontal: screenWidth * 0.04,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.expenseName,
                              style: AppTextStyles.bodyMediumHeading(
                                context,
                              ).copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenHeight * 0.003,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _statusLabel,
                              style: AppTextStyles.labelSmall(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Text(
                        item.amount > 0
                            ? 'Amount : ${NumberFormat.currency(symbol: '₹ ', decimalDigits: 0).format(item.amount)}'
                            : 'Type : ${item.expenseType}',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textPrimary),
                      ),
                      SizedBox(height: screenHeight * 0.004),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: _accentColor,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            _getDateRange(item.fromDate, item.toDate),
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: _accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.004),
                      Text(
                        'Duration : ${item.durationDays} ${item.durationDays == 1 ? 'day' : 'days'}',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
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
