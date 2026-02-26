import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_assets.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/attendance_details_remote_datasource.dart';
import '../../data/repositories/attendance_details_repository_impl.dart';
import '../../domain/usecases/get_attendance_details_usecase.dart';
import '../../domain/entities/attendance_details.dart';

/// Punch details widget with 2x2 grid layout
class PunchDetails extends StatefulWidget {
  const PunchDetails({super.key});

  @override
  State<PunchDetails> createState() => _PunchDetailsState();
}

class _PunchDetailsState extends State<PunchDetails> {
  AttendanceDetails? _attendanceDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttendanceDetails();
  }

  Future<void> _loadAttendanceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize API client and dependencies
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
      final remoteDataSource =
          AttendanceDetailsRemoteDataSourceImpl(apiClient);
      final repository = AttendanceDetailsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final getAttendanceDetailsUseCase =
          GetAttendanceDetailsUseCase(repository);

      // Fetch attendance details from API
      final result = await getAttendanceDetailsUseCase();

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
        (attendanceDetails) {
          setState(() {
            _attendanceDetails = attendanceDetails;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading attendance details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.042), // ~4.2% of screen width
      child: _isLoading
          ? SizedBox(
              height: screenHeight * 0.15,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _errorMessage != null
              ? SizedBox(
                  height: screenHeight * 0.15,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadAttendanceDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: screenWidth * 0.027, // ~2.7% of screen width
                  mainAxisSpacing:
                      screenHeight * 0.015, // 1.5% of screen height
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  childAspectRatio: 2.3,
                  children: [
                    _buildPunchCard(
                      context,
                      time: _attendanceDetails?.formattedPunchIn ?? '-',
                      label: AppStrings.punchIn,
                      icon: AppAssets.iconPunchIn,
                      iconColor: AppColors.primary,
                      backgroundColor: AppColors.attendanceLightBlueBg,
                      borderColor: AppColors.primary,
                    ),
                    _buildPunchCard(
                      context,
                      time: _attendanceDetails?.formattedPunchOut ?? '-',
                      label: AppStrings.punchOut,
                      icon: AppAssets.iconPunchOut,
                      iconColor: AppColors.success,
                      backgroundColor: AppColors.attendanceLightGreenBg,
                      borderColor: AppColors.success,
                    ),
                    _buildPunchCard(
                      context,
                      time: _attendanceDetails?.formattedBreakTime ?? '-',
                      label: AppStrings.breakTime,
                      icon: AppAssets.iconBreak,
                      iconColor: AppColors.warning,
                      backgroundColor: AppColors.attendanceLightOrangeBg,
                      borderColor: AppColors.warning,
                    ),
                    _buildPunchCard(
                      context,
                      time: _attendanceDetails?.formattedOverTime ?? '-',
                      label: AppStrings.overtime,
                      icon: AppAssets.iconOvertime,
                      iconColor: AppColors.error,
                      backgroundColor: AppColors.attendanceLightRedBg,
                      borderColor: AppColors.error,
                    ),
                  ],
                ),
    );
  }

  Widget _buildPunchCard(
    BuildContext context, {
    required String time,
    required String label,
    required String icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.032), // ~3.2% of screen width
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with optional progress indicator
          SvgPicture.asset(
            icon,
            fit: BoxFit.contain,
          ),
          // Time and label
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenHeight * 0.0025), // 0.25% of screen height
                Text(
                  label,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}