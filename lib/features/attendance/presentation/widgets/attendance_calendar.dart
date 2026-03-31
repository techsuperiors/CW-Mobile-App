import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_section_header.dart';
import '../../../calendar/domain/entities/calendar_day_entity.dart';

/// Colour-coded circular attendance calendar.
class AttendanceCalendar extends StatefulWidget {
  final List<CalendarDayEntity> calendarDays;
  final Function(DateTime newMonth)? onMonthChanged;
  final bool isLoading;

  const AttendanceCalendar({
    super.key,
    this.calendarDays = const [],
    this.onMonthChanged,
    this.isLoading = false,
  });

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  late DateTime _currentDate;
  static const Color _shortLeaveColor = Color(0xFFFFE38E);
  static const Color _halfDayLeaveColor = Color(0xFFFFC94D);

  static const _headers = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime(DateTime.now().year, DateTime.now().month);
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

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  CalendarDayEntity? _findDay(DateTime date) {
    final key = _dateKey(date);
    try {
      return widget.calendarDays.firstWhere((d) => d.date == key);
    } catch (_) {
      return null;
    }
  }

  bool _isCurrentMonth(DateTime d) =>
      d.year == _currentDate.year && d.month == _currentDate.month;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isWeekend(DateTime d) => d.weekday == 6 || d.weekday == 7;

  List<DateTime?> _buildGrid() {
    final first = DateTime(_currentDate.year, _currentDate.month, 1);
    final last = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final startOffset = first.weekday % 7; // 0 = Sunday

    final grid = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) {
      grid.add(first.subtract(Duration(days: startOffset - i)));
    }
    for (int d = 1; d <= last.day; d++) {
      grid.add(DateTime(_currentDate.year, _currentDate.month, d));
    }
    while (grid.length < 35) {
      grid.add(
        DateTime(
          _currentDate.year,
          _currentDate.month + 1,
          grid.length - last.day - startOffset + 1,
        ),
      );
    }
    return grid;
  }

  // ─── Style logic ─────────────────────────────────────────────────────────────

  _DayStyle _getStyle(DateTime date) {
    final isCurrent = _isCurrentMonth(date);
    final isToday = _isToday(date);

    if (!isCurrent) {
      return _DayStyle(
        circleColor: AppColors.border.withOpacity(0.35),
        textColor: AppColors.textSecondary.withOpacity(0.45),
        showCircle: true,
        label: null,
        isHoliday: false,
        isWeekend: false,
        isLate: false,
      );
    }

    final day = _findDay(date);
    final isWeekoff = _isWeekend(date) || day?.isWeekoff == true;

    if (isWeekoff) {
      // Override 1: Holiday on a weekoff day
      if (day?.isHoliday == true) {
        return _DayStyle(
          circleColor: const Color(0xFFFF6B6B),
          textColor: Colors.white,
          showCircle: true,
          label: null,
          isHoliday: true,
          holidayName: day?.holidayName,
          isWeekend: false,
          isLate: false,
        );
      }
      // Override 2: User came in on weekoff (Present)
      if (day?.status == 'Present') {
        return _DayStyle(
          circleColor: const Color(0xFF0B7F7F),
          textColor: Colors.white,
          showCircle: true,
          label: day!.isLateEntry ? 'Late' : null,
          isHoliday: false,
          isWeekend: false,
          isLate: day.isLateEntry,
        );
      }
      // Override 3: WFH on weekoff
      if (day?.status == 'WFH') {
        return _DayStyle(
          circleColor: const Color(0xFF27AE60),
          textColor: Colors.white,
          showCircle: true,
          label: 'WFH',
          isHoliday: false,
          isWeekend: false,
          isLate: day!.isLateEntry,
        );
      }
      // Default weekoff: diagonal stripes
      return _DayStyle(
        circleColor: Colors.transparent,
        textColor: AppColors.textSecondary,
        showCircle: false,
        label: null,
        isHoliday: false,
        isWeekend: true,
        // triggers stripe painter
        isLate: false,
      );
    }

    // ── Regular weekday ──────────────────────────────────────────────────────

    // Today with no API data
    if (isToday && day == null) {
      return _DayStyle(
        circleColor: const Color(0xFFE74C3C),
        textColor: Colors.white,
        showCircle: true,
        label: null,
        isHoliday: false,
        isWeekend: false,
        isLate: false,
      );
    }

    if (day == null) {
      // No data at all — gray circle
      return _DayStyle(
        circleColor:
            isToday
                ? const Color(0xFFE74C3C)
                : AppColors.border.withOpacity(0.35),
        textColor: isToday ? Colors.white : AppColors.textSecondary,
        showCircle: true,
        label: null,
        isHoliday: false,
        isWeekend: false,
        isLate: false,
      );
    }

    // PRIORITY 1: Holiday (show even if isFuture=true — the API marks future holidays too)
    if (day.isHoliday) {
      return _DayStyle(
        circleColor: const Color(0xFFFF6B6B),
        textColor: Colors.white,
        showCircle: true,
        label: null,
        isHoliday: true,
        holidayName: day.holidayName,
        isWeekend: false,
        isLate: false,
      );
    }
    // PRIORITY 2: Status (show even if isFuture=true — covers pre-planned WFH/Leave)
    switch (day.status) {
      case 'Present':
        return _DayStyle(
          circleColor: const Color(0xFF0B7F7F),
          textColor: Colors.white,
          showCircle: true,
          label: day.isLateEntry ? 'Late' : null,
          isHoliday: false,
          isWeekend: false,
          isLate: day.isLateEntry,
        );
      case 'WFH':
        return _DayStyle(
          circleColor: const Color(0xFF27AE60),
          textColor: Colors.white,
          showCircle: true,
          label: 'WFH',
          isHoliday: false,
          isWeekend: false,
          isLate: day.isLateEntry,
        );
      case 'Leave':
        return _DayStyle(
          circleColor: const Color(0xFFFF8C00),
          textColor: Colors.white,
          showCircle: true,
          label: day.leaveType ?? 'Leave',
          isHoliday: false,
          isWeekend: false,
          isLate: false,
        );
      case 'Short Leave':
        return _DayStyle(
          circleColor: _shortLeaveColor,
          textColor: Colors.white,
          showCircle: true,
          label: 'Short Leave',
          isHoliday: false,
          isWeekend: false,
          isLate: false,
        );
      case 'Half Day Leave':
        return _DayStyle(
          circleColor: _halfDayLeaveColor,
          textColor: Colors.white,
          showCircle: true,
          label: 'Half Day Leave',
          isHoliday: false,
          isWeekend: false,
          isLate: false,
        );
      case 'Absent':
        return _DayStyle(
          circleColor: const Color(0xFFE74C3C),
          textColor: Colors.white,
          showCircle: true,
          label: null,
          isHoliday: false,
          isWeekend: false,
          isLate: false,
        );
      case 'Holiday':
        return _DayStyle(
          circleColor: const Color(0xFFFF6B6B),
          textColor: Colors.white,
          showCircle: true,
          label: null,
          isHoliday: true,
          holidayName: day.holidayName,
          isWeekend: false,
          isLate: false,
        );
    }

    // PRIORITY 3: isFuture with no meaningful status — gray
    return _DayStyle(
      circleColor:
          isToday
              ? const Color(0xFFE74C3C)
              : AppColors.border.withOpacity(0.35),
      textColor: isToday ? Colors.white : AppColors.textSecondary,
      showCircle: true,
      label: null,
      isHoliday: false,
      isWeekend: false,
      isLate: false,
    );
  }

  // ─── Cell builder ─────────────────────────────────────────────────────────────

  Widget _buildCell(
    BuildContext context,
    DateTime? date,
    double cellW,
    double cellH,
  ) {
    if (date == null) return SizedBox(width: cellW, height: cellH);

    final style = _getStyle(date);
    // Circle is 75% of cell width, capped for readability
    final circleD = (cellW * 0.75).clamp(28.0, 46.0);
    final fontSize = (circleD * 0.36).clamp(9.0, 15.0);
    final labelFontSize = (circleD * 0.25).clamp(7.0, 10.0);

    return SizedBox(
      width: cellW,
      height: cellH,
      child: Stack(
        children: [
          // Weekend stripe background
          if (style.isWeekend)
            Positioned.fill(
              child: ClipRect(child: CustomPaint(painter: _StripePainter())),
            ),

          // Circle + label, centered
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circle
                Container(
                  width: circleD,
                  height: circleD,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        style.showCircle
                            ? style.isHoliday
                                ? AppColors.error.withOpacity(0.6)
                                : style.circleColor
                            : Colors.transparent,
                  ),
                  child: Center(
                    child:
                        style.isHoliday
                            ? Text(
                              '🎉',
                              style: TextStyle(fontSize: circleD * 0.42),
                            )
                            : Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                color: style.textColor,
                              ),
                            ),
                  ),
                ),

                // Label pill (WFH / Leave type / Late) below circle **imp don't remove this
                /*
                if (style.label != null)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _labelBg(style.label!),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      style.label!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                */
              ],
            ),
          ),

          // Late-entry clock badge (top-left)
          if (style.isLate && !style.isHoliday)
            Positioned(
              top: cellH * 0.04,
              left: cellW * 0.08,
              child: SvgPicture.asset(AppAssets.iconaLatePunchIn),
            ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final grid = _buildGrid();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available width so it's fully responsive on any screen
        final availableW = constraints.maxWidth;
        final avaialbeH = constraints.maxHeight;
        final cellW = availableW / 8;
        // Cell height slightly taller than wide to accommodate label pill
        final cellH = cellW * 1.18;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background, // 👈 your background
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: availableW * 0.03),

              // Month navigation — shows: < Feb 2026 | March 2026 | Apr 2026 >
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: availableW * 0.008),

                  // ← Prev arrow + prev month name
                  GestureDetector(
                    onTap: _previousMonth,
                    child: Icon(
                      Icons.chevron_left,
                      color: AppColors.calendararrow,
                      size: availableW * 0.08,
                    ),
                  ),
                  Text(
                    DateFormat('MMM yyyy').format(
                      DateTime(_currentDate.year, _currentDate.month - 1),
                    ),
                    style: TextStyle(
                      fontSize: (availableW * 0.030).clamp(10, 13),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Current month (center, bold)
                  Text(
                    DateFormat('MMMM yyyy').format(_currentDate),
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  Text(
                    DateFormat('MMM yyyy').format(
                      DateTime(_currentDate.year, _currentDate.month + 1),
                    ),
                    style: TextStyle(
                      fontSize: (availableW * 0.030).clamp(10, 13),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Next month name + → arrow
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColors.calendararrow,
                      size: availableW * 0.08,
                    ),
                  ),
                  SizedBox(width: availableW * 0.008),
                ],
              ),

              SizedBox(height: availableW * 0.03),

              // Day-of-week headers
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    _headers.map((h) {
                      return SizedBox(
                        width: cellW,
                        child: Center(
                          child: Text(
                            h,
                            style: TextStyle(
                              fontSize: (cellW * 0.22).clamp(8, 12),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),

              SizedBox(height: availableW * 0.03),

              // Calendar grid
              if (widget.isLoading)
                SizedBox(
                  height: cellH * 5,
                  child: const Center(child: CircularProgressIndicator()),
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(grid.length ~/ 7, (row) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(7, (col) {
                        return _buildCell(
                          context,
                          grid[row * 7 + col],
                          cellW,
                          cellH,
                        );
                      }),
                    );
                  }),
                ),

              SizedBox(height: availableW * 0.08),

              // Legend
              Wrap(
                spacing: availableW * 0.04,
                runSpacing:16,
                alignment: WrapAlignment.center,
                children: [
                  _legend('Present', const Color(0xFF0B7F7F)),
                  _legend('WFH', const Color(0xFF27AE60)),
                  _legend('Leave', const Color(0xFFFF8C00)),
                  _legend('Absent', const Color(0xFFE74C3C)),
                  _legend('Short Leave', _shortLeaveColor),
                  _legend('Half Day Leave', _halfDayLeaveColor),
                  _legend('Holiday', const Color(0xFFFF6B6B)),
                  _legend(
                    'Late',
                    const Color(0xFFFF6B6B),
                    AppAssets.iconaLatePunchIn,
                  ),
                ],
              ),
              SizedBox(height: availableW * 0.04),
              // Wrap(
              //   spacing: availableW * 0.04,
              //   runSpacing: 4,
              //   children: [
              //     _legend('Holiday', const Color(0xFFFF6B6B)),
              //     _legend(
              //       'Late',
              //       const Color(0xFFFF6B6B),
              //       AppAssets.iconaLatePunchIn,
              //     ),
              //   ],
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _legend(String label, Color color, [String? iconpath]) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconpath != null)
          SvgPicture.asset(iconpath)
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _DayStyle {
  final Color circleColor;
  final Color textColor;
  final bool showCircle;
  final String? label;
  final bool isHoliday;
  final String? holidayName;
  final bool isWeekend;
  final bool isLate;

  const _DayStyle({
    required this.circleColor,
    required this.textColor,
    required this.showCircle,
    required this.label,
    required this.isHoliday,
    this.holidayName,
    required this.isWeekend,
    required this.isLate,
  });
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.withOpacity(0.13)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    const spacing = 6.0;
    final total = size.width + size.height;
    for (double i = -total; i < total; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}
