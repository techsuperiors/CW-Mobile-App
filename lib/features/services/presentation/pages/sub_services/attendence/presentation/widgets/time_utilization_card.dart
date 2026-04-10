import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/location_permission_helper.dart';
import '../../../../../../../../core/utils/time_utils.dart';
import '../../../../../../../attendance/data/datasources/attendance_offline_local_datasource.dart';
import '../../../../../../../attendance/data/models/offline_attendance_action_model.dart';
import '../../../../../../../attendance/domain/entities/attendance_details.dart';
import '../../../../../../../attendance/presentation/bloc/attendance_punch_bloc.dart';
import '../../../../../../../attendance/presentation/bloc/attendance_punch_event.dart';
import '../../../../../../../attendance/presentation/bloc/attendance_punch_state.dart';

/// Today's Time Utilization card with timer and Punch In button
class TimeUtilizationCard extends StatefulWidget {
  final AttendanceDetails? attendanceDetails;
  final bool isLoading;
  final VoidCallback onRefresh;

  const TimeUtilizationCard({
    super.key,
    this.attendanceDetails,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<TimeUtilizationCard> createState() => _TimeUtilizationCardState();
}

class _TimeUtilizationCardState extends State<TimeUtilizationCard> {
  bool _isPunchingIn = false;
  bool _isPunchingOut = false;
  Timer? _updateTimer;
  bool?
  _localPunchedInOverride; // null = use server data, true/false = override
  DateTime? _virtualPunchInTime; // Fully client-owned, not cleared by server
  double _workedHours = 0.0;
  double? _frozenWorkedHoursOverride;
  final AttendanceOfflineLocalDataSource _offlineLocalDataSource =
      AttendanceOfflineLocalDataSourceImpl();

  /// Check if user is already punched in
  bool get _isPunchedIn {
    if (_localPunchedInOverride != null) return _localPunchedInOverride!;
    return _getServerPunchedIn();
  }

  bool _getServerPunchedIn() {
    return TimeUtils.isActivePunchSession(
      status: widget.attendanceDetails?.status,
      entries: widget.attendanceDetails?.entries,
      punchType: widget.attendanceDetails?.punchType,
      punchIn: widget.attendanceDetails?.punchIn,
      punchOut: widget.attendanceDetails?.punchOut,
    );
  }

  /// Check if status is Holiday
  bool get _isHoliday {
    return widget.attendanceDetails?.status?.toLowerCase() == 'holiday';
  }

  /// Check if it's a week off day (Sunday)
  bool get _isWeekOff {
    if (widget.attendanceDetails?.date == null) return false;
    try {
      final utcDate = DateTime.parse(widget.attendanceDetails!.date!);
      final localDate = utcDate.toLocal();
      return localDate.weekday == 7;
    } catch (e) {
      return false;
    }
  }

  /// Check if punch-in button should be disabled
  bool get _isPunchInDisabled {
    return _isHoliday || _isWeekOff || _isPunchedIn;
  }

  /// Check if the main button should be disabled
  bool get _isButtonDisabled {
    if (widget.isLoading || _isPunchingIn || _isPunchingOut) return true;
    if (_isPunchedIn) return false; // Punch out is enabled when punched in
    return _isHoliday || _isWeekOff;
  }

  /// Get formatted date from UTC date string
  String _getFormattedDate() {
    if (widget.attendanceDetails?.date == null) {
      return DateFormat('d MMMM yyyy').format(DateTime.now());
    }
    try {
      final utcDate = DateTime.parse(widget.attendanceDetails!.date!);
      final localDate = utcDate.toLocal();
      return DateFormat('d MMMM yyyy').format(localDate);
    } catch (e) {
      return DateFormat('d MMMM yyyy').format(DateTime.now());
    }
  }

  @override
  void initState() {
    super.initState();
    _initVirtualPunchInTime();
    _hydratePendingOfflineState();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePunchInTime();
    });
    _updatePunchInTime();
  }

  @override
  void didUpdateWidget(TimeUtilizationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendanceDetails != widget.attendanceDetails) {
      // Only clear override when server confirms our action
      final serverSaysPunchedIn = _getServerPunchedIn();
      if (_localPunchedInOverride != null) {
        if (_localPunchedInOverride == serverSaysPunchedIn) {
          // Server has caught up — safe to trust server now
          _localPunchedInOverride = null;
        }
      }
      if (!serverSaysPunchedIn) {
        _virtualPunchInTime = null;
      }
      if (_localPunchedInOverride == null && _virtualPunchInTime == null) {
        _initVirtualPunchInTime();
      }

      _updatePunchInTime();
      _hydratePendingOfflineState();
    }
  }

  Future<void> _hydratePendingOfflineState() async {
    final actions = await _offlineLocalDataSource.getPendingActions();
    if (!mounted) return;

    setState(() {
      if (actions.isEmpty) {
        if (!_getServerPunchedIn()) {
          _localPunchedInOverride = null;
          _virtualPunchInTime = null;
          _frozenWorkedHoursOverride = null;
        }
        return;
      }

      actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final queueSnapshot = _buildPendingQueueSnapshot(actions);

      if (queueSnapshot.isPunchedIn) {
        _localPunchedInOverride = true;
        _frozenWorkedHoursOverride = null;
        _virtualPunchInTime = queueSnapshot.virtualPunchInTime;
      } else {
        _localPunchedInOverride = false;
        _virtualPunchInTime = null;
        _frozenWorkedHoursOverride = queueSnapshot.frozenWorkedHours;
      }
    });
  }

  void _initVirtualPunchInTime() {
    _virtualPunchInTime = _getServerVirtualPunchInTime();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updatePunchInTime() {
    if (!mounted) return;

    setState(() {
      if (_virtualPunchInTime != null) {
        // Client-owned timer — not affected by server data
        final diff = DateTime.now().difference(_virtualPunchInTime!);
        _workedHours = diff.inSeconds / 3600.0;
      } else if (_frozenWorkedHoursOverride != null) {
        _workedHours = _frozenWorkedHoursOverride!;
      } else {
        // Not punched in locally — use server data
        _workedHours = TimeUtils.getWorkedHours(
          totalTime: widget.attendanceDetails?.totalTime,
          status: widget.attendanceDetails?.status,
          entries: widget.attendanceDetails?.entries,
          punchType: widget.attendanceDetails?.punchType,
          punchIn: widget.attendanceDetails?.punchIn,
          punchOut: widget.attendanceDetails?.punchOut,
          punchInIp: widget.attendanceDetails?.punchInIp,
        );
      }
    });
  }

  int _getPreviousWorkedSeconds() {
    final totalTime = widget.attendanceDetails?.totalTime;
    if (totalTime == null || totalTime.isEmpty || totalTime == '-') return 0;

    try {
      final seconds = int.tryParse(totalTime.trim());
      if (seconds != null) return seconds;
    } catch (e) {
      return 0;
    }
    return 0;
  }

  DateTime? _getServerPunchInDateTime() {
    final punchInStr = widget.attendanceDetails?.punchIn;
    if (punchInStr == null || punchInStr.isEmpty || punchInStr == '-') {
      return null;
    }

    try {
      DateTime punchInDateTime = DateTime.parse(punchInStr);
      if (punchInDateTime.isUtc) {
        punchInDateTime = punchInDateTime.toLocal();
      }
      return punchInDateTime;
    } catch (e) {
      return null;
    }
  }

  DateTime? _getServerVirtualPunchInTime() {
    final serverPunchIn = _getServerPunchInDateTime();
    if (serverPunchIn == null || !_getServerPunchedIn()) return null;
    return serverPunchIn.subtract(Duration(seconds: _getPreviousWorkedSeconds()));
  }

  _PendingQueueSnapshot _buildPendingQueueSnapshot(
    List<OfflineAttendanceActionModel> actions,
  ) {
    var accumulatedSeconds = _getPreviousWorkedSeconds();
    DateTime? activePunchInAt =
        _getServerPunchedIn() ? _getServerPunchInDateTime() : null;

    for (final action in actions) {
      if (action.type == OfflineAttendanceActionType.punchIn) {
        activePunchInAt ??= action.createdAt;
      } else if (activePunchInAt != null) {
        accumulatedSeconds +=
            action.createdAt.difference(activePunchInAt).inSeconds;
        activePunchInAt = null;
      }
    }

    if (activePunchInAt != null) {
      return _PendingQueueSnapshot(
        isPunchedIn: true,
        virtualPunchInTime: activePunchInAt.subtract(
          Duration(seconds: accumulatedSeconds),
        ),
      );
    }

    return _PendingQueueSnapshot(
      isPunchedIn: false,
      frozenWorkedHours: accumulatedSeconds / 3600.0,
    );
  }

  /// Triggers punch in via shared BLoC
  Future<void> _handlePunchIn() async {
    if (_isPunchingIn || _isPunchedIn || _isPunchInDisabled) return;
    final hasPermission = await LocationPermissionHelper.ensureLocationAccess(
      context,
      actionLabel: 'punch in',
    );
    if (!mounted || !hasPermission) return;
    context.read<AttendancePunchBloc>().add(const PunchInRequested());
  }

  /// Triggers punch out via shared BLoC
  Future<void> _handlePunchOut() async {
    if (_isPunchingOut || !_isPunchedIn) return;
    final hasPermission = await LocationPermissionHelper.ensureLocationAccess(
      context,
      actionLabel: 'punch out',
    );
    if (!mounted || !hasPermission) return;
    context.read<AttendancePunchBloc>().add(const PunchOutRequested());
  }

  /// Handles BLoC state changes — updates local state and shows SnackBar
  void _onPunchStateChanged(BuildContext context, AttendancePunchState state) {
    if (state is AttendancePunchLoading) {
      setState(() {
        if (_isPunchedIn) {
          _isPunchingOut = true;
        } else {
          _isPunchingIn = true;
        }
      });
    } else if (state is AttendancePunchInSuccess) {
      if (state.isQueuedOffline) {
        setState(() {
          _isPunchingIn = false;
          _frozenWorkedHoursOverride = null;
        });
        _hydratePendingOfflineState();
        return;
      }
      setState(() {
        _isPunchingIn = false;
        if (state.requiresServerRefresh) {
          _localPunchedInOverride = null;
          _virtualPunchInTime = null;
          _frozenWorkedHoursOverride = null;
        } else {
          final prevSeconds = _getPreviousWorkedSeconds();
          _localPunchedInOverride = true;
          _frozenWorkedHoursOverride = null;
          _virtualPunchInTime = state.punchInTime.subtract(
            Duration(seconds: prevSeconds),
          );
        }
      });
      if (!state.isQueuedOffline || state.requiresServerRefresh) {
        widget.onRefresh();
      }
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         AttendancePunchReconciliationHelper.toUserMessage(state.message),
      //       ),
      //       backgroundColor: AppColors.success,
      //     ),
      //   );
      // }
    } else if (state is AttendancePunchOutSuccess) {
      if (state.isQueuedOffline) {
        setState(() {
          _isPunchingOut = false;
        });
        _hydratePendingOfflineState();
        return;
      }
      final frozenWorkedHours =
          _virtualPunchInTime != null
              ? DateTime.now().difference(_virtualPunchInTime!).inSeconds /
                  3600.0
              : _workedHours;
      setState(() {
        _isPunchingOut = false;
        _localPunchedInOverride = state.requiresServerRefresh ? null : false;
        _virtualPunchInTime = null;
        _frozenWorkedHoursOverride = frozenWorkedHours;
      });
      if (!state.isQueuedOffline || state.requiresServerRefresh) {
        widget.onRefresh();
      }
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         AttendancePunchReconciliationHelper.toUserMessage(state.message),
      //       ),
      //       backgroundColor: AppColors.success,
      //     ),
      //   );
      // }
    } else if (state is AttendancePunchError) {
      setState(() {
        _isPunchingIn = false;
        _isPunchingOut = false;
        _localPunchedInOverride = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else if (state is AttendancePendingSyncSuccess) {
      setState(() {
        _isPunchingIn = false;
        _isPunchingOut = false;
        _localPunchedInOverride = null;
      });
      _hydratePendingOfflineState();
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get formatted date from API (UTC to local)
    final formattedDate = _getFormattedDate();

    // Get time components - show elapsed time if punched in
    final totalSeconds = (_workedHours * 3600).round();
    final String hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final String minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final String seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    return BlocListener<AttendancePunchBloc, AttendancePunchState>(
      listener: _onPunchStateChanged,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.0020),
        padding: EdgeInsets.all(screenWidth * 0.042),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  "Today's \nTime Utilization",
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.010),
                // Date with Holiday badge inline
                Row(
                  children: [
                    Text(
                      formattedDate,
                      style: AppTextStyles.heading5(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // Show Holiday status badge inline
                    if (_isHoliday) ...[
                      SizedBox(width: screenWidth * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenHeight * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.6),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Holiday',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // SizedBox(height: screenHeight * 0.02),
              ],
            ),
            // Timer and Punch In button row
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timer boxes (HH MM SS)
                widget.isLoading
                    ? Row(
                      children: [
                        _buildTimeBox(context, '00'),
                        SizedBox(width: screenWidth * 0.02),
                        _buildTimeBox(context, '00'),
                        SizedBox(width: screenWidth * 0.02),
                        _buildTimeBox(context, '00'),
                      ],
                    )
                    : Row(
                      children: [
                        Column(
                          children: [
                            _buildTimeBox(context, hours),
                            Text(
                              "HH",
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Column(
                          children: [
                            _buildTimeBox(context, minutes),
                            Text(
                              "MM",
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Column(
                          children: [
                            _buildTimeBox(context, seconds),
                            Text(
                              "SS",
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                SizedBox(height: screenHeight * 0.008),
                // Punch In/Out button
                ElevatedButton(
                  onPressed:
                      _isButtonDisabled
                          ? null
                          : _isPunchedIn
                          ? _handlePunchOut
                          : _handlePunchIn,
                  style: ElevatedButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        _isButtonDisabled
                            ? AppColors.textSecondary.withOpacity(0.3)
                            : AppColors.attendanceTeal,
                    foregroundColor: AppColors.textWhite,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.textSecondary
                        .withOpacity(0.3),
                    disabledForegroundColor: AppColors.textWhite.withOpacity(
                      0.6,
                    ),
                  ),
                  child:
                      (_isPunchingIn || _isPunchingOut)
                          ? SizedBox(
                            width: screenWidth * 0.04,
                            height: screenWidth * 0.04,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textWhite,
                              ),
                            ),
                          )
                          : Text(
                            _isPunchedIn
                                ? AppStrings.punchOut
                                : AppStrings.punchIn,
                            style: AppTextStyles.heading5(context).copyWith(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBox(BuildContext context, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.08,
      height: screenHeight * 0.04,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Center(
        child: Text(
          value,
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _PendingQueueSnapshot {
  final bool isPunchedIn;
  final DateTime? virtualPunchInTime;
  final double? frozenWorkedHours;

  const _PendingQueueSnapshot({
    required this.isPunchedIn,
    this.virtualPunchInTime,
    this.frozenWorkedHours,
  });
}
