import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/api_service.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../approval/presentation/widgets/approval_action_bar.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../bloc/approvers/approvers_bloc.dart';
import '../../data/datasources/approvers_remote_datasource.dart';
import '../../data/repositories/approvers_repository_impl.dart';
import '../../domain/entities/leave_entity.dart';
import '../../domain/usecases/get_approvers.dart';
import '../bloc/leave_detail/leave_detail_bloc.dart';
import '../bloc/leave_detail/leave_detail_event.dart';
import '../bloc/leave_detail/leave_detail_state.dart';
import '../../data/models/leave_detail_model.dart';
import '../widgets/approvers_section.dart';
import 'apply_leave_page.dart';

/// Leave detail page — fetches full leave data from the API using the leave ID.
class LeaveDetailPage extends StatelessWidget {
  final LeaveEntity leaveRequest;
  final bool isApprovalMode;

  const LeaveDetailPage({
    super.key,
    required this.leaveRequest,
    this.isApprovalMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);

    return BlocProvider(
      create:
          (_) =>
              LeaveDetailBloc(apiClient: apiClient)
                ..add(FetchLeaveDetail(int.tryParse(leaveRequest.id) ?? 0)),
      child: _LeaveDetailView(
        leaveEntity: leaveRequest,
        isApprovalMode: isApprovalMode,
      ),
    );
  }
}

class _LeaveDetailView extends StatelessWidget {
  final LeaveEntity leaveEntity;
  final bool isApprovalMode;

  const _LeaveDetailView({
    required this.leaveEntity,
    required this.isApprovalMode,
  });

  LeaveEntity _mapDetailToEditableLeave(LeaveDetailModel detail) {
    return LeaveEntity(
      id: detail.id.toString(),
      leaveType: detail.leaveType,
      shortCode: detail.shortCode,
      fromDate: detail.startDate,
      toDate: detail.dayType.toLowerCase() == 'single' ? null : detail.endDate,
      noOfDays: detail.noOfDays.toInt(),
      reason: detail.reason,
      subject: detail.subject,
      status: _mapStatus(detail.status),
      appliedDate: detail.requestDate,
      rejectRemark: detail.rejectRemark,
      fileDocuments: detail.fileDocuments.map((doc) => doc.url).toList(),
      fileAttachments:
          detail.fileDocuments
              .map(
                (doc) => LeaveAttachmentRef(
                  leaveFileId: detail.id,
                  fileId: doc.id,
                  url: doc.url,
                  name: doc.name,
                ),
              )
              .toList(),
    );
  }

  LeaveStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'withdrawn':
        return LeaveStatus.withdrawn;
      default:
        return LeaveStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
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
        title: BlocBuilder<LeaveDetailBloc, LeaveDetailState>(
          builder: (ctx, state) {
            final title =
                state is LeaveDetailLoaded
                    ? state.detail.leaveType
                    : leaveEntity.leaveType;
            return Text(
              isApprovalMode ? 'Leave Approval' : title,
              style: AppTextStyles.heading4(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<LeaveDetailBloc, LeaveDetailState>(
            builder: (context, state) {
              if (state is LeaveDetailLoaded) {
                final bool isPending =
                    state.detail.status.toLowerCase() == 'pending';
                final menuActions = <Map<String, String>>[
                  if (isPending && !isApprovalMode)
                    {'value': 'Edit', 'icon': AppAssets.editIconwfh},
                  if (isPending && !isApprovalMode)
                    {'value': 'Withdraw', 'icon': AppAssets.withdrawIcon},
                  {'value': 'Activity', 'icon': AppAssets.activityIcon},
                ];

                Future<void> handleAction(String value) async {
                  switch (value) {
                    case 'Edit':
                      final editableLeave = _mapDetailToEditableLeave(
                        state.detail,
                      );
                      final bool? updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  ApplyLeavePage(leaveRequest: editableLeave),
                        ),
                      );

                      if (updated == true && context.mounted) {
                        context.read<LeaveDetailBloc>().add(
                          FetchLeaveDetail(int.tryParse(leaveEntity.id) ?? 0),
                        );
                      }
                      break;
                    case 'Withdraw':
                      _showWithdrawDialog(context, state.detail);
                      break;
                    case 'Activity':
                      _showActivitySheet(context, state.detail);
                      break;
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
                  );
                }

                if (menuActions.length == 1) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => handleAction(menuActions.first['value']!),
                    child: Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.06),
                      child: SizedBox(
                        width: screenWidth * 0.06,
                        height: screenHeight * 0.03,
                        child: SvgPicture.asset(menuActions.first['icon']!),
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar:
          isApprovalMode
              ? null
              : BottomNavBar(
                currentIndex: 3,
                onTap: NavigationHelper.getBottomNavHandler(context),
              ),
      body: BlocListener<LeaveDetailBloc, LeaveDetailState>(
        listenWhen: (previous, current) {
          if (current is LeaveDetailError) {
            return previous is! LeaveDetailInitial &&
                previous is! LeaveDetailLoading;
          }
          return current is LeaveDetailWithdrawn ||
              current is LeaveStatusUpdated ||
              current is LeaveCommentAdded;
        },
        listener: (context, state) {
          if (state is LeaveDetailWithdrawn) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(
              context,
            ).pop(true); // Pop back to list and signal refresh
          } else if (state is LeaveDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ErrorMessageMapper.toUserFriendlyMessage(state.message),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is LeaveStatusUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is LeaveCommentAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        child: BlocBuilder<LeaveDetailBloc, LeaveDetailState>(
          builder: (ctx, state) {
            if (state is LeaveDetailLoading || state is LeaveDetailInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LeaveDetailError) {
              return ApiErrorState(
                rawMessage: state.message,
                title: 'Unable to load leave details',
                onRetry:
                    () => ctx.read<LeaveDetailBloc>().add(
                      FetchLeaveDetail(int.tryParse(leaveEntity.id) ?? 0),
                    ),
              );
            }
            if (state is LeaveDetailWithdrawing) {
              return Stack(
                children: [
                  _DetailContent(
                    detail: state.detail,
                    leaveEntity: leaveEntity,
                    isApprovalMode: isApprovalMode,
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (state is LeaveCommentSubmitting) {
              return Stack(
                children: [
                  _DetailContent(
                    detail: state.detail,
                    leaveEntity: leaveEntity,
                    isApprovalMode: isApprovalMode,
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (state is LeaveDetailStatusUpdating) {
              return Stack(
                children: [
                  _DetailContent(
                    detail: state.detail,
                    leaveEntity: leaveEntity,
                    isApprovalMode: isApprovalMode,
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (state is LeaveDetailLoaded) {
              return _DetailContent(
                detail: state.detail,
                leaveEntity: leaveEntity,
                isApprovalMode: isApprovalMode,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, LeaveDetailModel detail) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Withdraw Leave',
              style: AppTextStyles.heading5(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to withdraw this leave request?',
              style: AppTextStyles.bodyMedium(context),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.buttonMedium(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.read<LeaveDetailBloc>().add(WithdrawLeave(detail.id));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Withdraw',
                  style: AppTextStyles.buttonMedium(
                    context,
                  ).copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showActivitySheet(BuildContext context, LeaveDetailModel detail) {
    final sw = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,

      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
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
                  child: ListView(
                    controller: sc,
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
                      ...detail.activity.map(
                        (a) => _ActivityTile(activity: a, sw: sw, sh: 720),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main content (StatefulWidget so comments + upload image have local state)
// ─────────────────────────────────────────────────────────────────────────────
class _DetailContent extends StatefulWidget {
  final LeaveDetailModel detail;
  final LeaveEntity leaveEntity;
  final bool isApprovalMode;

  const _DetailContent({
    required this.detail,
    required this.leaveEntity,
    required this.isApprovalMode,
  });

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      padding: EdgeInsets.all(sw * 0.002),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailsCard(
            detail: widget.detail,
            sw: sw,
            sh: sh,
            isApprovalMode: widget.isApprovalMode,
          ),
          SizedBox(height: sh * 0.02),
          SizedBox(height: sh * 0.02),
          _CommentsCard(
            detail: widget.detail,
            commentController: _commentController,
            sw: sw,
            sh: sh,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Details Card
// ─────────────────────────────────────────────────────────────────────────────
class _DetailsCard extends StatelessWidget {
  final LeaveDetailModel detail;
  final double sw, sh;
  final bool isApprovalMode;

  const _DetailsCard({
    required this.detail,
    required this.sw,
    required this.sh,
    required this.isApprovalMode,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _statusColor(detail.status);
    final appliedOn = detail.createdAt ?? detail.requestDate;

    return _Card(
      sw: sw,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: 'Leave Type:',
            value:
                detail.shortCode != null
                    ? '${detail.leaveType} (${detail.shortCode})'
                    : detail.leaveType,
            sw: sw,
            sh: sh,
          ),
          _Div(sh: sh),
          _Row(
            label: 'Request Type:',
            value: detail.dayType == 'single' ? 'Single Day' : 'Multiple Days',
            sw: sw,
            sh: sh,
          ),
          _Div(sh: sh),
          _Row(
            label: 'Subject:',
            value: detail.subject ?? detail.reason,
            sw: sw,
            sh: sh,
          ),
          _Div(sh: sh),
          _Row(
            label: 'Reason:',
            value: detail.reason.trim().isEmpty ? '-' : detail.reason,
            sw: sw,
            sh: sh,
          ),
          _Div(sh: sh),
          // Request To with avatar
          _RequestToRow(detail: detail, sw: sw, sh: sh),
          _Div(sh: sh),
          _Row(
            label: 'No. of Days:',
            value: detail.noOfDays.toString().padLeft(2, '0'),
            sw: sw,
            sh: sh,
          ),
          _Div(sh: sh),
          _Row(
            label: 'From:',
            value:
                '${dateFormat.format(detail.startDate)}  (${LeaveDetailModel.halfLabel(detail.startHalf)})',
            sw: sw,
            sh: sh,
          ),
          _Div(sh: sh),
          _Row(
            label: 'To:',
            value:
                '${dateFormat.format(detail.endDate)}  (${LeaveDetailModel.halfLabel(detail.endHalf)})',
            sw: sw,
            sh: sh,
          ),
          _Div(sh: sh),
          _Row(
            label: 'Applied On:',
            value: DateFormat('dd/MM/yyyy hh:mm a').format(appliedOn),
            sw: sw,
            sh: sh,
          ),
          if (detail.status.toLowerCase() == 'rejected' &&
              detail.rejectRemark != null) ...[
            _Div(sh: sh),
            _Row(
              label: 'Reject Remark:',
              value: detail.rejectRemark!,
              sw: sw,
              sh: sh,
            ),
          ],
          _Div(sh: sh),
          // Status row with info icon → show approvers sheet
          _StatusRow(detail: detail, sw: sw, sh: sh, statusColor: statusColor),
          _Div(sh: sh),

          _DescriptionCard(
            detail: detail,
            sw: sw,
            sh: sh,
            isApprovalMode: isApprovalMode,
          ),
        ],
      ),
    );
  }
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.approvalSheetAccept;
      case 'rejected':
        return AppColors.approvalSheetReject;
      case 'withdrawn':
        return AppColors.approvalSheetWithdrawn;
      case 'pending':
        return AppColors.approvalSheetPending;
      default:
        return  AppColors.approvalSheetPending;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Approvers Row (with stacked avatars)
// ─────────────────────────────────────────────────────────────────────────────
class _RequestToRow extends StatelessWidget {
  final LeaveDetailModel detail;
  final double sw, sh;

  const _RequestToRow({
    required this.detail,
    required this.sw,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    final approverUsers =
        detail.approvers.expand((level) => level.users).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: sw * 0.3,
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
            onTap: () => _showApproversSheet(context),
            child: Row(
              children: [
                _ApproverAvatarStack(
                  users: approverUsers,
                  avatarSize: sw * 0.07,
                ),
                SizedBox(width: sw * 0.02),
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

  void _showApproversSheet(BuildContext context) {
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
                      scrollController: sc,
                      endpoint: AppUrls.leaveRequestDetails,
                      payload: {'leave_id': detail.id},
                    ),
                  ),
                ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final LeaveDetailModel detail;
  final double sw, sh;
  final Color statusColor;

  const _StatusRow({
    required this.detail,
    required this.sw,
    required this.sh,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: sw * 0.3,
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
            horizontal: sw * 0.032,
            vertical: sh * 0.004,
          ),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            detail.status,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description + Attachments Card
// ─────────────────────────────────────────────────────────────────────────────
class _DescriptionCard extends StatelessWidget {
  final LeaveDetailModel detail;
  final double sw, sh;
  final bool isApprovalMode;

  const _DescriptionCard({
    required this.detail,
    required this.sw,
    required this.sh,
    required this.isApprovalMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppTextStyles.heading5(
            context,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: sh * 0.01),
        Text(
          detail.description?.isNotEmpty == true
              ? detail.description!
              : (detail.reason.isNotEmpty
                  ? detail.reason
                  : 'No description provided'),
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),

        if (isApprovalMode &&
            detail.status.toLowerCase() == 'pending' &&
            detail.isEligibleToApprove) ...[
          SizedBox(height: sh * 0.02),
          ApprovalActionBar(
            embedded: true,
            onApprove: () {
              context.read<LeaveDetailBloc>().add(
                UpdateLeaveStatus(
                  leaveRequestId: detail.id,
                  userId: detail.userLeave?.id ?? 0,
                  status: 'Approved',
                ),
              );
            },
            onReject: () {
              context.read<LeaveDetailBloc>().add(
                UpdateLeaveStatus(
                  leaveRequestId: detail.id,
                  userId: detail.userLeave?.id ?? 0,
                  status: 'Rejected',
                ),
              );
            },
            isLoading:
                context.watch<LeaveDetailBloc>().state
                    is LeaveDetailStatusUpdating,
          ),
        ],
        if (detail.fileDocuments.isNotEmpty) ...[
          SizedBox(height: sh * 0.02),
          Text(
            'Attachments',
            style: AppTextStyles.heading5(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: sh * 0.015),
          _ImageGrid(docs: detail.fileDocuments, sw: sw),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comments Card
// ─────────────────────────────────────────────────────────────────────────────
class _CommentsCard extends StatelessWidget {
  final LeaveDetailModel detail;
  final TextEditingController commentController;
  final double sw, sh;

  const _CommentsCard({
    required this.detail,
    required this.commentController,
    required this.sw,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      sw: sw,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Comments',
                style: AppTextStyles.heading5(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.025,
                  vertical: sh * 0.005,
                ),
                decoration: BoxDecoration(
                  color: AppColors.serviceBlueBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${detail.comments.length}',
                  style: AppTextStyles.labelSmall(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.008),
          Text(
            'Keep updates and discussion in one place.',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: sh * 0.018),
          if (detail.comments.isNotEmpty) ...[
            ...detail.comments.map(
              (comment) => Padding(
                padding: EdgeInsets.only(bottom: sh * 0.012),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(sw * 0.032),
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
                            width: sw * 0.09,
                            height: sw * 0.09,
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
                          SizedBox(width: sw * 0.03),
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
                                SizedBox(height: sh * 0.002),
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
                      SizedBox(height: sh * 0.012),
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
            SizedBox(height: sh * 0.008),
          ],
          Container(
            padding: EdgeInsets.all(sw * 0.02),
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
                    controller: commentController,
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
                        horizontal: sw * 0.02,
                        vertical: sh * 0.012,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: sw * 0.02),
                SizedBox(
                  height: sw * 0.12,
                  width: sw * 0.12,
                  child: ElevatedButton(
                    onPressed: () {
                      final trimmedComment = commentController.text.trim();
                      if (trimmedComment.isNotEmpty) {
                        context.read<LeaveDetailBloc>().add(
                          AddLeaveComment(
                            leaveId: detail.id,
                            comment: trimmedComment,
                          ),
                        );
                        commentController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Icon(Icons.arrow_upward_rounded, size: sw * 0.05),
                  ),
                ),
              ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
class _ImageGrid extends StatelessWidget {
  final List<LeaveFileDocument> docs;
  final double sw;

  const _ImageGrid({required this.docs, required this.sw});

  @override
  Widget build(BuildContext context) {
    final thumbSize = sw * 0.28;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          docs.map((doc) => _ThumbTile(doc: doc, size: thumbSize)).toList(),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  final LeaveFileDocument doc;
  final double size;

  const _ThumbTile({required this.doc, required this.size});

  @override
  Widget build(BuildContext context) {
    final isImage = _isImageFile(doc.url);

    return GestureDetector(
      onTap: () => _openDocument(context, isImage: isImage),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child:
            isImage
                ? Image.network(
                  doc.url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: size,
                      height: size,
                      color: AppColors.backgroundLight,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder:
                      (_, __, ___) => _FilePlaceholder(size: size, doc: doc),
                )
                : _FilePlaceholder(size: size, doc: doc),
      ),
    );
  }

  bool _isImageFile(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif');
  }

  void _openDocument(BuildContext context, {required bool isImage}) {
    if (isImage) {
      _openImage(context, doc.url);
      return;
    }

    if (doc.url.toLowerCase().endsWith('.pdf')) {
      _openPdf(context, doc.url);
      return;
    }

    _openImage(context, doc.url);
  }

  void _openImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPdf(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 50,
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PDF Preview',
                      style: TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(child: SfPdfViewer.network(url)),
            ],
          ),
        );
      },
    );
  }
}

class _FilePlaceholder extends StatelessWidget {
  final double size;
  final LeaveFileDocument doc;

  const _FilePlaceholder({required this.size, required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              doc.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final LeaveActivity activity;
  final double sw, sh;

  const _ActivityTile({
    required this.activity,
    required this.sw,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    // Strip HTML tags from activity string
    final cleanText = activity.action.replaceAll(RegExp(r'<[^>]*>'), '');
    return Padding(
      padding: EdgeInsets.only(bottom: sh * 0.012),
      child: Container(
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: sw * 0.025),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanText,
                    style: AppTextStyles.bodyMediumHeading(
                      context,
                    ).copyWith(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(activity.updatedAt),
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final double sw;
  final Widget child;

  const _Card({required this.sw, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(sw * 0.042),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final double sw, sh;

  const _Row({
    required this.label,
    required this.value,
    required this.sw,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: sw * 0.32,
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
}

class _Div extends StatelessWidget {
  final double sh;

  const _Div({required this.sh});

  @override
  Widget build(BuildContext context) =>
      Divider(height: sh * 0.03, color: AppColors.border);
}

/// Avatar widget that shows network image or color initial fallback
class _AvatarWidget extends StatelessWidget {
  final LeaveUserSnapshot user;
  final double size;

  const _AvatarWidget({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.primary;
    if (user.profileColor != null && user.profileColor!.startsWith('#')) {
      try {
        bgColor = Color(
          int.parse(user.profileColor!.replaceFirst('#', 'FF'), radix: 16),
        );
      } catch (_) {}
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      backgroundImage:
          user.imageUrl != null && user.imageUrl!.isNotEmpty
              ? NetworkImage(user.imageUrl!)
              : null,
      child:
          user.imageUrl == null || user.imageUrl!.isEmpty
              ? Text(
                user.firstName.isNotEmpty
                    ? user.firstName[0].toUpperCase()
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

class _ApproverAvatarStack extends StatelessWidget {
  final List<LeaveApprover> users;
  final double avatarSize;

  const _ApproverAvatarStack({required this.users, required this.avatarSize});

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
              left: edgePadding + (i * (avatarSize - overlap)),
              top: edgePadding,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: _AvatarWidget(
                  user: LeaveUserSnapshot(
                    id: visibleUsers[i].id,
                    firstName: visibleUsers[i].firstName,
                    lastName: visibleUsers[i].lastName,
                    imageUrl: visibleUsers[i].imageUrl,
                    profileColor: visibleUsers[i].profileColor,
                  ),
                  size: avatarSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
