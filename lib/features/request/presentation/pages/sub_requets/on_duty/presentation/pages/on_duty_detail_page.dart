import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/network/api_service.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../approval/presentation/widgets/approval_action_bar.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../../../../bloc/approvers/approvers_bloc.dart';
import '../../bloc/on_duty_detail_bloc.dart';
import '../../bloc/on_duty_detail_event.dart';
import '../../bloc/on_duty_detail_state.dart';
import '../../data/datasources/on_duty_remote_datasource.dart';
import '../../data/repositories/on_duty_repository_impl.dart';
import '../../domain/entities/on_duty_detail.dart';
import '../../domain/usecases/add_on_duty_request_comment.dart';
import '../../domain/usecases/get_on_duty_request_comments.dart';
import '../../domain/usecases/get_on_duty_request_detail.dart';
import '../../domain/usecases/update_on_duty_request_status.dart';
import '../../models/on_duty_request_model.dart';
import '../../../leaves/data/datasources/approvers_remote_datasource.dart';
import '../../../leaves/data/repositories/approvers_repository_impl.dart';
import '../../../leaves/domain/usecases/get_approvers.dart';
import '../../../leaves/presentation/widgets/approvers_section.dart';
import '../widgets/on_duty_activity_bottom_sheet.dart';

class OnDutyDetailPage extends StatefulWidget {
  final OnDutyRequestModel onDutyRequest;
  final bool isApprovalMode;

  const OnDutyDetailPage({
    super.key,
    required this.onDutyRequest,
    this.isApprovalMode = false,
  });

  @override
  State<OnDutyDetailPage> createState() => _OnDutyDetailPageState();
}

class _OnDutyDetailPageState extends State<OnDutyDetailPage> {
  final _commentController = TextEditingController();
  late final OnDutyDetailBloc _onDutyDetailBloc;
  bool _shouldRefreshListing = false;

  OnDutyRequestModel get _fallbackRequest => widget.onDutyRequest;

  int get _clientId => _resolveClientId();

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = OnDutyRemoteDataSourceImpl(apiClient: apiClient);
    final repository = OnDutyRepositoryImpl(remoteDataSource: remoteDataSource);

    _onDutyDetailBloc = OnDutyDetailBloc(
      getOnDutyRequestDetailUseCase: GetOnDutyRequestDetailUseCase(repository),
      updateOnDutyRequestStatusUseCase: UpdateOnDutyRequestStatusUseCase(
        repository,
      ),
      getOnDutyRequestCommentsUseCase: GetOnDutyRequestCommentsUseCase(
        repository,
      ),
      addOnDutyRequestCommentUseCase: AddOnDutyRequestCommentUseCase(
        repository,
      ),
    )..add(
      LoadOnDutyDetail(
        requestId: int.tryParse(widget.onDutyRequest.id) ?? 0,
        clientId: _clientId,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _onDutyDetailBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider.value(
      value: _onDutyDetailBloc,
      child: BlocConsumer<OnDutyDetailBloc, OnDutyDetailState>(
        listener: (context, state) {
          if (state is OnDutyDetailStatusUpdated) {
            _shouldRefreshListing = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is OnDutyDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final screenHeight = MediaQuery.of(context).size.height;
          final detail = _detailFromState(state);
          final currentRequest = _currentRequest(detail);
          final comments = _commentsFromState(state);
          final isBusy =
              state is OnDutyDetailLoading ||
              state is OnDutyDetailStatusUpdating ||
              state is OnDutyCommentSubmitting;

          return WillPopScope(
            onWillPop: () async {
              Navigator.of(context).pop(_shouldRefreshListing);
              return false;
            },
            child: Stack(
              children: [
                ResponsiveScaffold(
                  backgroundColor: AppColors.backgroundMedium,
                  appBar: AppBar(
                    elevation: 0,
                    forceMaterialTransparency: true,
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    leading: GestureDetector(
                      onTap:
                          () =>
                              Navigator.of(context).pop(_shouldRefreshListing),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Theme.of(context).colorScheme.primary,
                            size: screenWidth * 0.048,
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
                      widget.isApprovalMode ? 'On Duty Approval' : 'On Duty',
                      style: AppTextStyles.heading4(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  bottomNavigationBar:
                      widget.isApprovalMode
                          ? null
                          : BottomNavBar(
                            currentIndex: 3,
                            onTap: NavigationHelper.getBottomNavHandler(context),
                          ),
                  body: _buildDetailsContent(
                    context,
                    screenWidth,
                    screenHeight,
                    currentRequest,
                    comments,
                    detail,
                  ),
                ),
                if (isBusy)
                  Container(
                    color: Colors.black.withOpacity(0.08),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsContent(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    OnDutyRequestModel currentRequest,
    List<AttendanceRequestComment> comments,
    OnDutyDetail? detail,
  ) {
    final statusColor = _getStatusColor(currentRequest.status);

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.002),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail != null)
            _buildDetailsCard(
              context,
              screenWidth,
              screenHeight,
              currentRequest,
              statusColor,
              detail,
              comments
            )

          // shown while loading

        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    OnDutyRequestModel currentRequest,
    Color statusColor,
    OnDutyDetail? onDutyDetail,
      List<AttendanceRequestComment> comments
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isSingleDay =
        currentRequest.requestType?.toLowerCase() == 'single' ||
        currentRequest.toDate == null;
    final requestId = int.tryParse(widget.onDutyRequest.id) ?? 0;
    final isPending = currentRequest.status == OnDutyStatus.pending;
    final menuActions = <Map<String, String>>[
      if (isPending && !widget.isApprovalMode)
        {'value': 'Withdraw', 'icon': AppAssets.withdrawIcon},
      {'value': 'Activity', 'icon': AppAssets.activityIcon},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentRequest.subject?.isNotEmpty == true
                    ? currentRequest.subject!
                    : 'On Duty Request',
                style: AppTextStyles.heading4(
                  context,
                ).copyWith(fontWeight: FontWeight.w700, color: statusColor),
              ),
              if (menuActions.length >= 2)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
                  onSelected: (value) {
                    if (value == 'Withdraw') {
                      context.read<OnDutyDetailBloc>().add(
                        UpdateOnDutyRequestStatus(
                          requestId: requestId,
                          clientId: _clientId,
                          status: 'Withdrawn',
                        ),
                      );
                    } else if (value == 'Activity') {
                      final activity = onDutyDetail?.activity;

                      if (activity == null || activity.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No activity found for this request.',
                            ),
                            backgroundColor: Colors.grey,
                          ),
                        );
                        return;
                      }

                      _showActivityBottomSheet(context, activity);
                    }
                  },
                  itemBuilder: (context) {
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
                  onTap: () {
                    final action = menuActions.first['value'];
                    if (action == 'Withdraw') {
                      context.read<OnDutyDetailBloc>().add(
                        UpdateOnDutyRequestStatus(
                          requestId: requestId,
                          clientId: _clientId,
                          status: 'Withdrawn',
                        ),
                      );
                    } else if (action == 'Activity') {
                      final activity = onDutyDetail?.activity;

                      if (activity == null || activity.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No activity found for this request.',
                            ),
                            backgroundColor: Colors.grey,
                          ),
                        );
                        return;
                      }

                      _showActivityBottomSheet(context, activity);
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

          SizedBox(height: screenHeight * 0.02),
          _buildDetailRow(
            context,
            'Subject:',
            currentRequest.subject?.isNotEmpty == true
                ? currentRequest.subject!
                : 'N/A',
            screenWidth,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Request Type:',
            isSingleDay ? 'Single Day' : 'Multiple Days',
            screenWidth,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'No. of Days:',
            currentRequest.numberOfDays.toString().padLeft(2, '0'),
            screenWidth,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'From:',
            dateFormat.format(currentRequest.fromDate),
            screenWidth,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'To:',
            currentRequest.toDate != null
                ? dateFormat.format(currentRequest.toDate!)
                : dateFormat.format(currentRequest.fromDate),
            screenWidth,
          ),
          if (currentRequest.startHalf != null) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'Start Half:',
              _formatHalf(currentRequest.startHalf!),
              screenWidth,
            ),
          ],
          if (currentRequest.endHalf != null) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'End Half:',
              _formatHalf(currentRequest.endHalf!),
              screenWidth,
            ),
          ],
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Applied On:',
            dateTimeFormat.format(currentRequest.appliedDate),
            screenWidth,
          ),
          if (currentRequest.rejectRemark?.isNotEmpty == true) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'Reject Remark:',
              currentRequest.rejectRemark!,
              screenWidth,
            ),
          ],
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildApproversRow(
            context,
            screenWidth,
            onDutyDetail?.approvers ?? const [],
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
                  vertical: screenHeight * 0.008,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentRequest.status.displayName,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500, color: Colors.white),
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
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildCommentsSection(context, screenWidth, screenHeight, comments),
        ],
      ),
    );
  }

  Widget _buildApproversRow(
    BuildContext context,
    double screenWidth,
    List<OnDutyApprovalLevel> approvers,
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
            onTap: () => _showApproversBottomSheet(context),
            child: Row(
              children: [
                _OnDutyApproverAvatarStack(
                  users: approverUsers,
                  avatarSize: screenWidth * 0.07,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  approverUsers.length == 1
                      ? approverUsers.first.fullName
                      : '${approverUsers.length} approvers',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(
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
    OnDutyRequestModel currentRequest,
    int requestId,
  ) {
    final text =
        currentRequest.reason.isNotEmpty
            ? currentRequest.reason
            : 'No description';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppTextStyles.heading5(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        SizedBox(height: screenHeight * 0.012),
        Text(
          text,
          style: AppTextStyles.bodySmall(
            context,
          ).copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        if (widget.isApprovalMode &&
            currentRequest.status == OnDutyStatus.pending &&
            currentRequest.isEligibleToApprove) ...[
          SizedBox(height: screenHeight * 0.02),
          BlocBuilder<OnDutyDetailBloc, OnDutyDetailState>(
            builder: (context, state) {
              return ApprovalActionBar(
                embedded: true,
                isLoading: state is OnDutyDetailStatusUpdating,
                onApprove:
                    requestId <= 0
                        ? null
                        : () {
                          context.read<OnDutyDetailBloc>().add(
                            UpdateOnDutyRequestStatus(
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
                          context.read<OnDutyDetailBloc>().add(
                            UpdateOnDutyRequestStatus(
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
    );
  }

  Widget _buildCommentsSection(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    List<AttendanceRequestComment> comments,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comments',
                style: AppTextStyles.heading5(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.025,
                  vertical: screenHeight * 0.004,
                ),
                decoration: BoxDecoration(
                  color: AppColors.attendanceTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${comments.length}',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.attendanceTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),

          ...comments.map(
            (comment) => Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.012),
              child: _buildCommentTile(
                context,
                screenWidth,
                screenHeight,
                comment,
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.01),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.032,
                vertical: screenHeight * 0.015,
              ),
            ),
            maxLines: 3,
            style: AppTextStyles.bodyMedium(context),
          ),
          SizedBox(height: screenHeight * 0.02),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final comment = _commentController.text.trim();
                if (comment.isEmpty) return;
                context.read<OnDutyDetailBloc>().add(
                  AddOnDutyComment(
                    requestId: int.tryParse(widget.onDutyRequest.id) ?? 0,
                    clientId: _clientId,
                    comment: comment,
                  ),
                );
                _commentController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Submit',
                style: AppTextStyles.buttonLarge(
                  context,
                ).copyWith(color: AppColors.textWhite),
              ),
            ),
          ),
        ],
      ),
    );
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
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentTile(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    AttendanceRequestComment comment,
  ) {
    final userName =
        comment.user?.fullName.isNotEmpty == true
            ? comment.user!.fullName
            : 'User';
    final initials =
        userName
            .split(' ')
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.035),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: screenWidth * 0.04,
            backgroundColor:
                comment.user?.profileColor != null
                    ? Color(
                      int.parse(
                        comment.user!.profileColor!.replaceFirst('#', '0xff'),
                      ),
                    )
                    : AppColors.attendanceTeal,
            child: Text(
              initials.isEmpty ? 'U' : initials,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(color: AppColors.textPrimary),
                ),
                SizedBox(height: screenHeight * 0.004),
                Text(
                  comment.comment,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
                SizedBox(height: screenHeight * 0.006),
                Text(
                  comment.createdAt != null
                      ? DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(comment.createdAt!)
                      : 'N/A',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityBottomSheet(
    BuildContext context,
    List<OnDutyActivity> activity,
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
                  child: OnDutyActivityBottomSheet(
                    scrollController: scrollController,
                    activity: activity,
                  ),
                ),
          ),
    );
  }

  void _showApproversBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
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
                  child: BlocProvider(
                    create: (context) {
                      final apiService = ApiService(
                        networkInfo: NetworkInfoImpl(Connectivity()),
                        onTokenExpired:
                            () => AppNavigator.pushAndRemoveAll(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                      );
                      final remoteDataSource = ApproversRemoteDataSourceImpl(
                        apiService: apiService,
                      );
                      final repository = ApproversRepositoryImpl(
                        remoteDataSource: remoteDataSource,
                      );
                      final getApprovers = GetApprovers(repository);

                      return ApproversBloc(getApprovers: getApprovers);
                    },
                    child: ApproversSection(
                      scrollController: scrollController,
                      endpoint: AppUrls.onDutyRequestDetails,
                      payload: {
                        'request_id': int.tryParse(widget.onDutyRequest.id) ?? 0,
                      },
                    ),
                  ),
                ),
          ),
    );
  }

  OnDutyDetail? _detailFromState(OnDutyDetailState state) {
    if (state is OnDutyDetailLoaded) return state.detail;
    if (state is OnDutyDetailStatusUpdating) return state.detail;
    if (state is OnDutyCommentSubmitting) return state.detail;
    if (state is OnDutyDetailError) return state.detail;
    return null;
  }

  List<AttendanceRequestComment> _commentsFromState(OnDutyDetailState state) {
    if (state is OnDutyDetailLoaded) return state.comments;
    if (state is OnDutyDetailStatusUpdating) return state.comments;
    if (state is OnDutyCommentSubmitting) return state.comments;
    if (state is OnDutyDetailError) return state.comments;
    return const [];
  }

  OnDutyRequestModel _currentRequest(OnDutyDetail? detail) {
    if (detail == null) return _fallbackRequest;

    return _fallbackRequest.copyWith(
      id: detail.id.toString(),
      numberOfDays: detail.numberOfDays,
      fromDate: detail.startDate ?? _fallbackRequest.fromDate,
      toDate: detail.endDate,
      reason:
          detail.description?.isNotEmpty == true
              ? detail.description!
              : (detail.reason ?? _fallbackRequest.reason),
      subject: detail.subject ?? _fallbackRequest.subject,
      requestType: detail.requestType,
      startHalf: detail.startHalf ?? _fallbackRequest.startHalf,
      endHalf: detail.endHalf ?? _fallbackRequest.endHalf,
      status: OnDutyRequestModel.parseStatusValue(detail.requestStatus),
      appliedDate: detail.createdAt ?? _fallbackRequest.appliedDate,
      rejectRemark: detail.rejectRemark ?? _fallbackRequest.rejectRemark,
    );
  }

  int _resolveClientId() {
    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is UserProfileLoaded) {
      return profileState.profile.clientId;
    }

    final token = TokenStorage.getToken();
    if (token == null || token.isEmpty) {
      return 0;
    }

    final decoded = decodeData<Map<String, dynamic>>(token);
    final clientId = decoded?['client_id'];
    if (clientId is int) return clientId;
    if (clientId is String) return int.tryParse(clientId) ?? 0;
    return 0;
  }

  String _formatHalf(String value) {
    switch (value) {
      case 'first_half':
        return 'First Half';
      case 'second_half':
        return 'Second Half';
      default:
        return value;
    }
  }

  Color _getStatusColor(OnDutyStatus status) {
    switch (status) {
      case OnDutyStatus.pending:
        return AppColors
            .approvalSheetPending; // 0xFF2196F3
      case OnDutyStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case OnDutyStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case OnDutyStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
    }
  }
}

class _OnDutyApproverAvatarStack extends StatelessWidget {
  final List<OnDutyApprover> users;
  final double avatarSize;

  const _OnDutyApproverAvatarStack({
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
            ? avatarSize+ (edgePadding * 2)
            : avatarSize + ((visibleUsers.length - 1) * (avatarSize - overlap))+
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
                  backgroundColor: _parseAvatarColor(visibleUsers[i].profileColor),
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
                              style: AppTextStyles.bodyMedium(
                                context,
                              ).copyWith(
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

Color _parseAvatarColor(String? color) {
  if (color == null || !color.startsWith('#')) {
    return AppColors.primary;
  }
  try {
    return Color(int.parse(color.replaceFirst('#', 'FF'), radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}
