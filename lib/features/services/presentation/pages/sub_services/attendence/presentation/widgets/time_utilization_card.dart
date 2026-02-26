import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/time_utils.dart';
import '../../../../../../../../core/utils/location_service.dart';
import '../../../../../../../attendance/data/datasources/attendance_remote_datasource.dart';
import '../../../../../../../attendance/data/repositories/attendance_repository_impl.dart';
import '../../../../../../../attendance/domain/entities/attendance_details.dart';
import '../../../../../../../attendance/domain/usecases/punch_in_usecase.dart';
import '../../../../../../../attendance/domain/usecases/punch_out_usecase.dart';

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
  DateTime? _punchInTime;
  
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

  /// Get punch-in time components (hours, minutes, seconds)
  Map<String, String> _getPunchInTimeComponents() {
    if (widget.attendanceDetails?.punchIn == null ||
        widget.attendanceDetails!.punchIn!.isEmpty ||
        widget.attendanceDetails!.punchIn == '-') {
      return {'hours': '00', 'minutes': '00', 'seconds': '00'};
    }
    
    try {
      final utcTime = DateTime.parse(widget.attendanceDetails!.punchIn!);
      final localTime = utcTime.toLocal();
      return {
        'hours': localTime.hour.toString().padLeft(2, '0'),
        'minutes': localTime.minute.toString().padLeft(2, '0'),
        'seconds': localTime.second.toString().padLeft(2, '0'),
      };
    } catch (e) {
      return {'hours': '00', 'minutes': '00', 'seconds': '00'};
    }
  }

  @override
  void initState() {
    super.initState();
    // Update timer every second to update punch-in time display
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePunchInTime();
    });
    _updatePunchInTime();
  }

  @override
  void didUpdateWidget(TimeUtilizationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update punch-in time when attendance details change
    if (oldWidget.attendanceDetails != widget.attendanceDetails) {
      _updatePunchInTime();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updatePunchInTime() {
    if (!mounted) return;

    if (widget.attendanceDetails?.punchIn != null &&
        widget.attendanceDetails!.punchIn!.isNotEmpty &&
        widget.attendanceDetails!.punchIn != '-') {
      try {
        final utcTime = DateTime.parse(widget.attendanceDetails!.punchIn!);
        final localTime = utcTime.toLocal();
        setState(() {
          _punchInTime = localTime;
        });
      } catch (e) {
        setState(() {
          _punchInTime = null;
        });
      }
    } else {
      setState(() {
        _punchInTime = null;
      });
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Get formatted date from API (UTC to local)
    final formattedDate = _getFormattedDate();
    
    // Get punch-in time components
    final timeComponents = _getPunchInTimeComponents();
    
    // Get time components - show elapsed time if punched in, otherwise show punch-in time
    String hours = timeComponents['hours']!;
    String minutes = timeComponents['minutes']!;
    String seconds = timeComponents['seconds']!;
    
    // If punched in, show elapsed time since punch-in (live update)
    if (_punchInTime != null && _isPunchedIn) {
      final now = DateTime.now();
      final difference = now.difference(_punchInTime!);
      final totalSeconds = difference.inSeconds;
      hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
      minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
      seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.020), // ~4.2% of screen width
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
          // Title
          Text(
            "Today's Time Utilization",
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.015), // 1.5% of screen height
          // Date with Holiday badge inline
          Row(
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
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
          SizedBox(height: screenHeight * 0.02), // 2% of screen height
          // Timer and Punch In button row
          Row(
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
                        _buildTimeBox(context, hours),
                        SizedBox(width: screenWidth * 0.02),
                        _buildTimeBox(context, minutes),
                        SizedBox(width: screenWidth * 0.02),
                        _buildTimeBox(context, seconds),
                      ],
                    ),
              // Punch In/Out button
              ElevatedButton(
                onPressed: _isButtonDisabled
                    ? null
                    : _isPunchedIn
                        ? _handlePunchOut
                        : _handlePunchIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonDisabled
                      ? AppColors.textSecondary.withOpacity(0.3)
                      : AppColors.attendanceTeal,
                  foregroundColor: AppColors.textWhite,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.textSecondary.withOpacity(0.3),
                  disabledForegroundColor: AppColors.textWhite.withOpacity(0.6),
                ),
                child: (_isPunchingIn || _isPunchingOut)
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
                        _isPunchedIn ? AppStrings.punchOut : AppStrings.punchIn,
                        style: AppTextStyles.buttonMedium(context).copyWith(
                          color: AppColors.textWhite,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(BuildContext context, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      width: screenWidth * 0.12, // 12% of screen width
      height: screenHeight * 0.06, // 6% of screen height
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          value,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

