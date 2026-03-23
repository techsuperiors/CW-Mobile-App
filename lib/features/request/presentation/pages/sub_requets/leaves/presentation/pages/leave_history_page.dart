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

  @override
  Widget build(BuildContext context) {
    final sw=MediaQuery.of(context).size.width;
    final sh=MediaQuery.of(context).size.height;
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
            padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04,
            ),
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
                  return  Center(child: LoadingWidget());
                }
                else if (state is LeaveHistoryError) {
                  return Center(
                    child: Padding(
                      padding:  EdgeInsets.all(24.0),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.error),
                      ),
                    ),
                  );
                }
                else if (state is LeaveHistoryLoaded) {
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

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.borderLight.withOpacity(0.3),
                        ),
                        // columnSpacing: 24,
                        headingTextStyle: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        dataTextStyle: AppTextStyles.bodyMedium(context),
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Leave Date')),
                          DataColumn(label: Text('Change')),
                          DataColumn(label: Text('Available')),
                          DataColumn(label: Text('Details')),
                        ],
                        rows:
                            history.map((record) {
                              final dateFormat = DateFormat('dd-MM-yyyy');
                              final dateStr = dateFormat.format(record.date);
                              // Determine if this is a positive (addition) or negative (deduction/subtraction)
                              final isPositive =
                                  record.action.toLowerCase() == 'addition';

                              final changeLabel =
                                  isPositive
                                      ? '+ ${record.leaveCount}'
                                      : '- ${record.leaveCount.abs()}';

                              final changeColor =
                                  isPositive ? Colors.green : AppColors.error;

                              return DataRow(
                                cells: [
                                  DataCell(Center(child: Text(dateStr))),
                                  DataCell(Center(child: const Text('-'))),
                                  // API doesn't provide explicit Leave Date out of box natively yet
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: changeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
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
                                      record.remainingLeaves.toStringAsFixed(2),
                                    ),
                                  ),
                                  DataCell(Text(record.remarks)),
                                ],
                              );
                            }).toList(),
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
