import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../calendar/domain/entities/calendar_day_entity.dart';
import '../../../../../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../attendance/data/datasources/attendance_details_remote_datasource.dart';
import '../../../../../../../attendance/data/repositories/attendance_details_repository_impl.dart';
import '../../../../../../../attendance/domain/entities/attendance_day_detail.dart';
import '../../../../../../../attendance/domain/entities/attendance_details.dart';
import '../../../../../../../attendance/domain/usecases/get_attendance_day_detail_usecase.dart';
import '../../../../../../../attendance/domain/usecases/get_attendance_details_usecase.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../widgets/time_utilization_card.dart';
import '../widgets/day_details_card.dart';

/// Attendance detail page opened from Services.
///
/// Displays time utilization, a color-coded attendance calendar,
/// and day details for the selected date.
class AttendanceDetailPage extends StatefulWidget {
  const AttendanceDetailPage({super.key});

  @override
  State<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage> {
  DateTime _selectedDate = _dateOnly(DateTime.now());
  AttendanceDetails? _attendanceDetails;
  AttendanceDayDetail? _selectedDayDetail;
  bool _isLoading = true;
  String? _errorMessage;

  late final CalendarBloc _calendarBloc;

  @override
  void initState() {
    super.initState();
    _calendarBloc = CalendarBloc();
    _loadAttendanceDetails();
    _loadCalendarData(DateTime.now());
  }

  @override
  void dispose() {
    _calendarBloc.close();
    super.dispose();
  }

  /// Dispatch calendar data load for the given month.
  void _loadCalendarData(DateTime month) {
    _calendarBloc.add(LoadCalendarData(month: month.month, year: month.year));
  }

  Future<void> _loadAttendanceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final dio = Dio();
      final apiClient = ApiClient(dio: dio, networkInfo: networkInfo,onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },);
      final remoteDataSource = AttendanceDetailsRemoteDataSourceImpl(apiClient);
      final repository = AttendanceDetailsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final getAttendanceDetailsUseCase = GetAttendanceDetailsUseCase(
        repository,
      );
      final getAttendanceDayDetailUseCase = GetAttendanceDayDetailUseCase(
        repository,
      );

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
          final userId = _resolveUserId();
          if (userId != null) {
            _loadSelectedDayDetail(
              userId: userId,
              useCase: getAttendanceDayDetailUseCase,
            );
          } else {
            developer.log(
              'Skipping initial selected day detail load because userId is null',
              name: 'AttendanceDetailPage',
            );
          }
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
    developer.log(
      'Attendance date selected: ${date.toIso8601String()}',
      name: 'AttendanceDetailPage',
    );
    setState(() {
      _selectedDate = _dateOnly(date);
    });
    final userId = _resolveUserId();
    if (userId != null) {
      _loadSelectedDayDetail(userId: userId);
    } else {
      developer.log(
        'Skipping selected day detail load because userId is null',
        name: 'AttendanceDetailPage',
      );
    }
  }

  Future<void> _loadSelectedDayDetail({
    required int userId,
    GetAttendanceDayDetailUseCase? useCase,
  }) async {
    try {
      developer.log(
        'Loading selected day detail for userId=$userId date=${_dateOnly(_selectedDate).toUtc().toIso8601String()}',
        name: 'AttendanceDetailPage',
      );
      final dayDetailUseCase =
          useCase ?? await _buildAttendanceDayDetailUseCase();
      final result = await dayDetailUseCase(
        userId: userId,
        date: _dateOnly(_selectedDate).toUtc().toIso8601String(),
      );
      result.fold(
        (failure) {
          developer.log(
            'Selected day detail failed: ${failure.message}',
            name: 'AttendanceDetailPage',
          );
          if (!mounted) return;
          setState(() {
            _selectedDayDetail = null;
          });
        },
        (dayDetail) {
          developer.log(
            'Selected day detail loaded. dayLogs=${dayDetail.dayLogs.length}',
            name: 'AttendanceDetailPage',
          );
          if (!mounted) return;
          setState(() {
            _selectedDayDetail = dayDetail;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedDayDetail = null;
      });
    }
  }

  Future<GetAttendanceDayDetailUseCase>
  _buildAttendanceDayDetailUseCase() async {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo,onTokenExpired: () {
      AppNavigator.pushAndRemoveAll(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    },);
    final remoteDataSource = AttendanceDetailsRemoteDataSourceImpl(apiClient);
    final repository = AttendanceDetailsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    return GetAttendanceDayDetailUseCase(repository);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int? _resolveUserId() {
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is UserProfileLoaded) {
      return profileState.profile.userId;
    }
    return _attendanceDetails?.userId;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
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
                  "Back",
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
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
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: screenHeight * 0.01),
            // Today's Time Utilization
            TimeUtilizationCard(
              attendanceDetails: _attendanceDetails,
              isLoading: _isLoading,
              onRefresh: _loadAttendanceDetails,
            ),
            SizedBox(height: screenHeight * 0.02),
            // Day Details
            PermissionGuard(
              requiredPermission: "Attendance:My Attendance:Read",
              child: BlocBuilder<CalendarBloc, CalendarState>(
                bloc: _calendarBloc,
                builder: (context, state) {
                  final days =
                      state is CalendarLoaded
                          ? state.days
                          : <CalendarDayEntity>[];
                  return DayDetailsCard(
                    selectedDate: _selectedDate,
                    onDateChanged: _onDateSelected,
                    attendanceDetails: _attendanceDetails,
                    selectedDayDetail: _selectedDayDetail,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    calendarDays: days,
                  );
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }
}
