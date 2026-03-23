/// Utility functions for time parsing and calculations
class TimeUtils {
  static bool isActivePunchSession({
    String? status,
    String? entries,
    String? punchType,
    String? punchIn,
    String? punchOut,
  }) {
    final normalizedStatus = status?.toLowerCase().trim();
    final normalizedEntries = entries?.toLowerCase().trim();
    final normalizedPunchType = punchType?.toLowerCase().trim();

    // Ignore system-generated weekend/holiday rows that do not represent
    // a real user punch session.
    if ((normalizedStatus == 'weekend' || normalizedStatus == 'holiday') &&
        (normalizedEntries == 'system' ||
            normalizedPunchType == null ||
            normalizedPunchType.isEmpty)) {
      return false;
    }

    final hasPunchIn = punchIn != null && punchIn.isNotEmpty && punchIn != '-';
    if (!hasPunchIn) return false;

    final hasPunchOut =
        punchOut != null && punchOut.isNotEmpty && punchOut != '-';

    if (!hasPunchOut) return true;

    try {
      final inTime = DateTime.parse(punchIn);
      final outTime = DateTime.parse(punchOut);
      return inTime.isAfter(outTime);
    } catch (_) {
      return false;
    }
  }

  /// Parse time string to hours (double)
  /// Supports formats: "HH:MM", "H:MM", "MM" (minutes), "H" (hours)
  /// Returns hours as double (e.g., 7.5 for 7 hours 30 minutes)
  static double parseTimeToHours(String? timeString) {
    if (timeString == null || timeString.isEmpty || timeString == '-') {
      return 0.0;
    }

    try {
      // Try parsing as "HH:MM" or "H:MM" format
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length == 2) {
          final hours = int.tryParse(parts[0].trim()) ?? 0;
          final minutes = int.tryParse(parts[1].trim()) ?? 0;
          return hours + (minutes / 60.0);
        }
      }

      // Try parsing as minutes (integer)
      final seconds = int.tryParse(timeString.trim());
      if (seconds != null) {
        return seconds / 3600.0;
      }
      // Try parsing as hours (double)
      final hours = double.tryParse(timeString.trim());
      if (hours != null) {
        return hours;
      }
    } catch (e) {
      // If parsing fails, return 0
      return 0.0;
    }

    return 0.0;
  }

  /// Calculate worked hours from punch in time to now
  /// Returns hours as double
  static double calculateWorkedHoursFromPunchIn(String? punchInTime) {
    if (punchInTime == null || punchInTime.isEmpty || punchInTime == '-') {
      return 0.0;
    }

    try {
      // Parse punch in time (ISO format or similar)
      final punchInDateTime = DateTime.parse(punchInTime);
      final now = DateTime.now();
      final difference = now.difference(punchInDateTime);
      return difference.inSeconds / 3600.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get worked hours from attendance details
  /// If punched in but not out, calculates from punch in time to now
  /// If punched out, uses totalTime
  static double getWorkedHours(
      {
        String? totalTime,
        String? status,
        String? entries,
        String? punchType,
        String? punchIn,
        String? punchOut,
        String? punchInIp,
      })
  {
    final hasPunchOut = punchOut != null && punchOut.isNotEmpty && punchOut != '-';

    final hasPunchIn = punchIn != null && punchIn.isNotEmpty && punchIn != '-';
    final isPunchedIn = isActivePunchSession(
      status: status,
      entries: entries,
      punchType: punchType,
      punchIn: punchIn,
      punchOut: punchOut,
    );

    if (isPunchedIn && hasPunchIn) {
      // Live calculation from punch in to now
      return calculateWorkedHoursFromPunchIn(punchIn);
    }

    if (!isPunchedIn && hasPunchOut) {
      // Prefer totalTime (now correctly parsed as seconds)
      final totalHours = parseTimeToHours(totalTime);
      if (totalHours > 0) return totalHours;

      // Fallback: calculate from punchIn to punchOut
      if (hasPunchIn) {
        try {
          final inTime = DateTime.parse(punchIn);
          final outTime = DateTime.parse(punchOut);
          return outTime.difference(inTime).inSeconds / 3600.0;
        } catch (_) {}
      }
    }

    return parseTimeToHours(totalTime);
  }
}
