import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/attendance_timer_circle.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/usecases/punch_in_usecase.dart';
import '../../domain/usecases/punch_out_usecase.dart';
import '../../domain/entities/attendance_details.dart';

// Helper function to get gradient alignment for CSS angle (111.14°)
// CSS: 0° = right, clockwise. The gradient line goes in this direction
List<Alignment> _getGradientAlignment(double angleDegrees) {
  // Convert CSS angle to radians
  // CSS: 0° = right (→), 90° = bottom (↓), 180° = left (←), 270° = top (↑)
  final angleRad = angleDegrees * math.pi / 180;
  
  // Calculate the direction vector for the gradient line
  // For CSS 111.14°, this points down-left
  final dx = math.cos(angleRad);
  final dy = math.sin(angleRad);
  
  // In Flutter, LinearGradient flows from begin to end
  // For CSS 111.14°, colors flow along the perpendicular direction
  // The visual effect: teal at top-left, white at bottom-right
  // So we need the gradient to go from top-left to bottom-right
  // But following the CSS angle direction
  
  // Calculate perpendicular direction (90° rotation)
  final perpDx = -dy;  // Perpendicular x component
  final perpDy = dx;   // Perpendicular y component
  
  // Normalize and create alignment points
  // Begin point (where gradient starts - top-left area)
  // End point (where gradient ends - bottom-right area)
  return [
    Alignment(perpDx, -perpDy), // Begin (adjusted for Flutter's coordinate system)
    Alignment(-perpDx, perpDy),  // End
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

  /// Check if user is already punched in
  /// Uses punchIn as primary indicator (has punch-in time, no punch-out)
  /// punchInIp is optional - API may not always return it
  bool get _isPunchedIn {
    final hasPunchOut = widget.attendanceDetails?.punchOut != null &&
        widget.attendanceDetails!.punchOut!.isNotEmpty &&
        widget.attendanceDetails!.punchOut != '-';
    if (hasPunchOut) return false;

    final hasPunchInIp = widget.attendanceDetails?.punchInIp != null &&
        widget.attendanceDetails!.punchInIp!.isNotEmpty &&
        widget.attendanceDetails!.punchInIp != '-';
    final hasPunchIn = widget.attendanceDetails?.punchIn != null &&
        widget.attendanceDetails!.punchIn!.isNotEmpty &&
        widget.attendanceDetails!.punchIn != '-';
    return hasPunchInIp || hasPunchIn;
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
      // Sunday is 7 in DateTime.weekday (Monday=1, Sunday=7)
      return localDate.weekday == 7;
    } catch (e) {
      return false;
    }
  }

  /// Check if punch-in button should be disabled (punch out is always enabled when punched in)
  bool get _isPunchInDisabled {
    return _isHoliday || _isWeekOff || _isPunchedIn;
  }

  /// Check if the main button should be disabled
  bool get _isButtonDisabled {
    if (widget.isLoading || _isPunchingIn || _isPunchingOut) return true;
    // When punched in, show punch out - button is enabled
    if (_isPunchedIn) return false;
    // When not punched in, disable if holiday or week off
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

  @override
  void initState() {
    super.initState();
    // Update timer every second to refresh worked hours when punched in
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateWorkedHours();
    });
    _updateWorkedHours();
  }

  @override
  void didUpdateWidget(AttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update worked hours when attendance details change
    if (oldWidget.attendanceDetails != widget.attendanceDetails) {
      _updateWorkedHours();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateWorkedHours() {
    if (!mounted) return;

    setState(() {
      _workedHours = TimeUtils.getWorkedHours(
        totalTime: widget.attendanceDetails?.totalTime,
        punchIn: widget.attendanceDetails?.punchIn,
        punchOut: widget.attendanceDetails?.punchOut,
        punchInIp: widget.attendanceDetails?.punchInIp,
      );
    });
  }

  Future<void> _handlePunchIn() async {
    if (_isPunchingIn || _isPunchedIn || _isPunchInDisabled) return;

    setState(() {
      _isPunchingIn = true;
    });

    try {
      // Get current location
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocation();

      // Initialize API client and dependencies
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
      final remoteDataSource = AttendanceRemoteDataSourceImpl(apiClient);
      final repository = AttendanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final punchInUseCase = PunchInUseCase(repository);

      // Call punch-in API
      final result = await punchInUseCase(
        punchInLocation: locationData.address,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        punchType: 'remote',
      );

      result.fold(
        (failure) {
          // Handle error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (success) {
          // Handle success
          // Reload attendance details to get updated punch in time
          widget.onRefresh();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPunchingIn = false;
        });
      }
    }
  }

  Future<void> _handlePunchOut() async {
    if (_isPunchingOut || !_isPunchedIn) return;

    setState(() {
      _isPunchingOut = true;
    });

    try {
      // Get current location
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocation();

      // Initialize dependencies (same pattern as punch in)
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
      final remoteDataSource = AttendanceRemoteDataSourceImpl(apiClient);
      final repository = AttendanceRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final punchOutUseCase = PunchOutUseCase(repository);

      // Call punch-out API
      final result = await punchOutUseCase(
        punchOutLocation: locationData.address,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (success) {
          // Reload attendance details to get updated punch out time
          widget.onRefresh();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPunchingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get formatted date from API (UTC to local) or use current date
    final dateStr = _getFormattedDate();
    final now = DateTime.now();
    final dayTimeStr = DateFormat('EEEE, hh:mm a').format(now);
    
    return Transform.translate(
      offset: const Offset(0, -12), // Overlap header slightly
      child: Container(
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width * 0.053, // ~5.3% of screen width
          MediaQuery.of(context).size.height * 0.0125, // 1.25% of screen height
          MediaQuery.of(context).size.width * 0.053,
          MediaQuery.of(context).size.height * 0.015, // 1.5% of screen height
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: _getGradientAlignment(111.14)[0],
            end: _getGradientAlignment(111.14)[1],
            stops: const [0.0, 0.4, 0.8676], // Start with teal, transition to white
            colors: [
              AppColors.attendanceTeal,
              AppColors.attendanceTeal,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: AppTextStyles.heading4(context).copyWith(
                      color: AppColors.textWhite,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.0075), // 0.75% of screen height
                  // Day and time
                  Text(
                    dayTimeStr,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textWhite,
                      height: 1.2,
                    ),
                  ),
                  // Show Holiday status badge at the end
                  if (_isHoliday) ...[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.008),
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
                          Icon(
                            Icons.event,
                            size: 12,
                            color: AppColors.error,
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
                  // Punch In/Out button
                  ElevatedButton(
                    onPressed: _isButtonDisabled
                        ? null
                        : _isPunchedIn
                            ? _handlePunchOut
                            : _handlePunchIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isButtonDisabled
                          ? AppColors.textSecondary.withOpacity(0.2)
                          : AppColors.background,
                      foregroundColor: _isButtonDisabled
                          ? AppColors.textSecondary.withOpacity(0.7)
                          : AppColors.textPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.053, // ~5.3% of screen width
                        vertical: MediaQuery.of(context).size.height * 0.0175, // 1.75% of screen height
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // More rounded/oval
                        side: BorderSide(
                          color: _isButtonDisabled
                              ? AppColors.textSecondary.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.2),
                      disabledForegroundColor: AppColors.textSecondary.withOpacity(0.7),
                    ),
                    child: (widget.isLoading || _isPunchingIn || _isPunchingOut)
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width * 0.037,
                            height: MediaQuery.of(context).size.width * 0.037,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.064, // ~6.4% of screen width
                                height: MediaQuery.of(context).size.width * 0.064,
                                decoration: BoxDecoration(
                                  color:  AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPunchedIn ? Icons.arrow_back : Icons.arrow_forward,
                                  color: AppColors.textWhite,
                                  size: MediaQuery.of(context).size.width * 0.037, // ~3.7% of screen width
                                ),
                              ),
                              SizedBox(width: MediaQuery.of(context).size.width * 0.021), // ~2.1% of screen width
                              Text(
                                _isPunchedIn ? AppStrings.punchOut : AppStrings.punchIn,
                                style: AppTextStyles.bodyMedium(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.042), // ~4.2% of screen width
            // Right side - Dynamic Circular progress timer
            AttendanceTimerCircle(
              workedHours: _workedHours,
              shiftHours: _shiftHours,
              size: 90,
            ),
          ],
        ),
      ),
    );
  }
}

