import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../calendar/domain/entities/calendar_day_entity.dart';

/// Attendance detail calendar with color-coded dates from API data.
///
/// Displays Present (green), Leave (amber), Holiday (red), and Weekend (striped)
/// based on data fetched from the calendar API.
class AttendanceDetailCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(DateTime)? onDateSelected;

  /// API-provided day data for the current month.
  final List<CalendarDayEntity> calendarDays;

  /// Callback when user navigates to a different month.
  final Function(DateTime newMonth)? onMonthChanged;

  /// Whether data is currently loading.
  final bool isLoading;

  const AttendanceDetailCalendar({
    super.key,
    this.selectedDate,
    this.onDateSelected,
    this.calendarDays = const [],
    this.onMonthChanged,
    this.isLoading = false,
  });

  @override
  State<AttendanceDetailCalendar> createState() =>
      _AttendanceDetailCalendarState();
}

class _AttendanceDetailCalendarState extends State<AttendanceDetailCalendar> {
  late DateTime _currentDate;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDate = widget.selectedDate ?? DateTime.now();
  }

  @override
  void didUpdateWidget(covariant AttendanceDetailCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != null &&
        (oldWidget.selectedDate == null ||
            !_isSameDay(widget.selectedDate!, oldWidget.selectedDate!))) {
      _selectedDate = widget.selectedDate;
    }
  }

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    });
    widget.onMonthChanged?.call(_currentDate);
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    });
    widget.onMonthChanged?.call(_currentDate);
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    widget.onDateSelected?.call(date);
  }

  List<DateTime?> _getCalendarGridDays() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(
      _currentDate.year,
      _currentDate.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0=Sun, 6=Sat

    final days = <DateTime?>[];

    // Days from previous month
    for (int i = firstWeekday - 1; i >= 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
    }

    // Days of current month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(_currentDate.year, _currentDate.month, day));
    }

    // Fill remaining to complete 6-row grid
    final remainingDays = 42 - days.length;
    for (int day = 1; day <= remainingDays; day++) {
      days.add(DateTime(_currentDate.year, _currentDate.month + 1, day));
    }

    return days;
  }

  bool _isCurrentMonth(DateTime date) {
    return date.year == _currentDate.year && date.month == _currentDate.month;
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == 6 || date.weekday == 7; // Saturday or Sunday
  }

  /// Determine a date's display status using API data.
  DateStatus _getDateStatus(DateTime date) {
    if (!_isCurrentMonth(date)) return DateStatus.otherMonth;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayData = _findDayData(dateStr);

    final isWeekoffDay = dayData?.isWeekoff == true || _isWeekend(date);

    if (isWeekoffDay) {
      // Override 1: holiday on a weekoff day
      if (dayData?.isHoliday == true) return DateStatus.holiday;
      // Override 2: user attended on weekoff
      if (dayData?.status == 'Present') return DateStatus.present;
      if (dayData?.status == 'WFH') return DateStatus.wfh;
      // Default: stripes
      return DateStatus.weekend;
    }

    // No data at all
    if (dayData == null) return DateStatus.available;

    // PRIORITY 1: Holiday (even if isFuture=true)
    if (dayData.isHoliday) return DateStatus.holiday;

    // PRIORITY 2: Status from API (covers pre-planned future WFH / approved leave)
    switch (dayData.status) {
      case 'Present':
        return DateStatus.present;
      case 'WFH':
        return DateStatus.wfh;
      case 'Leave':
        return DateStatus.leave;
      case 'Absent':
        return DateStatus.absent;
      case 'Holiday':
        return DateStatus.holiday;
    }

    // PRIORITY 3: No meaningful status — gray (future or unknown)
    return DateStatus.available;
  }

  /// Find API data for a specific date string.
  CalendarDayEntity? _findDayData(String dateStr) {
    try {
      return widget.calendarDays.firstWhere((d) => d.date == dateStr);
    } catch (_) {
      return null;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get tooltip text for a date (holiday name, leave type, etc.)
  String? _getDateTooltip(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dayData = _findDayData(dateStr);
    if (dayData == null) return null;

    if (dayData.isHoliday && dayData.holidayName != null) {
      return dayData.holidayName;
    }
    if (dayData.status == 'Leave' && dayData.leaveType != null) {
      return dayData.leaveType;
    }
    return null;
  }

  Widget _buildDateCell(
    BuildContext context,
    DateTime date,
    DateStatus status,
    bool isCurrentMonth,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = (screenWidth * 0.10).clamp(32.0, 42.0);
    final isSelected =
        _selectedDate != null &&
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
        // Weekoff day — stripes (unless overridden above by holiday/present)
        backgroundColor = AppColors.backgroundLight;
        textColor = AppColors.textSecondary;
        showStripes = true;
        break;
      case DateStatus.available:
        // Future / no-data weekday — plain, no stripes
        backgroundColor = AppColors.border.withOpacity(0.25);
        textColor = AppColors.textSecondary;
        showStripes = false;
        break;
      case DateStatus.present:
        backgroundColor = const Color(0xFF0B7F7F); // teal
        textColor = Colors.white;
        break;
      case DateStatus.wfh:
        backgroundColor = const Color(
          0xFF27AE60,
        ); // green — distinct from present
        textColor = Colors.white;
        break;
      case DateStatus.leave:
        backgroundColor = const Color(0xFFFF8C00); // orange
        textColor = Colors.white;
        break;
      case DateStatus.absent:
        backgroundColor = const Color(0xFFE74C3C); // red
        textColor = Colors.white;
        break;
      case DateStatus.holiday:
        backgroundColor = const Color(0xFFFF6B6B); // pink-red
        textColor = Colors.white;
        break;
    }

    // Darken selected present/wfh
    if (isSelected &&
        (status == DateStatus.present || status == DateStatus.wfh)) {
      backgroundColor = AppColors.successDark;
    }

    final tooltip = _getDateTooltip(date);

    Widget cell = GestureDetector(
      onTap: () {
        if (status != DateStatus.otherMonth && status != DateStatus.available) {
          _selectDate(date);
        }
      },
      child: ClipOval(
        child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border:
                isSelected && status != DateStatus.present
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
          ),
          child: CustomPaint(
            painter: showStripes ? StripedBackgroundPainter() : null,
            child: Center(
              child:
                  status == DateStatus.holiday
                      ? Icon(
                        Icons.celebration,
                        size: cellSize * 0.5,
                        color: textColor,
                      )
                      : Text(
                        '${date.day}',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: textColor,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
            ),
          ),
        ),
      ),
    );

    // Wrap with Tooltip if there's info to show
    if (tooltip != null) {
      cell = Tooltip(message: tooltip, child: cell);
    }

    return cell;
  }

  @override
  Widget build(BuildContext context) {
    final calendarDays = _getCalendarGridDays();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final monthName = DateFormat('MMMM yyyy').format(_currentDate);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.020),
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
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
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
                    size: screenWidth * 0.042,
                    color: AppColors.calendararrow,
                  ),
                  // Legend dots
                  Builder(
                    builder: (dotsContext) {
                      return GestureDetector(
                        onTap: () {
                          // Find the specific RenderBox of the dots to get its exact screen position
                          final RenderBox box =
                              dotsContext.findRenderObject() as RenderBox;
                          // Convert local coordinates to global screen coordinates
                          final Offset offset = box.localToGlobal(Offset.zero);

                          showMenu(
                            context: dotsContext,
                            // Define the exact position: Start at dots' left (dx) and just below dots' bottom (dy + height)
                            position: RelativeRect.fromLTRB(
                              offset.dx,
                              offset.dy + box.size.height,
                              offset.dx + box.size.width,
                              offset.dy,
                            ),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            items: [
                              PopupMenuItem(
                                enabled: false,
                                // Disable interaction as this is only for information
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLegendRow(
                                        dotsContext,
                                        'Present',
                                        AppColors.attendanceTeal,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildLegendRow(
                                        dotsContext,
                                        'Leave',
                                        AppColors.warning,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildLegendRow(
                                        dotsContext,
                                        'Holiday',
                                        AppColors.error,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildLegendRow(
                                        dotsContext,
                                        'WFH',
                                        AppColors.success,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        child: Container(
                          // Transparent color ensures the entire padded area is hit-testable/tappable
                          color: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.01,
                            vertical: screenHeight * 0.019,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            // Prevents the Row from stretching to full screen width
                            children: [
                              _buildDot(AppColors.success),
                              const SizedBox(width: 2),
                              _buildDot(AppColors.warning),
                              const SizedBox(width: 2),
                              _buildDot(AppColors.error),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Navigation arrows
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: Icon(
                      Icons.chevron_left,
                      size: screenWidth * 0.073,
                      color: AppColors.calendararrow,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  // SizedBox(width: screenWidth * 0.01),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: Icon(
                      Icons.chevron_right,
                      size: screenWidth * 0.073,
                      color: AppColors.calendararrow,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Legend
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: AppTextStyles.labelSmall(context).copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          SizedBox(height: screenHeight * 0.015),
          // Loading indicator or calendar grid
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else
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
                if (date == null) return const SizedBox.shrink();
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.015),
        Text(
          label,
          style: AppTextStyles.labelSmall(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

Widget _buildDot(Color color) {
  return Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

Widget _buildLegendRow(BuildContext context, String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: AppTextStyles.labelSmall(
          context,
        ).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w400),
      ),
    ],
  );
}

enum DateStatus {
  otherMonth,
  weekend,
  available,
  present,
  wfh,
  leave,
  absent,
  holiday,
}

/// Custom painter for striped background (diagonal stripes)
class StripedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withOpacity(0.25) // light grey stripes
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

    const stripeSpacing = 5.0;
    final total = size.width + size.height;

    for (double i = -total; i < total; i += stripeSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StripedBackgroundPainter oldDelegate) => false;
}
