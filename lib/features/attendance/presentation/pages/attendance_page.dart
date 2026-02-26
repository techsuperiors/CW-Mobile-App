import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/attendance_details_remote_datasource.dart';
import '../../data/repositories/attendance_details_repository_impl.dart';
import '../../domain/entities/attendance_details.dart';
import '../../domain/usecases/get_attendance_details_usecase.dart';
import '../../../user/data/datasources/user_profile_remote_datasource.dart';
import '../../../user/data/repositories/user_profile_repository_impl.dart';
import '../../../user/domain/entities/user_profile.dart';
import '../../../user/domain/usecases/get_user_profile_usecase.dart';
import '../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../user/presentation/bloc/user_profile_event.dart';
import '../../../leaves/domain/entities/leave_type.dart';
import '../../../leaves/presentation/bloc/leave_types_bloc.dart';
import '../../../leaves/presentation/bloc/leave_types_event.dart';
import '../../../leaves/presentation/bloc/leave_types_state.dart';
import '../../../events/data/datasources/upcoming_events_remote_datasource.dart';
import '../../../events/data/repositories/upcoming_events_repository_impl.dart';
import '../../../events/domain/entities/upcoming_event.dart';
import '../../../events/domain/usecases/get_upcoming_events_usecase.dart';
import '../widgets/attendance_header.dart';
import '../widgets/attendance_card.dart';
import '../widgets/punch_details.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/leaves_summary.dart';
import '../widgets/quick_links.dart';
import '../widgets/upcoming_events.dart';
import '../widgets/attendance_calendar.dart';

/// Attendance page matching the design
class AttendancePage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const AttendancePage({super.key, this.onOpenDrawer});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // API Data
  AttendanceDetails? _attendanceDetails;
  UserProfile? _userProfile;
  List<UpcomingEvent> _upcomingEvents = [];

  // Loading States
  bool _isLoadingProfile = true;
  bool _isLoadingAttendance = true;
  bool _isLoadingEvents = true;

  // Error Messages
  String? _profileError;
  String? _attendanceError;
  String? _eventsError;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// Check if all APIs are loaded (leave types come from LeaveTypesBloc)
  bool _isAllDataLoaded(LeaveTypesState leaveTypesState) {
    final isLeavesReady =
        leaveTypesState is LeaveTypesLoaded || leaveTypesState is LeaveTypesError;
    return !_isLoadingProfile &&
        !_isLoadingAttendance &&
        !_isLoadingEvents &&
        isLeavesReady;
  }

  /// Load all APIs in parallel (leave types loaded via LeaveTypesBloc from dashboard)
  Future<void> _loadAllData() async {
    // Reset all loading states
    setState(() {
      _isLoadingProfile = true;
      _isLoadingAttendance = true;
      _isLoadingEvents = true;
      _profileError = null;
      _attendanceError = null;
      _eventsError = null;
    });

    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);

    // Call all APIs in parallel
    await Future.wait([
      _loadUserProfile(apiClient, networkInfo),
      _loadAttendanceDetails(apiClient, networkInfo),
      _loadUpcomingEvents(apiClient, networkInfo),
    ]);
  }

  Future<void> _loadUserProfile(ApiClient apiClient, NetworkInfo networkInfo) async {
    try {
      final remoteDataSource = UserProfileRemoteDataSourceImpl(apiClient);
      final repository = UserProfileRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final getUserProfileUseCase = GetUserProfileUseCase(repository);

      final result = await getUserProfileUseCase();

      result.fold(
        (failure) {
          setState(() {
            _profileError = failure.message;
            _isLoadingProfile = false;
          });
        },
        (profile) {
          setState(() {
            _userProfile = profile;
            _isLoadingProfile = false;
          });
          // Sync to UserProfileBloc so drawer shows same data as header
          if (context.mounted) {
            context.read<UserProfileBloc>().add(SetUserProfile(profile));
            // Load leave types into shared bloc (used by dashboard & Apply Leave)
            context.read<LeaveTypesBloc>().add(LoadLeaveTypes(profile.userId));
          }
        },
      );
    } catch (e) {
      setState(() {
        _profileError = 'Error loading profile: ${e.toString()}';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadAttendanceDetails(ApiClient apiClient, NetworkInfo networkInfo) async {
    try {
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
            _attendanceError = failure.message;
            _isLoadingAttendance = false;
          });
        },
        (attendanceDetails) {
          setState(() {
            _attendanceDetails = attendanceDetails;
            _isLoadingAttendance = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _attendanceError = 'Error loading attendance: ${e.toString()}';
        _isLoadingAttendance = false;
      });
    }
  }

  Future<void> _loadUpcomingEvents(ApiClient apiClient, NetworkInfo networkInfo) async {
    try {
      final remoteDataSource = UpcomingEventsRemoteDataSourceImpl(apiClient);
      final repository = UpcomingEventsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final getUpcomingEventsUseCase = GetUpcomingEventsUseCase(repository);

      final result = await getUpcomingEventsUseCase();

      result.fold(
        (failure) {
          setState(() {
            _eventsError = failure.message;
            _isLoadingEvents = false;
          });
        },
        (events) {
          setState(() {
            _upcomingEvents = events;
            _isLoadingEvents = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _eventsError = 'Error loading events: ${e.toString()}';
        _isLoadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    
    // Responsive spacing helper
    double responsiveSpacing(double baseSpacing) {
      if (screenHeight < 600) {
        return baseSpacing * 0.75;
      } else if (screenHeight < 700) {
        return baseSpacing * 0.85;
      }
      return baseSpacing;
    }
    
    return BlocBuilder<LeaveTypesBloc, LeaveTypesState>(
      builder: (context, leaveTypesState) {
        // Show loading screen until all data is loaded
        if (!_isAllDataLoaded(leaveTypesState)) {
          return ResponsiveScaffold(
            padding: EdgeInsets.zero,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Loading dashboard...',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final leaveTypes = leaveTypesState is LeaveTypesLoaded
            ? leaveTypesState.leaveTypes
            : null;
        final leavesError = leaveTypesState is LeaveTypesError
            ? leaveTypesState.message
            : null;
        final isLoadingLeaves = leaveTypesState is LeaveTypesLoading;

        return ResponsiveScaffold(
      padding: EdgeInsets.zero,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with profile
            AttendanceHeader(
              userProfile: _userProfile,
              onAvatarTap: widget.onOpenDrawer,
            ),
            // Attendance Card (overlaps header by 20px, so no spacing needed)
            AttendanceCard(
              attendanceDetails: _attendanceDetails,
              isLoading: _isLoadingAttendance,
              onRefresh: _loadAllData,
            ),
            // Punch Details
            PunchDetails(
              attendanceDetails: _attendanceDetails,
              isLoading: _isLoadingAttendance,
              errorMessage: _attendanceError,
              onRefresh: _loadAllData,
            ),
            SizedBox(height: responsiveSpacing(10)),
            // Attendance Summary
            const AttendanceSummary(),
            SizedBox(height: responsiveSpacing(10)),
            // Leaves Summary (from LeaveTypesBloc - shared with Apply Leave)
            LeavesSummary(
              leaveTypes: leaveTypes,
              isLoading: isLoadingLeaves,
              errorMessage: leavesError,
            ),
            SizedBox(height: responsiveSpacing(10)),
            // Upcoming Events
            UpcomingEvents(
              events: _upcomingEvents,
              isLoading: _isLoadingEvents,
              errorMessage: _eventsError,
              onRefresh: _loadAllData,
            ),
            SizedBox(height: responsiveSpacing(10)),
            // Quick Links
            const QuickLinks(),
            SizedBox(height: responsiveSpacing(10)),
            // Calendar
            const AttendanceCalendar(),
            SizedBox(height: responsiveSpacing(24)),
          ],
        ),
      ),
    );
      },
    );
  }
}

