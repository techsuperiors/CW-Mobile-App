import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../approval/presentation/widgets/approval_action_bar.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../bloc/overtime_detail_bloc.dart';
import '../../bloc/overtime_detail_event.dart';
import '../../bloc/overtime_detail_state.dart';
import '../../data/datasources/overtime_remote_datasource.dart';
import '../../data/repositories/overtime_repository_impl.dart';
import '../../domain/entities/overtime_detail.dart';
import '../../domain/usecases/add_overtime_request_comment.dart';
import '../../domain/usecases/get_overtime_request_comments.dart';
import '../../domain/usecases/get_overtime_request_detail.dart';
import '../../domain/usecases/withdraw_overtime_request.dart';
import '../../models/overtime_request_model.dart';
import '../widgets/overtime_activity_bottom_sheet.dart';
import 'apply_overtime_page.dart';

class OvertimeDetailPage extends StatefulWidget {
  final OvertimeRequestModel overtimeRequest;
  final bool isApprovalMode;

  const OvertimeDetailPage({
    super.key,
    required this.overtimeRequest,
    this.isApprovalMode = false,
  });

  @override
  State<OvertimeDetailPage> createState() => _OvertimeDetailPageState();
}

class _OvertimeDetailPageState extends State<OvertimeDetailPage> {
  final _commentController = TextEditingController();
  late final OvertimeDetailBloc _overtimeDetailBloc;
  bool _shouldRefreshListing = false;

  OvertimeRequestModel get _fallbackRequest => widget.overtimeRequest;

  int get _clientId => _resolveClientId();

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo,onTokenExpired: () {
      AppNavigator.pushAndRemoveAll(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    },);
    final remoteDataSource = OvertimeRemoteDataSourceImpl(apiClient: apiClient);
    final repository = OvertimeRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
    _overtimeDetailBloc = OvertimeDetailBloc(
      getOvertimeRequestDetailUseCase: GetOvertimeRequestDetailUseCase(
        repository,
      ),
      withdrawOvertimeRequestUseCase: WithdrawOvertimeRequestUseCase(
        repository,
      ),
      getOvertimeRequestCommentsUseCase: GetOvertimeRequestCommentsUseCase(
        repository,
      ),
      addOvertimeRequestCommentUseCase: AddOvertimeRequestCommentUseCase(
        repository,
      ),
    )..add(
      LoadOvertimeDetail(
        requestId: int.tryParse(widget.overtimeRequest.id) ?? 0,
        clientId: _clientId,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _overtimeDetailBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return BlocProvider.value(
      value: _overtimeDetailBloc,
      child: BlocConsumer<OvertimeDetailBloc, OvertimeDetailState>(
        listenWhen: (previous, current) {
          if (current is! OvertimeDetailError) return true;
          final isInitialLoadFailure =
              current.detail == null &&
              (previous is OvertimeDetailInitial ||
                  previous is OvertimeDetailLoading);
          return !isInitialLoadFailure;
        },
        listener: (context, state) {
          if (state is OvertimeDetailStatusUpdated) {
            _shouldRefreshListing = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            if (widget.isApprovalMode && Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          } else if (state is OvertimeDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ErrorMessageMapper.toUserFriendlyMessage(state.message),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final detail = _detailFromState(state);
          final currentRequest = _currentRequest(detail);
          final comments = _commentsFromState(state);
          final isBusy =
              state is OvertimeDetailLoading ||
              state is OvertimeDetailStatusUpdating ||
              state is OvertimeCommentSubmitting;
          return Stack(
            children: [
              ResponsiveScaffold(
                backgroundColor: AppColors.backgroundMedium,
                appBar: AppBar(
                  forceMaterialTransparency: true,
                  elevation: 0,
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  leading: GestureDetector(
                    onTap:
                        () => Navigator.of(context).pop(_shouldRefreshListing),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: Theme.of(context).colorScheme.primary,
                          size: screenWidth * 0.048, // 4.8% of screen width
                        ),
                        Flexible(
                          child: Text(
                            'Back',
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
                    widget.isApprovalMode ? 'Overtime Approval' : 'Overtime',
                    style: AppTextStyles.heading4(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  centerTitle: true,
                ),

                bottomNavigationBar:
                    widget.isApprovalMode
                        ? BottomNavBar(
                      currentIndex: 4,
                      onTap: NavigationHelper.getBottomNavHandler(context),
                    )
                        : BottomNavBar(
                          currentIndex: 3,
                          onTap: NavigationHelper.getBottomNavHandler(context),
                        ),
                body:
                    state is OvertimeDetailError && state.detail == null
                        ? ApiErrorState(
                          title: 'Unable to load overtime details',
                          rawMessage: state.message,
                          onRetry:
                              () => context.read<OvertimeDetailBloc>().add(
                                LoadOvertimeDetail(
                                  requestId:
                                      int.tryParse(widget.overtimeRequest.id) ??
                                      0,
                                  clientId: _clientId,
                                ),
                              ),
                        )
                        : _buildContent(context, currentRequest, comments),
              ),
              if (isBusy)
                Container(
                  color: Colors.black.withValues(alpha: 0.08),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OvertimeRequestModel currentRequest,
    List<AttendanceRequestComment> comments,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final statusColor = _getStatusColor(currentRequest.status);
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.002),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailsCard(context, currentRequest, statusColor),
          SizedBox(height: screenHeight * 0.02),
          _buildCommentsSection(context, comments),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    OvertimeRequestModel currentRequest,
    Color statusColor,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final detail = _detailFromState(_overtimeDetailBloc.state);
    final requestDate = detail?.requestDate ?? currentRequest.requestDate;
    final checkIn = detail?.checkIn;
    final checkOut = detail?.checkOut;
    final totalHours = detail?.totalHours;
    final requestId = int.tryParse(widget.overtimeRequest.id) ?? 0;
    final isPending = currentRequest.status == OvertimeStatus.pending;
    final menuActions = <Map<String, String>>[
      if (isPending && !widget.isApprovalMode)
        {'value': 'Edit', 'icon': AppAssets.editIconwfh},
      // if (isPending && !widget.isApprovalMode)
      //   {'value': 'Withdraw', 'icon': AppAssets.withdrawIcon},
      {'value': 'Activity', 'icon': AppAssets.activityIcon},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentRequest.subject,
                style: AppTextStyles.heading4(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: statusColor),
              ),
              if (menuActions.length >= 2)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
                  onSelected: (value) async {
                    if (value == 'Edit') {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ApplyOvertimePage(
                                overtimeRequest: currentRequest,
                                overtimeDetail: detail,
                              ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        _shouldRefreshListing = true;
                        context.read<OvertimeDetailBloc>().add(
                          LoadOvertimeDetail(
                            requestId: requestId,
                            clientId: _clientId,
                          ),
                        );
                      }
                    }
                    // else if (value == 'Withdraw') {
                    //   context.read<OvertimeDetailBloc>().add(
                    //     UpdateOvertimeRequestStatus(
                    //       requestId: requestId,
                    //       clientId: _clientId,
                    //       status: 'Withdrawn',
                    //     ),
                    //   );
                    // }
                    else if (value == 'Activity') {
                      _showActivityBottomSheet(
                        context,
                        detail?.activity ?? const [],
                      );
                    }
                  },
                  itemBuilder: (_) {
                    return menuActions.map((action) {
                      return PopupMenuItem(
                        value: action['value'],
                        child: Row(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.05,
                              height: screenHeight * 0.05,
                              child: SvgPicture.asset(action['icon']!),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              action['value']!,
                              style: AppTextStyles.heading5(context).copyWith(
                                fontWeight: FontWeight.w400,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                )
              else if (menuActions.length == 1)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final action = menuActions.first['value'];
                    if (action == 'Edit') {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ApplyOvertimePage(
                                overtimeRequest: currentRequest,
                                overtimeDetail: detail,
                              ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        _shouldRefreshListing = true;
                        context.read<OvertimeDetailBloc>().add(
                          LoadOvertimeDetail(
                            requestId: requestId,
                            clientId: _clientId,
                          ),
                        );
                      }
                    }
                    // else if (action == 'Withdraw') {
                    //   context.read<OvertimeDetailBloc>().add(
                    //     UpdateOvertimeRequestStatus(
                    //       requestId: requestId,
                    //       clientId: _clientId,
                    //       status: 'Withdrawn',
                    //     ),
                    //   );
                    // }
                    else if (action == 'Activity') {
                      _showActivityBottomSheet(
                        context,
                        detail?.activity ?? const [],
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SizedBox(
                      width: screenWidth * 0.06,
                      height: screenHeight * 0.03,
                      child: SvgPicture.asset(menuActions.first['icon']!),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          _buildDetailRow(
            context,
            'Subject:',
            currentRequest.subject,
            screenWidth,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Request Date:',
            DateFormat('dd MMM yyyy').format(requestDate),
            screenWidth,
          ),
          if (checkIn != null) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'Check In:',
              DateFormat('dd MMM yyyy, hh:mm a').format(checkIn),
              screenWidth,
            ),
          ],
          if (checkOut != null) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'Check Out:',
              DateFormat('dd MMM yyyy, hh:mm a').format(checkOut),
              screenWidth,
            ),
          ],
          if (totalHours != null && totalHours.trim().isNotEmpty) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'Total Overtime hours:',
              _formatTotalOvertimeHours(totalHours),
              screenWidth,
            ),
          ],
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Applied On:',
            DateFormat(
              'dd MMM yyyy, hh:mm a',
            ).format(currentRequest.appliedDate),
            screenWidth,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildApproversRow(
            context,
            screenWidth,
            detail?.approvers ?? const [],
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: screenWidth * 0.3,
                child: Text(
                  'Status:',
                  style: AppTextStyles.bodyMediumHeading(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.032,
                  vertical: screenHeight * 0.004,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentRequest.status.displayName,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),

          _buildDescriptionSection(
            context,
            screenWidth,
            screenHeight,
            currentRequest,
            requestId,
            detail?.description?.isNotEmpty == true
                ? detail!.description!
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildApproversRow(
    BuildContext context,
    double screenWidth,
    List<OvertimeApprovalLevel> approvers,
  ) {
    final approverUsers = approvers.expand((level) => level.users).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: screenWidth * 0.3,
          child: Text(
            'Approvers:',
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textHeading,
            ),
          ),
        ),
        const Spacer(),
        if (approverUsers.isNotEmpty)
          GestureDetector(
            onTap: () => _showApproversSheet(context, approvers),
            child: Row(
              children: [
                _OvertimeApproverAvatarStack(
                  users: approverUsers,
                  avatarSize: screenWidth * 0.07,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  approverUsers.length == 1
                      ? approverUsers.first.fullName
                      : '${approverUsers.length} approvers',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          Text('—', style: AppTextStyles.bodySmall(context)),
      ],
    );
  }

  Widget _buildDescriptionSection(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    OvertimeRequestModel currentRequest,
    int requestId,
    String description,
  ) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      // padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTextStyles.heading5(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Text(
            description,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          if (widget.isApprovalMode &&
              currentRequest.status == OvertimeStatus.pending &&
              currentRequest.isEligibleToApprove) ...[
            SizedBox(height: screenHeight * 0.02),
            BlocBuilder<OvertimeDetailBloc, OvertimeDetailState>(
              builder: (context, state) {
                return ApprovalActionBar(
                  embedded: true,
                  isLoading: state is OvertimeDetailStatusUpdating,
                  onApprove:
                      requestId <= 0
                          ? null
                          : () {
                            context.read<OvertimeDetailBloc>().add(
                              UpdateOvertimeRequestStatus(
                                requestId: requestId,
                                clientId: _clientId,
                                status: 'Approved',
                              ),
                            );
                          },
                  onReject:
                      requestId <= 0
                          ? null
                          : () {
                            context.read<OvertimeDetailBloc>().add(
                              UpdateOvertimeRequestStatus(
                                requestId: requestId,
                                clientId: _clientId,
                                status: 'Rejected',
                              ),
                            );
                          },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
    BuildContext context,
    List<AttendanceRequestComment> comments,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: AppTextStyles.heading5(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: screenHeight * 0.002),
          if (comments.isNotEmpty) ...[
            ...comments.map(
              (comment) => Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.012),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.032),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: screenWidth * 0.09,
                            height: screenWidth * 0.09,
                            decoration: BoxDecoration(
                              color: AppColors.serviceBlueBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials(comment.user?.fullName ?? 'User'),
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.user?.fullName ?? 'User',
                                  style: AppTextStyles.bodyMediumHeading(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: screenHeight * 0.002),
                                Text(
                                  comment.createdAt != null
                                      ? DateFormat(
                                        'dd MMM yyyy, hh:mm a',
                                      ).format(comment.createdAt!)
                                      : 'Just now',
                                  style: AppTextStyles.bodySmall(
                                    context,
                                  ).copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.012),
                      Text(
                        comment.comment,
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: AppColors.textPrimary, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
          ],

          // ...comments.map(
          //   (comment) => Padding(
          //     padding: EdgeInsets.only(bottom: screenHeight * 0.012),
          //     child: Text(
          //       '${comment.user?.fullName.isNotEmpty == true ? comment.user!.fullName : 'User'}: ${comment.comment}',
          //     ),
          //   ),
          // ),
          SizedBox(height: screenHeight * 0.02),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final comment = _commentController.text.trim();
                if (comment.isEmpty) return;
                context.read<OvertimeDetailBloc>().add(
                  AddOvertimeComment(
                    requestId: int.tryParse(widget.overtimeRequest.id) ?? 0,
                    clientId: _clientId,
                    comment: comment,
                  ),
                );
                _commentController.clear();
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .toList();
    if (parts.isEmpty) return 'U';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  String _formatTotalOvertimeHours(String rawValue) {
    final trimmedValue = rawValue.trim();
    if (trimmedValue.isEmpty) {
      return '—';
    }

    final timePattern = RegExp(r'^(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?$');
    final timeMatch = timePattern.firstMatch(trimmedValue);
    if (timeMatch != null) {
      final hours = int.tryParse(timeMatch.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
      final seconds = int.tryParse(timeMatch.group(3) ?? '') ?? 0;
      final roundedMinutes = minutes + (seconds >= 30 ? 1 : 0);
      final normalizedHours = hours + (roundedMinutes ~/ 60);
      final normalizedMinutes = roundedMinutes % 60;
      return '${normalizedHours.toString().padLeft(2, '0')}h ${normalizedMinutes.toString().padLeft(2, '0')}m';
    }

    final numericValue = double.tryParse(trimmedValue);
    if (numericValue != null) {
      final totalMinutes =
          trimmedValue.contains('.')
              ? (numericValue * 60).round()
              : (numericValue / 60).round();
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    }

    return trimmedValue;
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    double screenWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: screenWidth * 0.3,
          child: Text(
            label,
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textHeading,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  void _showActivityBottomSheet(
    BuildContext context,
    List<OvertimeActivity> activity,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: OvertimeActivityBottomSheet(
                    scrollController: scrollController,
                    activity: activity,
                  ),
                ),
          ),
    );
  }

  void _showApproversSheet(
    BuildContext context,
    List<OvertimeApprovalLevel> approvers,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder:
                (ctx, sc) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: _OvertimeApproversSheetContent(
                    approvers: approvers,
                    scrollController: sc,
                    sw: MediaQuery.of(context).size.width,
                  ),
                ),
          ),
    );
  }

  OvertimeDetail? _detailFromState(OvertimeDetailState state) {
    if (state is OvertimeDetailLoaded) return state.detail;
    if (state is OvertimeDetailStatusUpdating) return state.detail;
    if (state is OvertimeCommentSubmitting) return state.detail;
    if (state is OvertimeDetailError) return state.detail;
    return null;
  }

  List<AttendanceRequestComment> _commentsFromState(OvertimeDetailState state) {
    if (state is OvertimeDetailLoaded) return state.comments;
    if (state is OvertimeDetailStatusUpdating) return state.comments;
    if (state is OvertimeCommentSubmitting) return state.comments;
    if (state is OvertimeDetailError) return state.comments;
    return const [];
  }

  OvertimeRequestModel _currentRequest(OvertimeDetail? detail) {
    if (detail == null) return _fallbackRequest;
    return _fallbackRequest.copyWith(
      id: detail.id.toString(),
      subject: detail.subject,
      requestDate: detail.requestDate ?? _fallbackRequest.requestDate,
      status: OvertimeRequestModel.parseStatusValue(detail.status),
      appliedDate: detail.createdAt ?? _fallbackRequest.appliedDate,
    );
  }

  int _resolveClientId() {
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is UserProfileLoaded) {
      return profileState.profile.clientId;
    }
    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) return 0;
    final decoded = decodeData<Map<String, dynamic>>(token);
    final clientId = decoded?['client_id'];
    if (clientId is int) return clientId;
    if (clientId is String) return int.tryParse(clientId) ?? 0;
    return 0;
  }

  Color _getStatusColor(OvertimeStatus status) {
    switch (status) {
      case OvertimeStatus.pending:
        return AppColors.approvalSheetPending; //
      case OvertimeStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case OvertimeStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case OvertimeStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
    }
  }
}

class _OvertimeApproversSheetContent extends StatelessWidget {
  final List<OvertimeApprovalLevel> approvers;
  final ScrollController scrollController;
  final double sw;

  const _OvertimeApproversSheetContent({
    required this.approvers,
    required this.scrollController,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(sw * 0.04),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          'Approvers',
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (approvers.isEmpty)
          Text(
            'No approvers found.',
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textSecondary),
          )
        else
          ...approvers.map(
            (level) => _OvertimeApproverLevel(level: level, sw: sw),
          ),
      ],
    );
  }
}

class _OvertimeApproverLevel extends StatelessWidget {
  final OvertimeApprovalLevel level;
  final double sw;

  const _OvertimeApproverLevel({required this.level, required this.sw});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          level.level.toLowerCase().contains('super')
              ? level.level
              : 'Level ${level.level}',
          style: AppTextStyles.bodyMediumHeading(
            context,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...level.users.map((user) => _OvertimeApproverTile(user: user, sw: sw)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _OvertimeApproverTile extends StatelessWidget {
  final OvertimeApprover user;
  final double sw;

  const _OvertimeApproverTile({required this.user, required this.sw});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    switch (user.approvalStatus.toLowerCase()) {
      case 'approved':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'rejected':
        statusColor = const Color(0xFFE53935);
        break;
      default:
        statusColor = const Color(0xFF2196F3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(sw * 0.03),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: sw * 0.05,
            backgroundColor: _parseHexColor(user.profileColor),
            backgroundImage:
                user.imageUrl != null && user.imageUrl!.isNotEmpty
                    ? NetworkImage(user.imageUrl!)
                    : null,
            child:
                user.imageUrl == null || user.imageUrl!.isEmpty
                    ? Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                    : null,
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : 'Approver',
                  style: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                if (user.email?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.email!,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.approvalStatus,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _OvertimeApproverAvatarStack extends StatelessWidget {
  final List<OvertimeApprover> users;
  final double avatarSize;

  const _OvertimeApproverAvatarStack({
    required this.users,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.take(3).toList();
    final overlap = avatarSize * 0.35;
    final edgePadding = avatarSize * 0.08;

    final width =
        visibleUsers.length == 1
            ? avatarSize + (edgePadding * 2)
            : avatarSize +
                ((visibleUsers.length - 1) * (avatarSize - overlap)) +
                (edgePadding * 2);

    return SizedBox(
      width: width,
      height: avatarSize + (edgePadding * 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visibleUsers.length; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: avatarSize / 2,
                  backgroundColor: _parseHexColor(visibleUsers[i].profileColor),
                  backgroundImage:
                      visibleUsers[i].imageUrl != null &&
                              visibleUsers[i].imageUrl!.isNotEmpty
                          ? NetworkImage(visibleUsers[i].imageUrl!)
                          : null,
                  child:
                      visibleUsers[i].imageUrl == null ||
                              visibleUsers[i].imageUrl!.isEmpty
                          ? Text(
                            visibleUsers[i].fullName.isNotEmpty
                                ? visibleUsers[i].fullName[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.bodyMedium(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                          : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _parseHexColor(String hex) {
  final normalized = hex.replaceAll('#', '');
  final value = int.tryParse('FF$normalized', radix: 16);
  if (value == null) return AppColors.primary;
  return Color(value);
}
