import 'package:collectivWork/core/utils/token_storage.dart';
import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:collectivWork/features/attendance/presentation/pages/face_verification/face_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../../../../core/utils/app_navigator.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../calendar/domain/entities/calendar_day_entity.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../leave_stats/data/datasources/leave_stats_remote_datasource.dart';
import '../../../leave_stats/data/repository/leave_stats_repository_impl.dart';
import '../../../leave_stats/domain/entities/leave_stats_entity.dart';
import '../../../leave_stats/domain/usecases/get_leave_stats_usecase.dart';
import '../../../user/data/datasources/user_profile_local_datasource.dart';
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
import '../../../notification/data/datasources/notification_remote_datasource.dart';
import '../../../notification/data/repositories/notification_repository_impl.dart';
import '../../../notification/domain/usecases/get_notifications.dart';
import '../../../notification/domain/usecases/get_notification_count.dart';
import '../../../notification/domain/usecases/view_notifications.dart';
import '../../../notification/domain/usecases/read_notification.dart';
import '../../../notification/presentation/bloc/notification_bloc.dart';
import '../../../notification/presentation/bloc/notification_event.dart';
import '../bloc/attendance_punch_bloc.dart';
import '../bloc/attendance_punch_state.dart';
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
  bool _isLoadingLeaveStats = true;

  // Error Messages
  String? _profileError;
  String? _attendanceError;
  String? _eventsError;

  // Leave stats data
  LeaveStatsEntity? _leaveStats;

  late final CalendarBloc _calendarBloc;
  late final NotificationBloc _notificationBloc;

  /// Timestamp of the last successful data load.
  DateTime? _lastLoadedAt;

  /// data load — ensuring "Loading dashboard..." appears only once.
  bool _isInitialLoad = true;

  /// Prevents concurrent/duplicate API calls.
  bool _isLoadingInProgress = false;

  /// Prevents [didChangeDependencies] from triggering a data load
  bool _isDependenciesInitialized = false;

  /// How long loaded data is considered fresh before requiring a reload.
  static const _cacheDuration = Duration(minutes: 5);
  static const _refreshTimeout = Duration(seconds: 20);

  /// Returns true if the cached data is stale and should be reloaded.
  bool get _isDataStale {
    if (_lastLoadedAt == null) return true;
    return DateTime.now().difference(_lastLoadedAt!) > _cacheDuration;
  }

  //Selection of current date for the attendence summary
  DateTime _selectedMonth = DateTime.now();

  ///For Handling the scroll on the calender button tap
  final GlobalKey _calendarKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  void onCalenderTap() {
    debugPrint("======clicked");
    final context = _calendarKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
        alignment: 0.1, // Isse calendar screen ke thoda top/center mein aayega
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _calendarBloc = CalendarBloc();

    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(
      dio: dio,
      networkInfo: networkInfo,
      onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );

    final notificationRepo = NotificationRepositoryImpl(
      remoteDataSource: NotificationRemoteDataSourceImpl(apiClient: apiClient),
      networkInfo: networkInfo,
    );
    _notificationBloc = NotificationBloc(
      getNotifications: GetNotifications(notificationRepo),
      getNotificationCount: GetNotificationCount(notificationRepo),
      viewNotifications: ViewNotifications(notificationRepo),
      readNotification: ReadNotification(notificationRepo),
    );

    _loadAllData();
    _loadCalendarData(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Skip the first call — initState has already triggered the initial load.
    if (!_isDependenciesInitialized) {
      _isDependenciesInitialized = true;
      return;
    }

    // On subsequent calls (e.g. Navigator pop), reload only if cache is stale.
    if (_isDataStale) {
      _loadAllData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _calendarBloc.close();
    _notificationBloc.close();
    super.dispose();
  }

  /// Dispatch calendar data load for the given month.
  void _loadCalendarData(DateTime month) {
    _calendarBloc.add(LoadCalendarData(month: month.month, year: month.year));
  }

  DateTime _monthStart(DateTime month) => DateTime(month.year, month.month, 1);

  DateTime _monthEnd(DateTime month) =>
      DateTime(month.year, month.month + 1, 0);

  Future<void> _refreshAttendanceSummaryOnly() async {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(
      dio: dio,
      networkInfo: networkInfo,
      onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );

    setState(() {
      _isLoadingLeaveStats = true;
    });

    await _loadLeaveStats(apiClient, networkInfo, targetMonth: _selectedMonth);
  }

  Future<void> _changeSelectedMonth(int monthOffset) async {
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + monthOffset,
      1,
    );
    setState(() {
      _selectedMonth = nextMonth;
    });
    await _refreshAttendanceSummaryOnly();
  }

  /// Check if all APIs are loaded (leave types come from LeaveTypesBloc)
  bool _isAllDataLoaded(LeaveTypesState leaveTypesState) {
    if (!_isInitialLoad)
      return true; // ← After first load, never show full screen again

    final isLeavesReady =
        leaveTypesState is LeaveTypesLoaded ||
        leaveTypesState is LeaveTypesError;
    return !_isLoadingProfile &&
        !_isLoadingAttendance &&
        !_isLoadingEvents &&
        isLeavesReady;
  }

  /// Load all APIs in parallel (leave types loaded via LeaveTypesBloc from dashboard)
  Future<void> _loadAllData({DateTime? targetMonth}) async {
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;

    // Reset all loading states
    setState(() {
      _isLoadingProfile = true;
      _isLoadingAttendance = true;
      _isLoadingEvents = true;
      _isLoadingLeaveStats = true;
      _profileError = null;
      _attendanceError = null;
      _eventsError = null;
    });

    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(
      dio: dio,
      networkInfo: networkInfo,
      onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );
    final effectiveMonth = targetMonth ?? _selectedMonth;
    _loadCalendarData(effectiveMonth);
    // Call all APIs in parallel
    try {
      _notificationBloc.add(FetchNotificationCount());
      if(context.mounted){
        await Future.wait([
          _loadUserProfile(apiClient, networkInfo),
          _loadAttendanceDetails(apiClient, networkInfo),
          _loadUpcomingEvents(apiClient, networkInfo),
          _loadLeaveStats(apiClient, networkInfo, targetMonth: effectiveMonth),
        ]).timeout(_refreshTimeout);
      }

    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingAttendance = false;
          _isLoadingEvents = false;
          _isLoadingLeaveStats = false;
          _profileError ??= 'Refresh timed out. Please try again.';
          _attendanceError ??= 'Refresh timed out. Please try again.';
          _eventsError ??= 'Refresh timed out. Please try again.';
        });
      }
    } finally {
      _isLoadingInProgress = false;
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
          _lastLoadedAt = DateTime.now();
        });
      }
    }
  }

  Future<void> _loadUserProfile(
    ApiClient apiClient,
    NetworkInfo networkInfo,
  ) async {
    try {
      final remoteDataSource = UserProfileRemoteDataSourceImpl(apiClient);
      final userProfileLocalDataSource = UserProfileLocalDataSourceImpl();

      final repository = UserProfileRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
        localDataSource: userProfileLocalDataSource,
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
      if (mounted) {
        setState(() {
          _profileError = 'Error loading profile: ${e.toString()}';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadAttendanceDetails(
    ApiClient apiClient,
    NetworkInfo networkInfo,
  ) async
  {
    try {
      final remoteDataSource = AttendanceDetailsRemoteDataSourceImpl(apiClient);
      final repository = AttendanceDetailsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final getAttendanceDetailsUseCase = GetAttendanceDetailsUseCase(
        repository,
      );

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
      if(context.mounted){
        setState(() {
          _attendanceError = 'Error loading attendance: ${e.toString()}';
          _isLoadingAttendance = false;
        });
      }

    }
  }

  Future<void> _loadUpcomingEvents(
    ApiClient apiClient,
    NetworkInfo networkInfo,
  ) async {
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

  /// Load leave stats for the attendance summary card.
  Future<void> _loadLeaveStats(
    ApiClient apiClient,
    NetworkInfo networkInfo, {
    DateTime? targetMonth,
  }) async {
    try {
      final remoteDataSource = LeaveStatsRemoteDataSourceImpl(apiClient);
      final repository = LeaveStatsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        networkInfo: networkInfo,
      );
      final getLeaveStatsUseCase = GetLeaveStatsUseCase(repository);
      final effectiveMonth = targetMonth ?? _selectedMonth;
      final startDate = _monthStart(effectiveMonth).toIso8601String();
      final endDate = _monthEnd(effectiveMonth).toIso8601String();

      final result = await getLeaveStatsUseCase(
        startDate: startDate,
        endDate: endDate,
      );

      result.fold(
        (failure) {
          setState(() {
            _isLoadingLeaveStats = false;
          });
        },
        (stats) {
          setState(() {
            _leaveStats = stats;
            _isLoadingLeaveStats = false;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLeaveStats = false;
        });
      }
    }
  }

  /// only attendance data reload  — after punch in/out this method gets called
  Future<void> _refreshAttendanceOnly() async {
    if (_isLoadingInProgress) return;

    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(
      dio: dio,
      networkInfo: networkInfo,
      onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );

    setState(() {
      _isLoadingAttendance = true;
      _attendanceError = null;
    });

    try {
      await _loadAttendanceDetails(
        apiClient,
        networkInfo,
      ).timeout(_refreshTimeout);
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _attendanceError = 'Attendance refresh timed out. Please try again.';
          _isLoadingAttendance = false;
        });
      }
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
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final leaveTypes =
            leaveTypesState is LeaveTypesLoaded
                ? leaveTypesState.leaveTypes
                : null;
        final leavesError =
            leaveTypesState is LeaveTypesError ? leaveTypesState.message : null;
        final isLoadingLeaves = leaveTypesState is LeaveTypesLoading;

        return BlocListener<AttendancePunchBloc, AttendancePunchState>(
          listener: (context, punchState) {
            // Refresh attendance data after punch in/out success.

            if (punchState is AttendancePunchInSuccess &&
                (!punchState.isQueuedOffline ||
                    punchState.requiresServerRefresh)) {
              _refreshAttendanceOnly(); // only attendance, not everything
            }
            if (punchState is AttendancePunchOutSuccess &&
                (!punchState.isQueuedOffline ||
                    punchState.requiresServerRefresh)) {
              _refreshAttendanceOnly(); // only attendance, not everything
            }
          },
          child: ResponsiveScaffold(
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.backgroundMediumLight,
            body: RefreshIndicator(
              onRefresh: () async {
                _lastLoadedAt = null; // uncomment  — force refresh
                await _loadAllData(); // pull to refresh = all reload
              },
              child: BlocProvider.value(
                value: _notificationBloc,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with profile
                      AttendanceHeader(
                        userProfile: _userProfile,
                        onAvatarTap: widget.onOpenDrawer,
                        onCalenderTap: onCalenderTap,
                      ),
                      // Attendance Card (overlaps header by 20px, so no spacing needed)
                      AttendanceCard(
                        attendanceDetails: _attendanceDetails,
                        isLoading: _isLoadingAttendance,
                        onRefresh: _refreshAttendanceOnly,
                      ),
                      PunchDetails(
                        attendanceDetails: _attendanceDetails,
                        isLoading: _isLoadingAttendance,
                        errorMessage: _attendanceError,
                        onRefresh: _refreshAttendanceOnly,
                      ),
                      SizedBox(height: responsiveSpacing(10)),
                      // Attendance Summary
                      PermissionGuard(
                        requiredPermission: "Attendance:My Attendance:Read",
                        child: AttendanceSummary(
                          selectedDate: _selectedMonth,
                          onPreviousMonth: () => _changeSelectedMonth(-1),
                          onNextMonth: () => _changeSelectedMonth(1),
                          wfhDays: _leaveStats?.wfhDays ?? 0,
                          regularizeDays: _leaveStats?.regularizeDays ?? 0,
                          onDutyDays: _leaveStats?.onDutyDays ?? 0,
                          maxDays: _leaveStats?.totalDays ?? 30,
                          isLoading: _isLoadingLeaveStats,
                        ),
                      ),
                      SizedBox(height: responsiveSpacing(15)),
                      // Leaves Summary (from LeaveTypesBloc - shared with Apply Leave)
                      PermissionGuard(
                        requiredPermission: "Leave Management:My Leaves:Read",
                        child: LeavesSummary(
                          leaveTypes: leaveTypes,
                          isLoading: isLoadingLeaves,
                          errorMessage: leavesError,
                        ),
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
                      PermissionGuard(
                        requiredPermission: "Attendance:My Attendance:Read",
                        child: BlocBuilder<CalendarBloc, CalendarState>(
                          bloc: _calendarBloc,
                          builder: (context, calState) {
                            List<CalendarDayEntity> days = [];
                            bool calendarLoading = false;

                            if (calState is CalendarLoading) {
                              calendarLoading = true;
                            } else if (calState is CalendarLoaded) {
                              days = calState.days;
                            }

                            return AttendanceCalendar(
                              key: _calendarKey, // Key for handling the scroll
                              calendarDays: days,
                              isLoading: calendarLoading,
                              onMonthChanged: _loadCalendarData,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: responsiveSpacing(24)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
