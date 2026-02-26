import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/attendance_header.dart';
import '../widgets/attendance_card.dart';
import '../widgets/punch_details.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/leaves_summary.dart';
import '../widgets/quick_links.dart';
import '../widgets/upcoming_events.dart';
import '../widgets/attendance_calendar.dart';

/// Attendance page matching the design
class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    
    // Responsive spacing helper
    double responsiveSpacing(double baseSpacing) {
      if (screenHeight < 600) {
        return baseSpacing * 0.75;
      } else if (screenHeight < 700) {
        return baseSpacing * 0.85;
      }
      return baseSpacing;
    }
    
    return ResponsiveScaffold(
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with profile
            const AttendanceHeader(),
            // Attendance Card (overlaps header by 20px, so no spacing needed)
            const AttendanceCard(),
            // Punch Details
            const PunchDetails(),
            SizedBox(height: responsiveSpacing(10)),
            // Attendance Summary
            const AttendanceSummary(),
            SizedBox(height: responsiveSpacing(10)),
            // // Leaves Summary
            const LeavesSummary(),
            SizedBox(height: responsiveSpacing(10)),
            // Upcoming Events
            const UpcomingEvents(),
            SizedBox(height: responsiveSpacing(10)),
            // // Quick Links
            const QuickLinks(),
            SizedBox(height: responsiveSpacing(10)),
            // // Calendar
            const AttendanceCalendar(),
            SizedBox(height: responsiveSpacing(24)),
          ],
        ),
      ),
    );
  }
}

