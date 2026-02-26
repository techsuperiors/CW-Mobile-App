import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_section_header.dart';

/// Attendance calendar widget
class AttendanceCalendar extends StatefulWidget {
  const AttendanceCalendar({super.key});

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  DateTime _currentDate = DateTime(2025, 12, 1); // Start with December 2025
  DateTime? _selectedDate;

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  String _getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  List<DateTime?> _getCalendarDays() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    
    // Get the weekday of the first day (0 = Sunday, 6 = Saturday)
    final firstDayWeekday = firstDayOfMonth.weekday % 7;
    
    final days = <DateTime?>[];
    
    // Add days from previous month
    final previousMonth = DateTime(_currentDate.year, _currentDate.month - 1);
    final lastDayOfPreviousMonth = DateTime(_currentDate.year, _currentDate.month, 0);
    for (int i = firstDayWeekday - 1; i >= 0; i--) {
      days.add(DateTime(previousMonth.year, previousMonth.month, lastDayOfPreviousMonth.day - i));
    }
    
    // Add all days of the current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(_currentDate.year, _currentDate.month, day));
    }
    
    // Add days from next month to fill the grid (6 rows x 7 columns = 42 cells)
    final remainingCells = 42 - days.length;
    for (int day = 1; day <= remainingCells; day++) {
      days.add(DateTime(_currentDate.year, _currentDate.month + 1, day));
    }
    
    return days;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.year == _currentDate.year && date.month == _currentDate.month;
  }

  bool _isWeekend(DateTime date) {
    final weekday = date.weekday % 7;
    return weekday == 0 || weekday == 6; // Sunday or Saturday
  }

  // Mock data for date states - in real app, this would come from API
  DateState _getDateState(DateTime date) {
    if (!_isCurrentMonth(date)) {
      return DateState.adjacentMonth;
    }
    
    if (_isWeekend(date)) {
      return DateState.weekendUnavailable;
    }
    
    // Mock special dates - replace with actual data
    final day = date.day;
    if ([2, 5, 6, 9, 19, 20, 21, 22, 23].contains(day)) {
      return DateState.green;
    } else if ([7, 8, 16].contains(day)) {
      return DateState.red;
    } else if ([12, 13, 14, 15].contains(day)) {
      return DateState.blue;
    }
    
    return DateState.available;
  }

  Widget _buildDateCell(BuildContext context, DateTime date, DateState state, bool isCurrentMonth) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final cellSize = (screenWidth * 0.10).clamp(32.0, 42.0); // 10% of screen width, clamped

    Color backgroundColor;
    Color textColor;
    bool showStripes = false;

    switch (state) {
      case DateState.adjacentMonth:
        backgroundColor = AppColors.background;
        textColor = AppColors.textSecondary;
        break;
      case DateState.weekendUnavailable:
        backgroundColor = AppColors.backgroundLight;
        textColor = AppColors.textSecondary;
        showStripes = true;
        break;
      case DateState.available:
        backgroundColor = AppColors.background;
        textColor = AppColors.textPrimary;
        break;
      case DateState.green:
        backgroundColor = AppColors.success;
        textColor = AppColors.textWhite;
        break;
      case DateState.red:
        backgroundColor = AppColors.error;
        textColor = AppColors.textWhite;
        break;
      case DateState.blue:
        backgroundColor = AppColors.primary;
        textColor = AppColors.textWhite;
        break;
    }

    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: CustomPaint(
        painter: showStripes ? StripedBackgroundPainter() : null,
        child: Center(
          child: Text(
            '${date.day}',
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarDays = _getCalendarDays();

    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.042), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: AppStrings.calendar),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02, // 2% of screen height
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            child: CustomPaint(
              painter: DottedBorderPainter(),
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04), // 4% of screen width
                child: Column(
                  children: [
                    // Month header - Previous month, Current month, Next month with arrows
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left arrow
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.chevron_left,
                            color: AppColors.textPrimary,
                            size: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
                          ),
                          onPressed: _previousMonth,
                        ),
                        // Month display: Previous | Current | Next
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final screenWidth = MediaQuery.of(context).size.width;
                              
                              // Calculate responsive font sizes based on available width
                              final baseFontSize = (availableWidth * 0.08).clamp(10.0, 14.0);
                              final currentMonthFontSize = (availableWidth * 0.09).clamp(12.0, 16.0);
                              final spacing = (availableWidth * 0.02).clamp(4.0, 8.0);
                              
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Previous month
                                  Flexible(
                                    child: Text(
                                      _getMonthName(DateTime(_currentDate.year, _currentDate.month - 1)),
                                      style: AppTextStyles.bodySmall(context).copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  // Current month
                                  Flexible(
                                    child: Text(
                                      _getMonthName(_currentDate),
                                      style: AppTextStyles.bodyMedium(context).copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  // Next month
                                  Flexible(
                                    child: Text(
                                      _getMonthName(DateTime(_currentDate.year, _currentDate.month + 1)),
                                      style: AppTextStyles.bodySmall(context).copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Right arrow
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.chevron_right,
                            color: AppColors.textPrimary,
                            size: MediaQuery.of(context).size.width * 0.05, // 5% of screen width
                          ),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02, // 2% of screen height
                    ),
                    // Days of week
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        AppStrings.sun,
                        AppStrings.mon,
                        AppStrings.tue,
                        AppStrings.wed,
                        AppStrings.thu,
                        AppStrings.fri,
                        AppStrings.sat,
                      ]
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final day = entry.value;
                            final isWeekend = index == 0 || index == 6; // SUN or SAT
                            return Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: AppTextStyles.bodySmall(context).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isWeekend
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.015, // 1.5% of screen height
                    ),
                    // Calendar grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                        mainAxisSpacing: MediaQuery.of(context).size.width * 0.01, // 1% of screen width
                        crossAxisSpacing: MediaQuery.of(context).size.width * 0.01,
                      ),
                      itemCount: calendarDays.length,
                      itemBuilder: (context, index) {
                        final date = calendarDays[index];

                        if (date == null) {
                          return const SizedBox.shrink();
                        }

                        final dateState = _getDateState(date);
                        final isCurrentMonth = _isCurrentMonth(date);

                        return GestureDetector(
                          onTap: () {
                            if (dateState != DateState.weekendUnavailable) {
                              _selectDate(date);
                            }
                          },
                          child: Center(
                            child: _buildDateCell(context, date, dateState, isCurrentMonth),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DateState {
  adjacentMonth,
  weekendUnavailable,
  available,
  green,
  red,
  blue,
}

/// Custom painter for striped background (diagonal stripes)
class StripedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textTertiary.withOpacity(0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Draw diagonal stripes from top-left to bottom-right
    const stripeSpacing = 4.0;
    final diagonalLength = size.width * 1.414; // sqrt(2) for 45-degree angle
    
    // Start from top-left, draw lines going down-right
    for (double i = -diagonalLength; i < diagonalLength * 2; i += stripeSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + diagonalLength, diagonalLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StripedBackgroundPainter oldDelegate) => false;
}

/// Custom painter for dotted border
class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    // Create a dashed path effect
    final dashPath = _dashPath(path, dashArray: CircularIntervalList<double>([5.0, 5.0]));

    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path path, {required CircularIntervalList<double> dashArray}) {
    final dashPath = Path();
    final pathMetrics = path.computeMetrics();

    for (final pathMetric in pathMetrics) {
      var distance = 0.0;
      while (distance < pathMetric.length) {
        final length = dashArray.next;
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length;
        if (distance < pathMetric.length) {
          distance += dashArray.next;
        }
      }
    }

    return dashPath;
  }

  @override
  bool shouldRepaint(DottedBorderPainter oldDelegate) => false;
}

/// Helper class for circular interval list
class CircularIntervalList<T> {
  final List<T> _list;
  int _index = 0;

  CircularIntervalList(this._list);

  T get next {
    if (_index >= _list.length) {
      _index = 0;
    }
    return _list[_index++];
  }
}

