import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/location_permission_helper.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/attendance_timer_circle.dart';
import '../../data/datasources/attendance_offline_local_datasource.dart';
import '../../data/models/offline_attendance_action_model.dart';
import '../../domain/entities/attendance_details.dart';
import '../bloc/attendance_punch_bloc.dart';
import '../bloc/attendance_punch_event.dart';
import '../bloc/attendance_punch_state.dart';
import '../utils/attendance_punch_reconciliation_helper.dart';

// Helper function to get gradient alignment for CSS angle (111.14°)
// CSS: 0° = right, clockwise. The gradient line goes in this direction
List<Alignment> _getGradientAlignment(double angleDegrees) {
  // Convert CSS angle to radians
  final angleRad = angleDegrees * math.pi / 180;

  // Calculate the direction vector for the gradient line
  final dx = math.cos(angleRad);
  final dy = math.sin(angleRad);

  // Calculate perpendicular direction (90° rotation)
  final perpDx = -dy;
  final perpDy = dx;

  return [
    Alignment(perpDx, -perpDy), // Begin
    Alignment(-perpDx, perpDy), // End
  ];
}

/// Large attendance card with date, time, progress, and punch in/out button
class AttendanceCard extends StatefulWidget {
  final AttendanceDetails? attendanceDetails;
  final bool isLoading;
  final VoidCallback onRefresh;

  const AttendanceCard({
    super.key,
    this.attendanceDetails,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  bool _isPunchingIn = false;
  bool _isPunchingOut = false;
  Timer? _updateTimer;
  double _workedHours = 0.0;
  double _shiftHours = 8.0; // Default shift hours
  double? _frozenWorkedHoursOverride;
  bool?
  _localPunchedInOverride; // null = use server data, true/false = override
  final AttendanceOfflineLocalDataSource _offlineLocalDataSource =
      AttendanceOfflineLocalDataSourceImpl();

  /// Check if user is already punched in
  /// Uses punchIn as primary indicator (has punch-in time, no punch-out)
  /// punchInIp is optional - API may not always return it
  bool get _isPunchedIn {
    if (_localPunchedInOverride != null) return _localPunchedInOverride!;
    return _getServerPunchedIn();
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
    if (_isPunchedIn) return false;
    return _isHoliday || _isWeekOff;
  }

  /// Get formatted date from UTC date string
  String _getFormattedDate() {
    if (widget.attendanceDetails?.date == null) {
      return DateFormat('dd MMM, yyyy').format(DateTime.now());
    }
    try {
      final utcDate = DateTime.parse(widget.attendanceDetails!.date!);
      final localDate = utcDate.toLocal();
      return DateFormat('dd MMM, yyyy').format(localDate);
    } catch (e) {
      return DateFormat('dd MMM, yyyy').format(DateTime.now());
    }
  }

  DateTime? _virtualPunchInTime; // Fully client-owned, not cleared by server

  @override
  void initState() {
    super.initState();
    _initVirtualPunchInTime();
    _hydratePendingOfflineState();

    // Update timer every second to refresh worked hours when punched in
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateWorkedHours();
    });
    _updateWorkedHours();
  }

  void _initVirtualPunchInTime() {
    _virtualPunchInTime = _getServerVirtualPunchInTime();
  }

  @override
  void didUpdateWidget(AttendanceCard oldWidget) {
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
        _virtualPunchInTime = null; // ← client timer clear karo
      }
      // If no local override and virtualPunchInTime is null but server says punched in
      // — initialize it (handles screen navigation case)
      if (_localPunchedInOverride == null && _virtualPunchInTime == null) {
        _initVirtualPunchInTime();
      }

      _updateWorkedHours();
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

  bool _getServerPunchedIn() {
    return TimeUtils.isActivePunchSession(
      status: widget.attendanceDetails?.status,
      entries: widget.attendanceDetails?.entries,
      punchType: widget.attendanceDetails?.punchType,
      punchIn: widget.attendanceDetails?.punchIn,
      punchOut: widget.attendanceDetails?.punchOut,
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateWorkedHours() {
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
      // totalTime is in seconds from API
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
      // widget.onRefresh();
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
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.sync, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AttendancePunchReconciliationHelper.toUserMessage(
                      state.message,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
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
    final dateStr = _getFormattedDate();
    final now = DateTime.now();
    final dayTimeStr = DateFormat('EEEE, hh:mm a').format(now);

    return BlocListener<AttendancePunchBloc, AttendancePunchState>(
      listener: _onPunchStateChanged,
      child: Transform.translate(
        offset: const Offset(0, -12), // Overlap header slightly
        child: Container(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.053,
            MediaQuery.of(context).size.height * 0.0125,
            MediaQuery.of(context).size.width * 0.053,
            MediaQuery.of(context).size.height * 0.015,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _getGradientAlignment(111.14)[0],
              end: _getGradientAlignment(111.14)[1],
              stops: const [0.0, 0.1, 0.8676],
              colors: [
                AppColors.attendanceTealLight,
                AppColors.attendanceTealLight,
                AppColors.background,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              // Left side - Date, time, and button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date
                    Text(
                      dateStr,
                      style: AppTextStyles.heading4(
                        context,
                      ).copyWith(color: AppColors.textWhite, height: 1.2),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.0085,
                    ),
                    // Day and time
                    Text(
                      dayTimeStr,
                      style: AppTextStyles.labelMedium(context).copyWith(
                        color: AppColors.textWhite,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // Show Holiday status badge
                    if (_isHoliday) ...[
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.008,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.025,
                          vertical: MediaQuery.of(context).size.height * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event, size: 12, color: AppColors.error),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01,
                            ),
                            Text(
                              'Holiday',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    // Punch In/Out button
                    ElevatedButton(
                      onPressed:
                          _isButtonDisabled
                              ? null
                              : _isPunchedIn
                              ? _handlePunchOut
                              : _handlePunchIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isButtonDisabled
                                ? AppColors.textSecondary.withOpacity(0.2)
                                : AppColors.background,
                        foregroundColor:
                            _isButtonDisabled
                                ? AppColors.textSecondary.withOpacity(0.7)
                                : AppColors.textPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.053,
                          vertical: MediaQuery.of(context).size.height * 0.0105,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color:
                                _isButtonDisabled
                                    ? AppColors.textSecondary.withOpacity(0.3)
                                    : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: AppColors.textSecondary
                            .withOpacity(0.2),
                        disabledForegroundColor: AppColors.textSecondary
                            .withOpacity(0.7),
                      ),

                      child:
                          (widget.isLoading || _isPunchingIn || _isPunchingOut)
                              ? SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.037,
                                height:
                                    MediaQuery.of(context).size.width * 0.037,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textWhite,
                                  ),
                                ),
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.080,
                                    height:
                                        MediaQuery.of(context).size.width *
                                        0.070,

                                    child: SvgPicture.asset(
                                      !_isPunchedIn
                                          ? AppAssets.iconPunchIn
                                          : AppAssets.iconPunchOut,
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.0371,
                                  ),
                                  Text(
                                    _isPunchedIn
                                        ? AppStrings.punchOut
                                        : AppStrings.punchIn,
                                    style: AppTextStyles.bodyMedium(
                                      context,
                                    ).copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.042),
              // Right side - Dynamic Circular progress timer
              AttendanceTimerCircle(
                workedHours: _workedHours,
                shiftHours: _shiftHours,
                size: 95,
              ),
            ],
          ),
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
