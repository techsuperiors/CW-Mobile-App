import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../leaves/data/datasources/leave_types_remote_datasource.dart';
import '../../../../../../../leaves/data/repositories/leave_types_repository_impl.dart';
import '../../../../../../../leaves/domain/usecases/get_leave_types_usecase.dart';
import '../../../../../../../leaves/domain/usecases/apply_leave_usecase.dart';
import '../../../../../../../leaves/domain/usecases/delete_leave_file_usecase.dart';
import '../../../../../../../leaves/domain/usecases/update_leave_usecase.dart';
import '../../../../../../../leaves/domain/usecases/upload_leave_files_usecase.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../bloc/leave_request_bloc.dart';
import '../bloc/leave_request_event.dart';
import '../bloc/leave_request_state.dart';
import '../widgets/leave_type_card.dart';

/// Leave Request page showing different leave types with statistics
class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key});

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  late final LeaveRequestBloc _leaveRequestBloc;
  bool _hasLoaded = false;

  // Helper function to get color for leave type
  Color _getLeaveTypeColor(String leaveCode) {
    final code = leaveCode.toUpperCase().trim();

    switch (code) {
      case 'LOP':
        return AppColors.error;

      case 'EL': // Earned Leave
        return AppColors.leaveEarned;

      case 'CL': // Casual Leave
        return AppColors.leaveCasual;

      case 'CLF': // Casual Leave Female (ya variant)
        return AppColors.leavecompoff;

      case 'SL': // Sick Leave
        return AppColors.leaveSick;

      case 'PLV': // Privilege Leave
        return AppColors.leaveprivilage;
      case 'OCL': // Privilege Leave
        return AppColors.ozicasualLeave;

      default:
        return AppColors.serviceTeal;
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize dependencies
    final networkInfo = NetworkInfoImpl(Connectivity());
    final dio = Dio();
    final apiClient = ApiClient(dio: dio, networkInfo: networkInfo);
    final remoteDataSource = LeaveTypesRemoteDataSourceImpl(apiClient);
    final repository = LeaveTypesRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    final getLeaveTypesUseCase = GetLeaveTypesUseCase(repository);
    final applyLeaveUseCase = ApplyLeaveUseCase(repository);
    final updateLeaveUseCase = UpdateLeaveUseCase(repository);
    final uploadLeaveFilesUseCase = UploadLeaveFilesUseCase(repository);
    final deleteLeaveFileUseCase = DeleteLeaveFileUseCase(repository);
    _leaveRequestBloc = LeaveRequestBloc(
      getLeaveTypesUseCase: getLeaveTypesUseCase,
      applyLeaveUseCase: applyLeaveUseCase,
      updateLeaveUseCase: updateLeaveUseCase,
      uploadLeaveFilesUseCase: uploadLeaveFilesUseCase,
      deleteLeaveFileUseCase: deleteLeaveFileUseCase,
    );
  }

  @override
  void dispose() {
    _leaveRequestBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _leaveRequestBloc,
      child: ResponsiveScaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
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
            AppStrings.leaveRequest,
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
        body: BlocBuilder<UserProfileBloc, UserProfileState>(
          builder: (context, profileState) {
            // Get user_id from profile and load leave request details once
            if (profileState is UserProfileLoaded && !_hasLoaded) {
              final userId = profileState.profile.userId;
              _hasLoaded = true;
              _leaveRequestBloc.add(LoadLeaveRequestDetails(userId));
            }

            return BlocBuilder<LeaveRequestBloc, LeaveRequestState>(
              builder: (context, state) {
                if (state is LeaveRequestLoading ||
                    profileState is! UserProfileLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is LeaveRequestError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: MediaQuery.of(context).size.width * 0.15,
                          color: AppColors.error,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Text(
                          state.message,
                          style: AppTextStyles.bodyMedium(context),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (state is LeaveRequestLoaded) {
                  final leaveTypes = state.leaveTypes.leaveTypes;
                  // Separate LOP from other leave types
                  final lopLeaves =
                      leaveTypes.where((lt) {
                        final name = (lt.leaveType ?? "").trim().toUpperCase();
                        final code = (lt.leaveCode ?? "").trim().toUpperCase();
                        return name == "LOP" || code == "LOP";
                      }).toList();

                  final otherLeaves =
                      leaveTypes.where((lt) {
                        final type = lt.leaveType.trim().toUpperCase();
                        final code = lt.leaveCode.trim().toUpperCase();
                        return type != 'LOP' && code != 'LOP';
                      }).toList();
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.01,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Loss of Pay (LOP) Card
                        ...otherLeaves.map((leaveType) {
                          return Column(
                            children: [
                              LeaveTypeCard(
                                title: leaveType.leaveType,
                                totalLeaves:
                                    (leaveType.remainingLeaves ??
                                            leaveType.count)
                                        .toDouble(),
                                consumed:
                                    (leaveType.consumedLeaves ?? 0).toDouble(),
                                allocatedQuota:
                                    (leaveType.allocatedQuota ??
                                            leaveType.annualQuota ??
                                            0)
                                        .toDouble(),
                                annualQuota:
                                    (leaveType.annualQuota ?? 0).toDouble(),
                                accruedSoFar: leaveType.allocatedLeave,
                                color: _getLeaveTypeColor(leaveType.leaveCode),
                                isLOP: false,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                            ],
                          );
                        }),

                        if (state.leaveTypes.lossOffPay && lopLeaves.isNotEmpty)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                        if (lopLeaves.isNotEmpty)
                          LeaveTypeCard(
                            title: 'Loss of Pay (LOP)',
                            totalLeaves:
                                (lopLeaves.first.currentMonthLop ??
                                        lopLeaves.first.totalLeaves ??
                                        0)
                                    .toDouble(),
                            consumed:
                                (lopLeaves.first.consumedLeaves ?? 0)
                                    .toDouble(),
                            allocatedQuota:
                                (lopLeaves.first.totalLeaves ?? 0).toDouble(),
                            annualQuota:
                                (lopLeaves.first.totalLeaves ?? 0).toDouble(),
                            accruedSoFar: lopLeaves.first.allocatedLeave,
                            color: _getLeaveTypeColor('LOP'),
                            isLOP: true,
                          ),
                        // Other leave types
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }
}
