/// Utility functions for time parsing and calculations
class TimeUtils {
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
      final minutes = int.tryParse(timeString.trim());
      if (minutes != null) {
        return minutes / 60.0;
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
      return difference.inMinutes / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get worked hours from attendance details
  /// If punched in but not out, calculates from punch in time to now
  /// If punched out, uses totalTime
  static double getWorkedHours({
    String? totalTime,
    String? punchIn,
    String? punchOut,
    String? punchInIp,
  }) {
    // Check if punched out
    final isPunchedOut = punchOut != null && 
        punchOut.isNotEmpty && 
        punchOut != '-';
    
    // Check if punched in - use punchIn as primary indicator (user has punch-in time, no punch-out)
    // punchInIp is optional - API may use punch_in_IP or punch_in_ip
    final hasPunchInIp = punchInIp != null && 
        punchInIp.isNotEmpty && 
        punchInIp != '-';
    final hasPunchIn = punchIn != null && 
        punchIn.isNotEmpty && 
        punchIn != '-';
    final isPunchedIn = (hasPunchInIp || hasPunchIn) && !isPunchedOut;

    // If punched out, use totalTime (if available)
    if (isPunchedOut) {
      final totalHours = parseTimeToHours(totalTime);
      // If totalTime is available and valid, use it
      if (totalHours > 0) {
        return totalHours;
      }
      // Otherwise, calculate from punch in to punch out
      if (punchIn != null && punchIn.isNotEmpty && punchIn != '-') {
        try {
          final punchInDateTime = DateTime.parse(punchIn);
          final punchOutDateTime = DateTime.parse(punchOut);
          final difference = punchOutDateTime.difference(punchInDateTime);
          return difference.inMinutes / 60.0;
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    // If punched in but not out, calculate from punch in time to now
    if (isPunchedIn && punchIn != null && punchIn.isNotEmpty && punchIn != '-') {
      return calculateWorkedHoursFromPunchIn(punchIn);
    }

    // Fallback to totalTime if available
    return parseTimeToHours(totalTime);
  }
}
