import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../attendance/data/datasources/attendance_details_remote_datasource.dart';
import '../../../../../../../attendance/data/repositories/attendance_details_repository_impl.dart';
import '../../../../../../../attendance/domain/entities/attendance_details.dart';
import '../../../../../../../attendance/domain/usecases/get_attendance_details_usecase.dart';
import '../widgets/time_utilization_card.dart';
import '../widgets/attendance_detail_calendar.dart';
import '../widgets/day_details_card.dart';

/// Attendance detail page opened from Services
class AttendanceDetailPage extends StatefulWidget {
  const AttendanceDetailPage({super.key});

  @override
  State<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  DateTime _selectedDate = DateTime(2025, 12, 30);
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

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return ResponsiveScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: MediaQuery.of(context).size.width * 0.048,
              ),
              Flexible(
                child: Text(
                  AppStrings.services,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          AppStrings.attendance,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: screenHeight * 0.02),
            // Today's Time Utilization
            TimeUtilizationCard(
              attendanceDetails: _attendanceDetails,
              isLoading: _isLoading,
              onRefresh: _loadAttendanceDetails,
            ),
            SizedBox(height: screenHeight * 0.02),
            // Calendar
            AttendanceDetailCalendar(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
            ),
            SizedBox(height: screenHeight * 0.02),
            // Day Details
            DayDetailsCard(
              selectedDate: _selectedDate,
              attendanceDetails: _attendanceDetails,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}

