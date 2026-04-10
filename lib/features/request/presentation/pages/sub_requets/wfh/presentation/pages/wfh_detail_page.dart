import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../approval/presentation/widgets/approval_action_bar.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../models/wfh_request_model.dart';
import '../../../leaves/presentation/widgets/approvers_section.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../../../../../core/network/api_service.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../bloc/approvers/approvers_bloc.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../leaves/data/datasources/approvers_remote_datasource.dart';
import '../../../leaves/data/repositories/approvers_repository_impl.dart';
import '../../../leaves/domain/usecases/get_approvers.dart';
import 'package:dio/dio.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../../../../../../attendance/data/models/attendance_request_comment_model.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../data/datasources/wfh_remote_datasource.dart';
import '../../data/repositories/wfh_repository_impl.dart';
import '../../domain/usecases/update_wfh_status.dart';
import '../../bloc/action/wfh_action_bloc.dart';
import '../../bloc/action/wfh_action_event.dart';
import '../../bloc/action/wfh_action_state.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import 'apply_wfh_page.dart';

/// WFH detail page showing full information about a WFH request
class WfhDetailPage extends StatefulWidget {
  final WfhRequestModel wfhRequest;
  final bool isApprovalMode;

  const WfhDetailPage({
    super.key,
    required this.wfhRequest,
    this.isApprovalMode = false,
  });

  @override
  State<WfhDetailPage> createState() => _WfhDetailPageState();
}

class _WfhDetailPageState extends State<WfhDetailPage> {
  final _commentController = TextEditingController();
  List<AttendanceRequestComment> _comments = const [];
  List<WfhApproverSnapshot> _approvers = const [];
  bool _commentsLoading = true;
  bool _submittingComment = false;
  String? _commentsErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadApprovers();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (context) {
        final networkInfo = NetworkInfoImpl(Connectivity());
        final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo,onTokenExpired: () {
          AppNavigator.pushAndRemoveAll(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },);
        final remoteDataSource = WfhRemoteDataSourceImpl(apiClient: apiClient);
        final repository = WfhRepositoryImpl(
          remoteDataSource: remoteDataSource,
        );
        final useCase = UpdateWfhStatusUseCase(repository);
        return WfhActionBloc(updateWfhStatusUseCase: useCase);
      },
      child: BlocListener<WfhActionBloc, WfhActionState>(
        listener: (context, state) {
          if (state is WfhActionInProgress) {
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => const Center(child: CircularProgressIndicator()),
            );
          } else if (state is WfhActionSuccess) {
            // Pop loading dialog
            Navigator.of(context).pop();
            // Show success
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is WfhActionFailure) {
            // Pop loading dialog
            Navigator.of(context).pop();
            // Show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ErrorMessageMapper.toUserFriendlyMessage(state.errorMessage),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: ResponsiveScaffold(
          backgroundColor: AppColors.backgroundMedium,
          appBar: AppBar(
            elevation: 0,
            forceMaterialTransparency: true,
            leadingWidth: 110,
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
            title: Text(
              widget.isApprovalMode ? 'WFH Approval' : 'WFH',
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
          body: _buildDetailsContent(context, screenWidth, screenHeight),
        ),
      ),
    );
  }

  Widget _buildDetailsContent(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    final statusColor = _getStatusColor(widget.wfhRequest.status);
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final dateTimeFormat = DateFormat('dd-MMM-yyyy HH:mm');

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.002),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WFH Details Card
          _buildDetailsCard(
            context,
            screenWidth,
            screenHeight,
            statusColor,
            dateFormat,
            dateTimeFormat,
          ),
          // Description Section
          SizedBox(height: screenHeight * 0.01),
          // Comments Section
          _buildCommentsSection(context, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    Color statusColor,
    DateFormat dateFormat,
    DateFormat dateTimeFormat,
  ) {
    final isSingleDayRequest =
        (widget.wfhRequest.requestType ?? '').toLowerCase() == 'single';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.wfhRequest.subject ?? widget.wfhRequest.reason,
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // Green color for title
                  ),
                ),
              ),
              Builder(
                builder: (menuContext) {
                  final isPending =
                      widget.wfhRequest.status == WfhStatus.pending;
                  final menuActions = <Map<String, String>>[
                    if (isPending && !widget.isApprovalMode)
                      {'value': 'Edit', 'icon': AppAssets.editIconwfh},
                    if (isPending && !widget.isApprovalMode)
                      {'value': 'Withdraw', 'icon': AppAssets.withdrawIcon},
                    {'value': 'Activity', 'icon': AppAssets.activityIcon},
                  ];

                  void handleAction(String value) {
                    if (value == 'Edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ApplyWfhPage(
                                wfhRequest: widget.wfhRequest,
                              ),
                        ),
                      ).then((result) {
                        if (result == true && context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      });
                    } else if (value == 'Withdraw') {
                      final requestIdString =
                          widget.wfhRequest.attendanceRequestId ??
                          widget.wfhRequest.id;
                      final requestId = int.tryParse(requestIdString) ?? 0;
                      if (requestId > 0) {
                        menuContext.read<WfhActionBloc>().add(
                          UpdateWfhStatus(
                            requestId: requestId,
                            status: 'Withdrawn',
                          ),
                        );
                      }
                    } else if (value == 'Activity') {
                      _showActivityBottomSheet(context);
                    }
                  }

                  if (menuActions.length >= 2) {
                    return PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
                      onSelected: handleAction,
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
                                  style: AppTextStyles.heading5(
                                    context,
                                  ).copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    );
                  }

                  if (menuActions.length == 1) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => handleAction(menuActions.first['value']!),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SizedBox(
                          width: screenWidth * 0.06,
                          height: screenHeight * 0.03,
                          child: SvgPicture.asset(menuActions.first['icon']!),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),

          _buildDetailRow(
            context,
            'Request Type:',
            isSingleDayRequest ? 'Single Day' : 'Multiple Days',

            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'WFH Type:',
            ((widget.wfhRequest.requestType ?? '').toLowerCase() == 'single'
                ? 'single'
                : 'multiple'),
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'No. of Days:',
            widget.wfhRequest.numberOfDays.toString().padLeft(2, '0'),
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            isSingleDayRequest ? 'On:' : 'From:',
            dateFormat.format(widget.wfhRequest.fromDate),
            screenWidth,
            screenHeight,
          ),
          if (!isSingleDayRequest) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'To:',
              widget.wfhRequest.toDate != null
                  ? dateFormat.format(widget.wfhRequest.toDate!)
                  : dateFormat.format(widget.wfhRequest.fromDate),
              screenWidth,
              screenHeight,
            ),
          ],
          // Show reject remark if rejected
          if (widget.wfhRequest.status == WfhStatus.rejected &&
              widget.wfhRequest.rejectRemark != null) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'Reject Remark:',
              widget.wfhRequest.rejectRemark!,
              screenWidth,
              screenHeight,
            ),
          ],
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildApproversRow(context, screenWidth, screenHeight),
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
                  widget.wfhRequest.status.displayName,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),

          _buildDescriptionSection(context, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildApproversRow(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    final approvers =
        _approvers.isNotEmpty ? _approvers : widget.wfhRequest.approvers;

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
        if (approvers.isNotEmpty)
          GestureDetector(
            onTap: () => _showApproversBottomSheet(context),
            child: Row(
              children: [
                _WfhApproverAvatarStack(
                  approvers: approvers,
                  avatarSize: screenWidth * 0.07,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  approvers.length == 1
                      ? approvers.first.fullName
                      : '${approvers.length} approvers',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
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

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    double screenWidth,
    double screenHeight,
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

  Widget _buildDescriptionSection(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
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
            widget.wfhRequest.reason.isNotEmpty
                ? widget.wfhRequest.reason
                : (widget.wfhRequest.subject ?? 'No description provided'),
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          if (widget.isApprovalMode &&
              widget.wfhRequest.status == WfhStatus.pending &&
              widget.wfhRequest.isEligibleToApprove) ...[
            SizedBox(height: screenHeight * 0.02),
            BlocBuilder<WfhActionBloc, WfhActionState>(
              builder: (context, state) {
                final requestIdString =
                    widget.wfhRequest.attendanceRequestId ??
                    widget.wfhRequest.id;
                final requestId = int.tryParse(requestIdString) ?? 0;

                return ApprovalActionBar(
                  embedded: true,
                  isLoading: state is WfhActionInProgress,
                  onApprove:
                      requestId <= 0
                          ? null
                          : () {
                            context.read<WfhActionBloc>().add(
                              UpdateWfhStatus(
                                requestId: requestId,
                                status: 'Approved',
                              ),
                            );
                          },
                  onReject:
                      requestId <= 0
                          ? null
                          : () {
                            context.read<WfhActionBloc>().add(
                              UpdateWfhStatus(
                                requestId: requestId,
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
    double screenWidth,
    double screenHeight,
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
            spreadRadius: 0,
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Comments',
                style: AppTextStyles.heading5(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.025,
                  vertical: screenHeight * 0.005,
                ),
                decoration: BoxDecoration(
                  color: AppColors.serviceBlueBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_comments.length}',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            'Keep updates and discussion in one place.',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: screenHeight * 0.018),
          if (_commentsLoading)
            const Center(child: CircularProgressIndicator())
          else if (_commentsErrorMessage != null)
            ApiErrorState(
              title: 'Unable to load comments',
              rawMessage: _commentsErrorMessage,
              onRetry: _loadComments,
            )
          else if (_comments.isNotEmpty) ...[
            ..._comments.map(
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

            SizedBox(height: screenHeight * 0.018),
          ],
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 4,
                    style: AppTextStyles.bodyMedium(context),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: AppTextStyles.bodyMedium(
                        context,
                      ).copyWith(color: AppColors.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.012,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                SizedBox(
                  height: screenWidth * 0.12,
                  width: screenWidth * 0.12,
                  child: ElevatedButton(
                    onPressed:
                        _submittingComment
                            ? null
                            : () => _submitComment(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _submittingComment
                            ? SizedBox(
                              width: screenWidth * 0.05,
                              height: screenWidth * 0.05,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Icon(
                              Icons.arrow_upward_rounded,
                              size: screenWidth * 0.05,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  initials.isEmpty ? 'U' : initials,
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
                      userName,
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
    );
  }

  void _showActivityBottomSheet(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.5, // Start at half screen
            minChildSize: 0.3, // Minimum 30% of screen
            maxChildSize: 0.9, // Maximum 90% of screen (can be dragged up)
            expand: false,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: FutureBuilder<List<_WfhActivityItem>>(
                    future: _fetchActivityItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: sw * 0.1,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load activity',
                                  style: AppTextStyles.bodyMedium(context),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final activities = snapshot.data ?? const [];
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
                            'Activity',
                            style: AppTextStyles.heading4(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          if (activities.isEmpty)
                            Text(
                              'No activity available',
                              style: AppTextStyles.bodyMedium(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                            )
                          else
                            ...activities.map(
                              (activity) =>
                                  _WfhActivityTile(activity: activity, sw: sw),
                            ),
                        ],
                      );
                    },
                  ),
                ),
          ),
    );
  }

  Future<List<_WfhActivityItem>> _fetchActivityItems() async {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo,onTokenExpired: () {
      AppNavigator.pushAndRemoveAll(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    },);
    final requestIdString =
        widget.wfhRequest.attendanceRequestId ?? widget.wfhRequest.id;
    final requestId = int.tryParse(requestIdString) ?? 0;

    final payload = encodeData({'request_id': requestId});
    final response = await apiClient.get(
      // '/api/attendance/wfh/request/details?payload=$payload',
      '${AppUrls.wfhRequestDetails}?payload=$payload',

      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final responseData = response.data;
    if (responseData is! Map<String, dynamic>) {
      return const [];
    }

    if (responseData['success'] != true) {
      throw Exception(
        responseData['message'] as String? ?? 'Failed to load activity',
      );
    }

    final data = responseData['data'];
    if (data is! Map<String, dynamic>) {
      return const [];
    }

    final rawActivity = data['activity'];
    if (rawActivity is! List) {
      return const [];
    }

    return rawActivity
        .whereType<Map>()
        .map(
          (item) => _WfhActivityItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> _loadApprovers() async {
    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo,onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },);
      final payload = encodeData({'request_id': _requestId});
      final response = await apiClient.get(
        '${AppUrls.wfhRequestDetails}?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        return;
      }

      if (responseData['success'] != true) {
        return;
      }

      final data = responseData['data'];
      if (data is! Map<String, dynamic>) {
        return;
      }

      final approvers =
          (data['approvers'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .expand(
                (level) => (level['users'] as List<dynamic>? ?? const [])
                    .whereType<Map<String, dynamic>>()
                    .map(WfhApproverSnapshot.fromJson),
              )
              .toList();

      if (!mounted) return;
      setState(() => _approvers = approvers);
    } catch (_) {
      // Keep the row on list-level data fallback if detail approvers fail to load.
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _commentsLoading = true;
      _commentsErrorMessage = null;
    });
    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
      final payload = encodeData({
        'client_id': _resolveClientId(),
        'attendance_request_id': _requestId,
        'type': 'WorkFromHome',
      });
      final response = await apiClient.get(
        '/api/attendance/request/comments/list?payload=$payload',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData['success'] == true) {
        _comments = parseAttendanceRequestComments(responseData);
      } else {
        _comments = const [];
        _commentsErrorMessage =
            responseData is Map<String, dynamic>
                ? responseData['message'] as String?
                : null;
      }
    } catch (e) {
      _comments = const [];
      _commentsErrorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _commentsLoading = false);
      }
    }
  }

  Future<void> _submitComment(BuildContext context) async {
    final trimmedComment = _commentController.text.trim();
    if (trimmedComment.isEmpty) return;

    setState(() => _submittingComment = true);
    try {
      final networkInfo = NetworkInfoImpl(Connectivity());
      final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
      final payload = encodeData({
        'request_id': _requestId,
        'comment': trimmedComment,
        'type': 'WorkFromHome',
      });
      final response = await apiClient.post(
        '/api/attendance/request/comments',
        data: {'payload': payload},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final responseData = response.data;
      final success =
          responseData is Map<String, dynamic> &&
          responseData['success'] == true;
      final message =
          responseData is Map<String, dynamic>
              ? responseData['message'] as String? ?? 'Failed to add comment'
              : 'Failed to add comment';

      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.toUserFriendlyMessage(message)),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );

      if (success) {
        _commentController.clear();
        await _loadComments();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorMessageMapper.toUserFriendlyMessage(e.toString()),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingComment = false);
      }
    }
  }

  int get _requestId {
    final requestIdString =
        widget.wfhRequest.attendanceRequestId ?? widget.wfhRequest.id;
    return int.tryParse(requestIdString) ?? 0;
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

  void _showApproversBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.5, // Start at half screen
            minChildSize: 0.3, // Minimum 30% of screen
            maxChildSize: 0.9, // Maximum 90% of screen (can be dragged up)
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
                      endpoint: AppUrls.wfhRequestDetails,
                      payload: {'request_id': _requestId},
                    ),
                  ),
                ),
          ),
    );
  }

  Color _getStatusColor(WfhStatus status) {
    switch (status) {
      case WfhStatus.pending:
        return AppColors.approvalSheetPending; //
      case WfhStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case WfhStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case WfhStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
    }
  }
}

class _WfhActivityItem {
  final String action;
  final String actionType;
  final String firstName;
  final String lastName;
  final DateTime? createdAt;

  const _WfhActivityItem({
    required this.action,
    required this.actionType,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
  });

  String get cleanAction => action.replaceAll(RegExp(r'<[^>]*>'), '');

  String get actorName => '$firstName $lastName'.trim();

  factory _WfhActivityItem.fromJson(Map<String, dynamic> json) {
    return _WfhActivityItem(
      action: json['action'] as String? ?? '',
      actionType: json['action_type'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
    );
  }
}

class _WfhActivityTile extends StatelessWidget {
  final _WfhActivityItem activity;
  final double sw;

  const _WfhActivityTile({required this.activity, required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(sw * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              activity.actorName.isNotEmpty
                  ? activity.actorName[0].toUpperCase()
                  : 'A',
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.cleanAction,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  activity.createdAt != null
                      ? DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(activity.createdAt!)
                      : activity.actionType,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WfhApproverAvatar extends StatelessWidget {
  final WfhApproverSnapshot approver;
  final double size;

  const _WfhApproverAvatar({required this.approver, required this.size});

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.primary;
    if (approver.profileColor != null &&
        approver.profileColor!.startsWith('#')) {
      try {
        bgColor = Color(
          int.parse(approver.profileColor!.replaceFirst('#', 'FF'), radix: 16),
        );
      } catch (_) {}
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      backgroundImage:
          approver.imageUrl != null && approver.imageUrl!.isNotEmpty
              ? NetworkImage(approver.imageUrl!)
              : null,
      child:
          approver.imageUrl == null || approver.imageUrl!.isEmpty
              ? Text(
                approver.firstName.isNotEmpty
                    ? approver.firstName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w600,
                ),
              )
              : null,
    );
  }
}

class _WfhApproverAvatarStack extends StatelessWidget {
  final List<WfhApproverSnapshot> approvers;
  final double avatarSize;

  const _WfhApproverAvatarStack({
    required this.approvers,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    final visibleApprovers = approvers.take(3).toList();
    final overlap = avatarSize * 0.35;
    final edgePadding = avatarSize * 0.08;

    final width =
        visibleApprovers.length == 1
            ? avatarSize+ (edgePadding * 2)
            : avatarSize +
                ((visibleApprovers.length - 1) * (avatarSize - overlap))+
            (edgePadding * 2);

    return SizedBox(
      width: width,
      height:avatarSize + (edgePadding * 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visibleApprovers.length; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: _WfhApproverAvatar(
                  approver: visibleApprovers[i],
                  size: avatarSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
