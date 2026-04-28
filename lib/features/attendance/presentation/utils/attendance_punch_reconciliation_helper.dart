import '../../../../core/utils/time_utils.dart';
import '../../data/models/offline_attendance_action_model.dart';
import '../../domain/entities/attendance_details.dart';

class AttendancePunchReconciliationHelper {
  const AttendancePunchReconciliationHelper._();

  static bool requiresPunchInReconciliation(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already') && normalized.contains('in');
  }

  static bool requiresPunchOutReconciliation(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already') && normalized.contains('out');
  }

  static String toUserMessage(String message) {
    final normalized = message.toLowerCase();
    if (requiresPunchInReconciliation(message)) {
      return 'Already punched in from another device. Syncing latest session...';
    }
    if (requiresPunchOutReconciliation(message)) {
      return 'Already punched out from another device. Syncing latest session...';
    }
    if (normalized.contains('network') || normalized.contains('connection')) {
      return 'Network issue. Please check your connection.';
    }
    if (normalized.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return message;
  }
}

class AttendanceSessionStateHelper {
  const AttendanceSessionStateHelper._();

  static bool isActiveSession(AttendanceDetails? attendanceDetails) {
    if (attendanceDetails == null) return false;

    final activityResolvedState = _resolveFromRecentRealPunchActivity(
      attendanceDetails.activity,
    );
    if (activityResolvedState != null) {
      return activityResolvedState;
    }

    return TimeUtils.isActivePunchSession(
      status: attendanceDetails.status,
      entries: attendanceDetails.entries,
      punchType: attendanceDetails.punchType,
      punchIn: attendanceDetails.punchIn,
      punchOut: attendanceDetails.punchOut,
    );
  }

  static bool? _resolveFromRecentRealPunchActivity(List<Activity>? activities) {
    if (activities == null || activities.isEmpty) {
      return null;
    }

    final indexedActivities =
        activities.asMap().entries.toList()..sort((left, right) {
          final leftTimestamp = _parseActivityTimestamp(left.value);
          final rightTimestamp = _parseActivityTimestamp(right.value);

          if (leftTimestamp == null && rightTimestamp == null) {
            return left.key.compareTo(right.key);
          }
          if (leftTimestamp == null) return -1;
          if (rightTimestamp == null) return 1;
          return leftTimestamp.compareTo(rightTimestamp);
        });

    for (final entry in indexedActivities.reversed) {
      final normalizedType = entry.value.activityType?.trim().toLowerCase();
      if (normalizedType == 'punch in') {
        return true;
      }
      if (normalizedType == 'punch out') {
        return false;
      }
    }

    return null;
  }

  static DateTime? _parseActivityTimestamp(Activity activity) {
    final rawValue = activity.createdAt?.trim().isNotEmpty == true
        ? activity.createdAt
        : activity.time;
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawValue.trim())?.toUtc();
  }
}

class PendingAttendanceUiState {
  final bool? localPunchedInOverride;
  final DateTime? virtualPunchInTime;
  final double? frozenWorkedHoursOverride;

  const PendingAttendanceUiState({
    required this.localPunchedInOverride,
    required this.virtualPunchInTime,
    required this.frozenWorkedHoursOverride,
  });
}

class PendingAttendanceSessionHelper {
  const PendingAttendanceSessionHelper._();

  static PendingAttendanceUiState resolve({
    required List<OfflineAttendanceActionModel> actions,
    required bool serverPunchedIn,
    DateTime? serverVirtualPunchInTime,
    required int baseWorkedSeconds,
    DateTime? referenceTime,
  }) {
    final effectiveReferenceTime = referenceTime ?? DateTime.now();
    final currentDayActions =
        actions
            .where((action) => action.isForSameLocalDay(effectiveReferenceTime))
            .toList();

    if (currentDayActions.isEmpty) {
      return PendingAttendanceUiState(
        localPunchedInOverride: null,
        virtualPunchInTime: serverPunchedIn ? serverVirtualPunchInTime : null,
        frozenWorkedHoursOverride: null,
      );
    }

    final sortedActions = [...currentDayActions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    var isPunchedIn = serverPunchedIn;
    var accumulatedWorkedSeconds = baseWorkedSeconds;
    DateTime? virtualPunchInTime =
        serverPunchedIn ? serverVirtualPunchInTime : null;

    for (final action in sortedActions) {
      if (action.type == OfflineAttendanceActionType.punchIn) {
        virtualPunchInTime ??= action.createdAt.subtract(
          Duration(seconds: accumulatedWorkedSeconds),
        );
        isPunchedIn = true;
        continue;
      }

      if (virtualPunchInTime != null) {
        final durationInSeconds = action.createdAt
            .difference(virtualPunchInTime)
            .inSeconds;
        accumulatedWorkedSeconds =
            durationInSeconds.isNegative ? 0 : durationInSeconds;
      }

      virtualPunchInTime = null;
      isPunchedIn = false;
    }

    if (isPunchedIn && virtualPunchInTime != null) {
      return PendingAttendanceUiState(
        localPunchedInOverride: true,
        virtualPunchInTime: virtualPunchInTime,
        frozenWorkedHoursOverride: null,
      );
    }

    return PendingAttendanceUiState(
      localPunchedInOverride: false,
      virtualPunchInTime: null,
      frozenWorkedHoursOverride: accumulatedWorkedSeconds / 3600.0,
    );
  }
}
