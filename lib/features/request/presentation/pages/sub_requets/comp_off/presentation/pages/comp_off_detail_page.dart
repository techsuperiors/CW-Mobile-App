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
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../approval/presentation/widgets/approval_action_bar.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../bloc/comp_off_detail_bloc.dart';
import '../../bloc/comp_off_detail_event.dart';
import '../../bloc/comp_off_detail_state.dart';
import '../../data/datasources/comp_off_remote_datasource.dart';
import '../../data/repositories/comp_off_repository_impl.dart';
import '../../domain/entities/comp_off_detail.dart';
import '../../domain/usecases/add_comp_off_comment.dart';
import '../../domain/usecases/get_comp_off_comments.dart';
import '../../domain/usecases/get_comp_off_detail.dart';
import '../../domain/usecases/update_comp_off_status.dart';
import '../../domain/usecases/upload_comp_off_file.dart';
import '../../models/comp_off_request_model.dart';
import '../widgets/comp_off_activity_bottom_sheet.dart';
import 'apply_comp_off_page.dart';

class CompOffDetailPage extends StatefulWidget {
  final CompOffRequestModel request;
  final bool isApprovalMode;

  const CompOffDetailPage({
    super.key,
    required this.request,
    this.isApprovalMode = false,
  });

  @override
  State<CompOffDetailPage> createState() => _CompOffDetailPageState();
}

class _CompOffDetailPageState extends State<CompOffDetailPage> {
  final _commentController = TextEditingController();
  late final CompOffDetailBloc _bloc;
  bool _shouldRefresh = false;

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(
      dio: Dio(),
      networkInfo: networkInfo,
      onTokenExpired: () {
        AppNavigator.pushAndRemoveAll(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );
    final remote = CompOffRemoteDataSourceImpl(apiClient: apiClient);
    final repo = CompOffRepositoryImpl(remoteDataSource: remote);
    _bloc = CompOffDetailBloc(
      getCompOffDetailUseCase: GetCompOffDetailUseCase(repo),
      getCompOffCommentsUseCase: GetCompOffCommentsUseCase(repo),
      addCompOffCommentUseCase: AddCompOffCommentUseCase(repo),
      uploadCompOffFileUseCase: UploadCompOffFileUseCase(repo),
      updateCompOffStatusUseCase: UpdateCompOffStatusUseCase(repo),
    )..add(LoadCompOffDetail(int.tryParse(widget.request.id) ?? 0));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_shouldRefresh);
      },
      child: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<CompOffDetailBloc, CompOffDetailState>(
          listenWhen: (previous, current) {
            if (current is! CompOffDetailError) return true;
            final isInitialLoadFailure =
                current.detail == null &&
                (previous is CompOffDetailInitial ||
                    previous is CompOffDetailLoading);
            return !isInitialLoadFailure;
          },
          listener: (context, state) {
            if (state is CompOffDetailStatus) {
              _shouldRefresh =
                  state.action != CompOffDetailSuccessAction.commentAdded;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
              if (widget.isApprovalMode &&
                  state.action == CompOffDetailSuccessAction.statusUpdated &&
                  Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true);
              }
            } else if (state is CompOffDetailError) {
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
            final comments = _commentsFromState(state);
            final currentRequest = _currentRequest(detail);
            final isBusy =
                state is CompOffDetailLoading ||
                state is CompOffDetailSubmitting ||
                state is CompOffDetailStatusUpdating;

            return Stack(
              children: [
                ResponsiveScaffold(
                  backgroundColor: AppColors.backgroundMedium,
                  appBar: AppBar(
                    forceMaterialTransparency: true,
                    elevation: 0,
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    leadingWidth: 110,

                    leading: GestureDetector(
                      onTap: () => Navigator.of(context).pop(_shouldRefresh),
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
                      widget.isApprovalMode ? 'Comp-Off Approval' : 'Comp-Off',
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
                            onTap: NavigationHelper.getBottomNavHandler(
                              context,
                            ),
                          )
                          : BottomNavBar(
                            currentIndex: 3,
                            onTap: NavigationHelper.getBottomNavHandler(
                              context,
                            ),
                          ),
                  body:
                      state is CompOffDetailError && state.detail == null
                          ? ApiErrorState(
                            title: 'Unable to load comp-off details',
                            rawMessage: state.message,
                            onRetry:
                                () => context.read<CompOffDetailBloc>().add(
                                  LoadCompOffDetail(
                                    int.tryParse(widget.request.id) ?? 0,
                                  ),
                                ),
                          )
                          : _buildBody(
                            context,
                            detail,
                            comments,
                            currentRequest.status,
                            currentRequest,
                          ),
                ),
                if (isBusy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.transparent,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CompOffDetail? detail,
    List<AttendanceRequestComment> comments,
    CompOffStatus status,
    CompOffRequestModel compOffRequest,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final date = detail?.date ?? widget.request.date;
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.002),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _primaryCard(
            context,
            status,
            detail,
            date,
            compOffRequest,
            screenWidth,
            screenHeight,
          ),
          SizedBox(height: screenHeight * 0.02),
          _commentSection(context, comments),
        ],
      ),
    );
  }

  Widget _primaryCard(
    BuildContext context,
    CompOffStatus status,
    CompOffDetail? detail,
    DateTime date,
    CompOffRequestModel compOffRequest,
    double screenWidth,
    double screenHeight,
  ) {
    final title = detail?.subject ?? widget.request.subject;
    final requestBy = detail?.requestByName;
    final requestByImg = detail?.requestByImage;
    final requestByColor = detail?.requestByColor;
    final requestId = int.tryParse(widget.request.id) ?? 0;
    final isPending = status == CompOffStatus.pending;
    final menuActions = <Map<String, String>>[
      if (isPending && !widget.isApprovalMode)
        {'value': 'Edit', 'icon': AppAssets.editIconwfh},
      {'value': 'Activity', 'icon': AppAssets.activityIcon},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
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
                              (_) => ApplyCompOffPage(
                                compOffRequest: compOffRequest,
                              ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        _shouldRefresh = true;
                        context.read<CompOffDetailBloc>().add(
                          LoadCompOffDetail(requestId),
                        );
                      }
                    } else if (value == 'Activity') {
                      _showActivity(context, detail?.activity ?? const []);
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
                  onTap: () async {
                    final action = menuActions.first['value'];
                    if (action == 'Edit') {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ApplyCompOffPage(
                                compOffRequest: compOffRequest,
                              ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        _shouldRefresh = true;
                        context.read<CompOffDetailBloc>().add(
                          LoadCompOffDetail(requestId),
                        );
                      }
                    } else if (action == 'Activity') {
                      _showActivity(context, detail?.activity ?? const []);
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
          const SizedBox(height: 14),
          _userRow(
            context,
            'Requested By',
            requestBy,
            requestByImg,
            requestByColor,
          ),
          const SizedBox(height: 12),
          _fieldRow(
            context,
            'Requested For',
            DateFormat('dd-MMM-yyyy').format(date),
          ),
          _divider(),
          _fieldRow(
            context,
            'Duration',
            detail?.duration ?? widget.request.duration,
          ),
          _divider(),
          _approversRow(
            context,
            _detailFromState(
                  context.read<CompOffDetailBloc>().state,
                )?.approvers ??
                const [],
          ),
          _divider(),
          _statusRow(context, status),
          _divider(),
          const SizedBox(height: 6),
          Text(
            'Description',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            detail?.reason.isNotEmpty == true
                ? detail!.reason
                : widget.request.reason,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textPrimary),
          ),
          if (widget.isApprovalMode &&
              isPending &&
              compOffRequest.isEligibleToApprove) ...[
            const SizedBox(height: 16),
            BlocBuilder<CompOffDetailBloc, CompOffDetailState>(
              builder: (context, state) {
                return ApprovalActionBar(
                  embedded: true,
                  isLoading: state is CompOffDetailStatusUpdating,
                  onApprove:
                      requestId <= 0
                          ? null
                          : () {
                            context.read<CompOffDetailBloc>().add(
                              UpdateCompOffRequestStatus(
                                compOffId: requestId,
                                status: 'Approved',
                              ),
                            );
                          },
                  onReject:
                      requestId <= 0
                          ? null
                          : () {
                            context.read<CompOffDetailBloc>().add(
                              UpdateCompOffRequestStatus(
                                compOffId: requestId,
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

  Widget _userRow(
    BuildContext context,
    String label,
    String? name,
    String? imageUrl,
    String? color,
  ) {
    final initials =
        (name ?? 'U').trim().isNotEmpty ? (name ?? 'U').trim()[0] : 'U';
    final displayName =
        name?.trim().isNotEmpty == true ? name!.trim() : 'Not set';
    final bgColor = Color(
      _parseColor(color ?? '#0dcaf0'),
    ).withValues(alpha: 0.12);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMediumHeading(
            context,
          ).copyWith(fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: bgColor,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
              child:
                  imageUrl != null
                      ? null
                      : Text(
                        initials,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.primary),
                      ),
            ),
            SizedBox(width: 8),
            Text(
              displayName,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.primary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ],
    );
  }

  int _parseColor(String hexColor) {
    final cleaned = hexColor.replaceFirst('#', '');
    return int.tryParse('0xFF$cleaned') ?? 0xFF0DCAF0;
  }

  Widget _fieldRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _approversRow(
    BuildContext context,
    List<CompOffApprovalLevel> approvers,
  ) {
    final approverUsers = approvers.expand((level) => level.users).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Approvers',
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
          if (approverUsers.isNotEmpty)
            GestureDetector(
              onTap: () => _showApproversSheet(context, approvers),
              child: Row(
                children: [
                  _CompOffApproverAvatarStack(
                    users: approverUsers,
                    avatarSize: MediaQuery.sizeOf(context).width * 0.07,
                  ),
                  SizedBox(width: MediaQuery.sizeOf(context).width * 0.02),
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
      ),
    );
  }

  Widget _statusRow(BuildContext context, CompOffStatus status) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Status',
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.032,
              vertical: MediaQuery.sizeOf(context).height * 0.004,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.name[0].toUpperCase() + status.name.substring(1),
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Divider(height: 1, color: Color(0xFFE5E7EB)),
  );

  Widget _commentSection(
    BuildContext context,
    List<AttendanceRequestComment> comments,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comments', style: AppTextStyles.heading5(context)),
          const SizedBox(height: 10),
          _buildCommentBox(context),
          const SizedBox(height: 12),
          ...comments.map((c) => _commentTile(context, c)),
        ],
      ),
    );
  }

  Widget _buildCommentBox(BuildContext context) {
    final requestId = int.tryParse(widget.request.id) ?? 0;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment',
              hintStyle: AppTextStyles.bodyMedium(
                context,
              ).copyWith(color: AppColors.textSecondary),
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
        ),
        IconButton(
          onPressed: () {
            final text = _commentController.text.trim();
            if (text.isEmpty) return;
            _commentController.clear();
            _bloc.add(
              AddCompOffCommentEvent(compOffId: requestId, comment: text),
            );
          },
          icon: const Icon(Icons.send),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _commentTile(BuildContext context, AttendanceRequestComment comment) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final authorName =
        comment.user?.firstName.trim().isNotEmpty == true
            ? comment.user!.fullName
            : 'User';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.05,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName),
                    if (comment.createdAt != null)
                      Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(comment.createdAt!),
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.comment, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }

  CompOffDetail? _detailFromState(CompOffDetailState state) {
    if (state is CompOffDetailLoaded) return state.detail;
    if (state is CompOffDetailSubmitting) return state.detail;
    if (state is CompOffDetailStatusUpdating) return state.detail;
    if (state is CompOffDetailStatus) return state.detail;
    if (state is CompOffDetailError) return state.detail;
    return null;
  }

  List<AttendanceRequestComment> _commentsFromState(CompOffDetailState state) {
    if (state is CompOffDetailLoaded) return state.comments;
    if (state is CompOffDetailSubmitting) return state.comments;
    if (state is CompOffDetailStatusUpdating) return state.comments;
    if (state is CompOffDetailStatus) return state.comments;
    if (state is CompOffDetailError) return state.comments;
    return const [];
  }

  CompOffRequestModel _currentRequest(CompOffDetail? detail) {
    if (detail == null) return widget.request;
    return widget.request.copyWith(
      type: detail.type,
      date: detail.date ?? widget.request.date,
      duration: detail.duration,
      subject: detail.subject,
      reason: detail.reason,
      status: CompOffRequestModel.parseStatusValue(detail.status),
      createdAt: detail.createdAt ?? widget.request.createdAt,
    );
  }

  Color _statusColor(CompOffStatus status) {
    switch (status) {
      case CompOffStatus.pending:
        return AppColors.approvalSheetPending; //
      case CompOffStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case CompOffStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case CompOffStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
    }
  }

  void _showActivity(BuildContext context, List<CompOffActivity> activity) {
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
                (ctx, sc) => CompOffActivityBottomSheet(activity: activity),
          ),
    );
  }

  void _showApproversSheet(
    BuildContext context,
    List<CompOffApprovalLevel> approvers,
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
                  child: _CompOffApproversSheetContent(
                    approvers: approvers,
                    scrollController: sc,
                    sw: MediaQuery.of(context).size.width,
                  ),
                ),
          ),
    );
  }
}

class _CompOffApproverAvatarStack extends StatelessWidget {
  final List<CompOffApprover> users;
  final double avatarSize;

  const _CompOffApproverAvatarStack({
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

class _CompOffApproversSheetContent extends StatelessWidget {
  final List<CompOffApprovalLevel> approvers;
  final ScrollController scrollController;
  final double sw;

  const _CompOffApproversSheetContent({
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
            (level) => _CompOffApproverLevel(level: level, sw: sw),
          ),
      ],
    );
  }
}

class _CompOffApproverLevel extends StatelessWidget {
  final CompOffApprovalLevel level;
  final double sw;

  const _CompOffApproverLevel({required this.level, required this.sw});

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
        ...level.users.map((user) => _CompOffApproverTile(user: user, sw: sw)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CompOffApproverTile extends StatelessWidget {
  final CompOffApprover user;
  final double sw;

  const _CompOffApproverTile({required this.user, required this.sw});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    switch (user.approvalStatus.toLowerCase()) {
      case 'approved':
        statusColor = AppColors.approvalSheetAccept;
        break;
      case 'rejected':
        statusColor = AppColors.approvalSheetReject;
        break;
      case 'withdrawn':
        statusColor = AppColors.approvalSheetWithdrawn;
        break;
      case 'pending':
        statusColor = AppColors.approvalSheetPending;
        break;
      default:
        statusColor = AppColors.approvalSheetPending;
        break;
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

Color _parseHexColor(String hex) {
  final normalized = hex.replaceAll('#', '');
  final value = int.tryParse('FF$normalized', radix: 16);
  if (value == null) return AppColors.primary;
  return Color(value);
}
