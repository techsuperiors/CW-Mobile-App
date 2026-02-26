import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Attendance detail calendar with color-coded dates
class AttendanceDetailCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime)? onDateSelected;

  const AttendanceDetailCalendar({
    super.key,
    this.selectedDate,
    this.onDateSelected,
  });

  @override
  State<AttendanceDetailCalendar> createState() => _AttendanceDetailCalendarState();
}

class _AttendanceDetailCalendarState extends State<AttendanceDetailCalendar> {
  DateTime _currentDate = DateTime(2025, 12, 1); // December 2025
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime(2025, 12, 30);
  }

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
    widget.onDateSelected?.call(date);
  }

  List<DateTime?> _getCalendarDays() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Convert to 0-6 (Sun-Sat)
    
    final days = <DateTime?>[];
    
    // Add days from previous month
    final daysBefore = firstWeekday;
    for (int i = daysBefore - 1; i >= 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
    }
    
    // Add days of current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(_currentDate.year, _currentDate.month, day));
    }
    
    // Add days from next month to fill the grid
    final remainingDays = 42 - days.length; // 6 rows * 7 days
    for (int day = 1; day <= remainingDays; day++) {
      days.add(DateTime(_currentDate.year, _currentDate.month + 1, day));
    }
    
    return days;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.year == _currentDate.year && date.month == _currentDate.month;
  }

  bool _isWeekend(DateTime date) {
    final weekday = date.weekday;
    return weekday == 7 || weekday == 6; // Saturday or Sunday
  }

  // Mock data for date states - in real app, this would come from API
  DateStatus _getDateStatus(DateTime date) {
    if (!_isCurrentMonth(date)) {
      return DateStatus.otherMonth;
    }
    
    if (_isWeekend(date)) {
      return DateStatus.weekend;
    }
    
    // Mock data based on image description
    final day = date.day;
    if ([2, 5, 6, 9, 12, 13, 19, 20, 21, 22, 23, 26, 27, 28, 29, 30].contains(day)) {
      return DateStatus.present;
    } else if ([15].contains(day)) {
      return DateStatus.leave;
    } else if ([7, 8, 14, 16].contains(day)) {
      return DateStatus.absent;
    } else if (day == 25) {
      return DateStatus.holiday;
    }
    
    return DateStatus.available;
  }

  Widget _buildDateCell(BuildContext context, DateTime date, DateStatus status, bool isCurrentMonth) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = (screenWidth * 0.10).clamp(32.0, 42.0);
    final isSelected = _selectedDate != null &&
        date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;

    Color backgroundColor;
    Color textColor;
    bool showStripes = false;

    switch (status) {
      case DateStatus.otherMonth:
        backgroundColor = AppColors.background;
        textColor = AppColors.textSecondary.withOpacity(0.5);
        break;
      case DateStatus.weekend:
        backgroundColor = AppColors.backgroundLight;
        textColor = AppColors.textSecondary;
        showStripes = true;
        break;
      case DateStatus.available:
        backgroundColor = AppColors.background;
        textColor = AppColors.textPrimary;
        break;
      case DateStatus.present:
        backgroundColor = AppColors.success;
        textColor = AppColors.textWhite;
        break;
      case DateStatus.leave:
        backgroundColor = AppColors.warning;
        textColor = AppColors.textWhite;
        break;
      case DateStatus.absent:
        backgroundColor = AppColors.error;
        textColor = AppColors.textWhite;
        break;
      case DateStatus.holiday:
        backgroundColor = AppColors.error;
        textColor = AppColors.textWhite;
        break;
    }

    // Highlight selected date
    if (isSelected && status == DateStatus.present) {
      backgroundColor = AppColors.successDark;
    }

    return GestureDetector(
      onTap: () {
        if (status != DateStatus.weekend && status != DateStatus.otherMonth) {
          _selectDate(date);
        }
      },
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: isSelected && status != DateStatus.present
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: CustomPaint(
          painter: showStripes ? StripedBackgroundPainter() : null,
          child: Center(
            child: status == DateStatus.holiday && date.day == 25
                ? Icon(
                    Icons.celebration,
                    size: cellSize * 0.5,
                    color: textColor,
                  )
                : Text(
                    '${date.day}',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                    ),
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
    final screenHeight = MediaQuery.of(context).size.height;
    
    final monthName = DateFormat('MMMM yyyy').format(_currentDate);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.042),
      padding: EdgeInsets.all(screenWidth * 0.042),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with month name and navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    monthName,
                    style: AppTextStyles.heading4(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: screenWidth * 0.032,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  // Legend dots
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Navigation arrows
              Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: Icon(
                      Icons.chevron_left,
                      size: screenWidth * 0.053,
                      color: AppColors.textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: Icon(
                      Icons.chevron_right,
                      size: screenWidth * 0.053,
                      color: AppColors.textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Legend
          Row(
            children: [
              _buildLegendItem(context, 'Present', AppColors.success),
              SizedBox(width: screenWidth * 0.05),
              _buildLegendItem(context, 'Leave', AppColors.warning),
              SizedBox(width: screenWidth * 0.05),
              _buildLegendItem(context, 'Absent', AppColors.error),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTextStyles.labelSmall(context).copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: screenHeight * 0.015),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: screenWidth * 0.01,
              crossAxisSpacing: screenWidth * 0.01,
            ),
            itemCount: calendarDays.length,
            itemBuilder: (context, index) {
              final date = calendarDays[index];
              if (date == null) {
                return const SizedBox.shrink();
              }
              final status = _getDateStatus(date);
              final isCurrentMonth = _isCurrentMonth(date);
              return _buildDateCell(context, date, status, isCurrentMonth);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.015),
        Text(
          label,
          style: AppTextStyles.labelSmall(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

enum DateStatus {
  otherMonth,
  weekend,
  available,
  present,
  leave,
  absent,
  holiday,
}

/// Custom painter for striped background (diagonal stripes)
class StripedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = 4.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

