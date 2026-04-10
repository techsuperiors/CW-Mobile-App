import 'package:collectivWork/core/widgets/permission_guard.dart';
import 'package:collectivWork/features/approval/presentation/pages/approval_bottom_sheet.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/module_permissions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/presentation/pages/app_loading_screen.dart';
import '../../../../core/utils/app_navigator.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/common/app_button.dart';
import '../../../authentication/presentation/bloc/auth_bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_bloc/auth_state.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../post/presentation/bloc/post_bloc.dart';
import '../../../post/presentation/pages/post_page.dart';
import '../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../user/presentation/bloc/user_profile_event.dart';
import '../../../user/presentation/bloc/user_profile_state.dart';
import '../cubit/home_page_cubit.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../../dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../../dashboard/domain/usecases/get_dashboard_stats.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../post/data/datasources/post_remote_datasource.dart';
import '../../../post/data/repositories/post_repository_impl.dart';
import '../../../post/domain/repositories/post_repository.dart';
import '../../../post/domain/usecases/bookmark_announcement_usecase.dart';
import '../../../post/domain/usecases/create_announcement_usecase.dart';
import '../../../post/domain/usecases/delete_announcement_usecase.dart';
import '../../../post/domain/usecases/generate_announcement_content_usecase.dart';
import '../../../post/domain/usecases/get_announcement_details_usecase.dart';
import '../../../post/domain/usecases/get_announcements_usecase.dart';
import '../../../post/domain/usecases/get_create_post_audience_departments_usecase.dart';
import '../../../post/domain/usecases/get_create_post_audience_users_usecase.dart';
import '../../../post/domain/usecases/get_post_menu_overview_usecase.dart';
import '../../../post/domain/usecases/like_announcement_usecase.dart';
import '../../../post/domain/usecases/mark_announcement_admin_remark_usecase.dart';
import '../../../post/domain/usecases/report_announcement_usecase.dart';
import '../../../post/domain/usecases/repost_announcement_usecase.dart';
import '../../../post/domain/usecases/remove_like_usecase.dart';
import '../../../post/domain/usecases/remove_bookmark_usecase.dart';
import '../../../post/domain/usecases/remove_repost_usecase.dart';
import '../../../post/domain/usecases/submit_poll_answer_usecase.dart';
import '../../../post/domain/usecases/update_announcement_usecase.dart';
import '../../../services/presentation/pages/services_page.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../../request/presentation/pages/request_bottom_sheet.dart';

/// Home page with bottom navigation
class HomePage extends StatefulWidget {
  final int? initialTabIndex;

  const HomePage({super.key, this.initialTabIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Connectivity _connectivity = Connectivity();
  late final DashboardBloc _dashboardBloc;
  late final PostRepository _postRepository;
  late final PostBloc _postBloc;
  late final GetAnnouncementDetailsUseCase _getAnnouncementDetailsUseCase;
  late final GetAnnouncementsUseCase _getAnnouncementsUseCase;
  late final CreateAnnouncementUseCase _createAnnouncementUseCase;
  late final GenerateAnnouncementContentUseCase
  _generateAnnouncementContentUseCase;
  late final GetCreatePostAudienceDepartmentsUseCase
  _getCreatePostAudienceDepartmentsUseCase;
  late final GetCreatePostAudienceUsersUseCase
  _getCreatePostAudienceUsersUseCase;
  late final GetPostMenuOverviewUseCase _getPostMenuOverviewUseCase;
  final Map<int, Widget> _loadedPages = {};
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _hadConnection = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapUserProfile();
    });
    _initializeConnectivityListener();

    final networkInfo = NetworkInfoImpl(Connectivity());
    _dashboardBloc = DashboardBloc(
      getDashboardStats: GetDashboardStats(
        DashboardRepositoryImpl(
          remoteDataSource: DashboardRemoteDataSourceImpl(),
          networkInfo: networkInfo,
        ),
      ),
    );

    final postApiClient = ApiClient(
      dio: Dio(),
      networkInfo: networkInfo,
      onTokenExpired: () {},
    );
    _postRepository = PostRepositoryImpl(
      remoteDataSource: PostRemoteDataSourceImpl(postApiClient),
      networkInfo: networkInfo,
    );
    _getAnnouncementDetailsUseCase = GetAnnouncementDetailsUseCase(
      _postRepository,
    );
    _getAnnouncementsUseCase = GetAnnouncementsUseCase(_postRepository);
    _createAnnouncementUseCase = CreateAnnouncementUseCase(_postRepository);
    _generateAnnouncementContentUseCase = GenerateAnnouncementContentUseCase(
      _postRepository,
    );
    _getCreatePostAudienceDepartmentsUseCase =
        GetCreatePostAudienceDepartmentsUseCase(_postRepository);
    _getCreatePostAudienceUsersUseCase = GetCreatePostAudienceUsersUseCase(
      _postRepository,
    );
    _getPostMenuOverviewUseCase = GetPostMenuOverviewUseCase(_postRepository);
    _postBloc = PostBloc(
      getAnnouncementsUseCase: _getAnnouncementsUseCase,
      getAnnouncementDetailsUseCase: _getAnnouncementDetailsUseCase,
      bookmarkAnnouncementUseCase: BookmarkAnnouncementUseCase(_postRepository),
      removeBookmarkUseCase: RemoveBookmarkUseCase(_postRepository),
      likeAnnouncementUseCase: LikeAnnouncementUseCase(_postRepository),
      markAnnouncementAdminRemarkUseCase: MarkAnnouncementAdminRemarkUseCase(
        _postRepository,
      ),
      reportAnnouncementUseCase: ReportAnnouncementUseCase(_postRepository),
      removeLikeUseCase: RemoveLikeUseCase(_postRepository),
      submitPollAnswerUseCase: SubmitPollAnswerUseCase(_postRepository),
      repostAnnouncementUseCase: RepostAnnouncementUseCase(_postRepository),
      removeRepostUseCase: RemoveRepostUseCase(_postRepository),
      deleteAnnouncementUseCase: DeleteAnnouncementUseCase(_postRepository),
      updateAnnouncementUseCase: UpdateAnnouncementUseCase(_postRepository),
    );

    _loadedPages[2] = AttendancePage(onOpenDrawer: _openDrawer);
  }

  void _bootstrapUserProfile() {
    final userProfileBloc = context.read<UserProfileBloc>();
    final userProfileState = userProfileBloc.state;

    if (userProfileState is UserProfileInitial ||
        userProfileState is UserProfileRecoveryRequired) {
      userProfileBloc.add(const LoadUserProfile());
    }
  }

  Future<void> _initializeConnectivityListener() async {
    final currentConnectivity = await _connectivity.checkConnectivity();
    _hadConnection = currentConnectivity != ConnectivityResult.none;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      final hasConnection = result != ConnectivityResult.none;
      if (hasConnection && !_hadConnection) {
        _refreshProfileOnConnectivityRestore();
      }
      _hadConnection = hasConnection;
    });
  }

  void _refreshProfileOnConnectivityRestore() {
    if (!mounted) return;

    final userProfileState = context.read<UserProfileBloc>().state;
    final shouldRefresh =
        userProfileState is UserProfileRecoveryRequired ||
        (userProfileState is UserProfileLoaded &&
            userProfileState.isStale &&
            !userProfileState.isRefreshing);

    if (shouldRefresh) {
      context.read<UserProfileBloc>().add(
        const LoadUserProfile(forceRefresh: true),
      );
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildTabPage(int index) {
    return _loadedPages.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return const ServicesPage();
        case 1:
          return PermissionGuard(
            anyOf: ModulePermissions.postRead,
            child: const PostPage(title: AppStrings.posts),
          );
        case 2:
          return AttendancePage(onOpenDrawer: _openDrawer);
        case 3:
          return const PlaceholderPage(title: AppStrings.request);
        case 4:
          return const PlaceholderPage(title: AppStrings.approval);
        default:
          return const SizedBox.shrink();
      }
    });
  }

  Future<void> _handleRecoveryLogout() async {
    final navigatorContext = AppNavigator.navigatorKey.currentContext;
    if (navigatorContext == null) return;

    navigatorContext.read<AuthBloc>().add(const LogoutRequested());
    final authState = await navigatorContext.read<AuthBloc>().stream.firstWhere(
      (state) => state is AuthUnauthenticated || state is AuthError,
    );

    if (!mounted || !navigatorContext.mounted) return;

    if (authState is AuthUnauthenticated) {
      Navigator.pushAndRemoveUntil(
        navigatorContext,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    if (authState is AuthError) {
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        SnackBar(
          content: Text(authState.failure.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _postBloc.close();
    _dashboardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PostRepository>.value(value: _postRepository),
        RepositoryProvider<GetPostMenuOverviewUseCase>.value(
          value: _getPostMenuOverviewUseCase,
        ),
        RepositoryProvider<GetCreatePostAudienceDepartmentsUseCase>.value(
          value: _getCreatePostAudienceDepartmentsUseCase,
        ),
        RepositoryProvider<GetCreatePostAudienceUsersUseCase>.value(
          value: _getCreatePostAudienceUsersUseCase,
        ),
        RepositoryProvider<CreateAnnouncementUseCase>.value(
          value: _createAnnouncementUseCase,
        ),
        RepositoryProvider<GenerateAnnouncementContentUseCase>.value(
          value: _generateAnnouncementContentUseCase,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _dashboardBloc),
          BlocProvider.value(value: _postBloc),
        ],
        child: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, userProfileState) {
            if (userProfileState is UserProfileInitial ||
                userProfileState is UserProfileLoading) {
              return const AppLoadingScreen();
            }

            if (userProfileState is UserProfileRecoveryRequired) {
              return _UserProfileRecoveryView(
                message: userProfileState.message,
                onRetry:
                    () => context.read<UserProfileBloc>().add(
                      const LoadUserProfile(forceRefresh: true),
                    ),
                onSignOut: _handleRecoveryLogout,
              );
            }

            if (userProfileState is! UserProfileLoaded) {
              return const AppLoadingScreen();
            }

            final showStaleBanner =
                userProfileState.isStale &&
                !userProfileState.isRefreshing &&
                (userProfileState.warningMessage?.isNotEmpty ?? false);

            return Scaffold(
              key: _scaffoldKey,
              drawer: const AppDrawer(),
              body: Column(
                children: [
                  if (showStaleBanner)
                    _UserProfileStaleBanner(
                      message:
                          userProfileState.warningMessage ??
                          AppStrings.accountSyncWarning,
                      onRetry:
                          () => context.read<UserProfileBloc>().add(
                            const LoadUserProfile(forceRefresh: true),
                          ),
                    ),
                  Expanded(
                    child: BlocBuilder<HomePageCubit, int>(
                      builder: (context, currentIndex) {
                        _buildTabPage(currentIndex);
                        return IndexedStack(
                          index: currentIndex,
                          children: List<Widget>.generate(5, (index) {
                            return TickerMode(
                              enabled: currentIndex == index,
                              child:
                                  _loadedPages[index] ??
                                  const SizedBox.shrink(),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: BlocBuilder<HomePageCubit, int>(
                builder: (context, currentIndex) {
                  return BottomNavBar(
                    currentIndex: currentIndex,
                    onTap: (index) {
                      if (index == currentIndex) return;
                      if (index == 3) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const RequestBottomSheet(),
                        );
                      } else {
                        if (index == 4) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const ApprovalBottomSheet(),
                          );
                        } else {
                          context.read<HomePageCubit>().switchTab(index);
                        }
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Placeholder page for features not yet implemented

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.construction,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            '$title ${AppStrings.feature}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.comingSoon,
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _UserProfileStaleBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _UserProfileStaleBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.sync_problem_outlined, color: AppColors.warning),
            AppSpacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.accountSyncWarning,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.vXs,
                  Text(
                    message,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            AppSpacing.hMd,
            TextButton(
              onPressed: onRetry,
              child: Text(
                AppStrings.retry,
                style: AppTextStyles.labelLarge(
                  context,
                ).copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserProfileRecoveryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Future<void> Function() onSignOut;

  const _UserProfileRecoveryView({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.attendanceLightRedBg,
                      borderRadius: BorderRadius.circular(AppSpacing.xl),
                    ),
                    child: const Icon(
                      Icons.sync_problem_outlined,
                      color: AppColors.error,
                      size: AppSpacing.section,
                    ),
                  ),
                  AppSpacing.vXl,
                  Text(
                    AppStrings.accountLoadFailedTitle,
                    style: AppTextStyles.heading3(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vMd,
                  Text(
                    AppStrings.accountLoadFailedDescription,
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vSm,
                  Text(
                    message,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vXl,
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: AppStrings.logout,
                          isPrimary: false,
                          isOutlined: true,
                          onPressed: () {
                            onSignOut();
                          },
                        ),
                      ),
                      AppSpacing.hMd,
                      Expanded(
                        child: AppButton(
                          label: AppStrings.retry,
                          onPressed: onRetry,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
