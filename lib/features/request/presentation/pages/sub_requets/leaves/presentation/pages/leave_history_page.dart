import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import 'package:collectivWork/core/widgets/loading_widget.dart';
import '../bloc/leave_history/leave_history_bloc.dart';
import '../bloc/leave_history/leave_history_state.dart';

class LeaveHistoryPage extends StatelessWidget {
  final String leaveType;

  const LeaveHistoryPage({super.key, required this.leaveType});

  bool get _isLopHistory {
    final normalizedLeaveType = leaveType.trim().toLowerCase();
    return normalizedLeaveType == 'lop' ||
        normalizedLeaveType.contains('loss of pay');
  }

  bool _isPositiveChange(dynamic record) {
    final normalizedAction = record.action.trim().toLowerCase();
    if (!_isLopHistory) {
      return normalizedAction == 'addition';
    }

    final normalizedRemarks = record.remarks.trim().toLowerCase();
    if (normalizedRemarks.contains('penalty applied')) {
      return false;
    }
    if (normalizedRemarks.contains('penalty restored')) {
      return true;
    }

    return normalizedAction == 'addition';
  }

  String _changeLabel(dynamic record, bool isPositive) {
    final amount = record.leaveCount.abs();
    return isPositive ? '+ $amount' : '- $amount';
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.02,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance History',
                  style: AppTextStyles.heading4(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: BlocBuilder<LeaveHistoryBloc, LeaveHistoryState>(
              builder: (context, state) {
                if (state is LeaveHistoryLoading ||
                    state is LeaveHistoryInitial) {
                  return Center(child: LoadingWidget());
                } else if (state is LeaveHistoryError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.error),
                      ),
                    ),
                  );
                } else if (state is LeaveHistoryLoaded) {
                  final history = state.history.reversed.toList();
                  if (history.isEmpty) {
                    return Center(
                      child: Text(
                        'No history found for this leave type.',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return Scrollbar(
                    thumbVisibility: history.length > 6,
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width,
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.borderLight.withValues(alpha: 0.3),
                            ),
                            headingTextStyle: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            dataTextStyle: AppTextStyles.bodyMedium(context),
                            columns: [
                              const DataColumn(label: Text('Date')),
                              if (!_isLopHistory)
                                const DataColumn(label: Text('Leave Date')),
                              const DataColumn(label: Text('Change')),
                              const DataColumn(label: Text('Available')),
                              const DataColumn(label: Text('Details')),
                            ],
                            rows:
                                history.map((record) {
                                  final dateFormat = DateFormat('dd-MMM-yyyy');
                                  final dateStr = dateFormat.format(record.date);
                                  final isPositive = _isPositiveChange(record);
                                  final changeLabel = _changeLabel(
                                    record,
                                    isPositive,
                                  );
                                  final changeColor =
                                      isPositive
                                          ? Colors.green
                                          : AppColors.error;

                                  return DataRow(
                                    cells: [
                                      DataCell(Center(child: Text(dateStr))),
                                      if (!_isLopHistory)
                                        DataCell(Center(child: const Text('-'))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: changeColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            changeLabel,
                                            style: TextStyle(
                                              color: changeColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          record.remainingLeaves
                                              .toStringAsFixed(2),
                                        ),
                                      ),
                                      DataCell(Text(record.remarks)),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
