import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/constants/app_urls.dart';
import '../../../../../../../../core/utils/data_encoder.dart';
import '../../../../../../../../core/utils/error_message_mapper.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/utils/token_storage.dart';
import '../../../../../../../../core/utils/app_navigator.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../../core/network/api_service.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../../../../../../attendance/data/datasources/attendance_regularize_remote_datasource.dart';
import '../../../../../../../attendance/data/repositories/attendance_regularize_repository_impl.dart';
import '../../../../../../../attendance/domain/usecases/add_attendance_request_comment_usecase.dart';
import '../../../../../../../attendance/domain/usecases/get_attendance_request_comments_usecase.dart';
import '../../../../../../../attendance/domain/entities/attendance_regularize_detail.dart';
import '../../../../../../../attendance/domain/usecases/get_regularize_request_detail_usecase.dart';
import '../../../../../../../attendance/domain/usecases/update_regularize_request_status_usecase.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../authentication/presentation/pages/login_page.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../../../../../../approval/presentation/widgets/approval_action_bar.dart';
import '../../../../../../../approval/presentation/widgets/reject_remark_sheet.dart';
import '../../../../../bloc/approvers/approvers_bloc.dart';
import '../../../leaves/data/datasources/approvers_remote_datasource.dart';
import '../../../leaves/data/repositories/approvers_repository_impl.dart';
import '../../../leaves/domain/usecases/get_approvers.dart';
import '../../../leaves/presentation/widgets/approvers_section.dart';
import '../../bloc/regularize_detail_bloc.dart';
import '../../bloc/regularize_detail_event.dart';
import '../../bloc/regularize_detail_state.dart';
import '../../models/regularize_request_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import 'apply_regularize_page.dart';
import '../widgets/regularize_activity_bottom_sheet.dart';

/// Regularize detail page showing full information about a regularize request
class RegularizeDetailPage extends StatefulWidget {
  final RegularizeRequestModel regularizeRequest;
  final bool isApprovalMode;

  const RegularizeDetailPage({
    super.key,
    required this.regularizeRequest,
    this.isApprovalMode = false,
  });

  @override
  State<RegularizeDetailPage> createState() => _RegularizeDetailPageState();
}

class _RegularizeDetailPageState extends State<RegularizeDetailPage> {
  final _commentController = TextEditingController();
  late final RegularizeDetailBloc _regularizeDetailBloc;
  bool _shouldRefreshListing = false;

  RegularizeRequestModel get _fallbackRequest => widget.regularizeRequest;

  int get _clientId => _resolveClientId();

  @override
  void initState() {
    super.initState();
    final networkInfo = NetworkInfoImpl(Connectivity());
    final apiClient = ApiClient(dio: Dio(), networkInfo: networkInfo);
    final remoteDataSource = AttendanceRegularizeRemoteDataSourceImpl(
      apiClient,
    );
    final repository = AttendanceRegularizeRepositoryImpl(
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );
    _regularizeDetailBloc = RegularizeDetailBloc(
      getRegularizeRequestDetailUseCase: GetRegularizeRequestDetailUseCase(
        repository,
      ),
      updateRegularizeRequestStatusUseCase:
          UpdateRegularizeRequestStatusUseCase(repository),
      getAttendanceRequestCommentsUseCase: GetAttendanceRequestCommentsUseCase(
        repository,
      ),
      addAttendanceRequestCommentUseCase: AddAttendanceRequestCommentUseCase(
        repository,
      ),
    )..add(
      LoadRegularizeDetail(
        requestId: int.tryParse(widget.regularizeRequest.id) ?? 0,
        clientId: _clientId,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _regularizeDetailBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider.value(
      value: _regularizeDetailBloc,
      child: BlocConsumer<RegularizeDetailBloc, RegularizeDetailState>(
        listenWhen: (previous, current) {
          if (current is! RegularizeDetailError) return true;
          final isInitialLoadFailure =
              current.detail == null &&
              (previous is RegularizeDetailInitial ||
                  previous is RegularizeDetailLoading);
          return !isInitialLoadFailure;
        },
        listener: (context, state) {
          if (state is RegularizeDetailStatusUpdated) {
            _shouldRefreshListing = true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is RegularizeDetailError) {
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
          final screenHeight = MediaQuery.of(context).size.height;
          final detail = _detailFromState(state);
          final currentRequest = _currentRequest(detail);
          final currentStatus = currentRequest.status;
          final comments = _commentsFromState(state);
          final isBusy =
              state is RegularizeDetailLoading ||
              state is RegularizeDetailStatusUpdating ||
              state is RegularizeCommentSubmitting;

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
                    forceMaterialTransparency: true,
                    elevation: 0,
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
                      widget.isApprovalMode
                          ? 'Regularize Approval'
                          : 'Regularize',
                      style: AppTextStyles.heading4(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  bottomNavigationBar:
                      widget.isApprovalMode
                          ? (currentStatus == RegularizeStatus.pending &&
                                  currentRequest.isEligibleToApprove
                              ? ApprovalActionBar(
                                isLoading:
                                    state is RegularizeDetailStatusUpdating,
                                onApprove:
                                    () => _updateRequestStatus('Approved'),
                                onReject: () => _showRejectRemarkSheet(context),
                              )
                              : BottomNavBar(
                                currentIndex: 4,
                                onTap: NavigationHelper.getBottomNavHandler(
                                  context,
                                ),
                              ))
                          : BottomNavBar(
                            currentIndex: 3,
                            onTap: NavigationHelper.getBottomNavHandler(
                              context,
                            ),
                          ),
                  body:
                      state is RegularizeDetailError && state.detail == null
                          ? ApiErrorState(
                            title: 'Unable to load regularize details',
                            rawMessage: state.message,
                            onRetry:
                                () => context.read<RegularizeDetailBloc>().add(
                                  LoadRegularizeDetail(
                                    requestId:
                                        int.tryParse(
                                          widget.regularizeRequest.id,
                                        ) ??
                                        0,
                                    clientId: _clientId,
                                  ),
                                ),
                          )
                          : _buildDetailsContent(
                            context,
                            screenWidth,
                            screenHeight,
                            detail,
                            currentRequest,
                            comments,
                            state,
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
    AttendanceRegularizeDetail? detail,
    RegularizeRequestModel currentRequest,
    List<AttendanceRequestComment> comments,
    RegularizeDetailState state,
  ) {
    final statusColor = _getStatusColor(currentRequest.status);
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final dateTimeFormat = DateFormat('dd-MMM-yyyy hh:mm a');

    // Calculate number of days
    final numberOfDays =
        currentRequest.toDate != null
            ? currentRequest.toDate!
                    .difference(currentRequest.fromDate)
                    .inDays +
                1
            : 1;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.002),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Regularize Details Card
          _buildDetailsCard(
            context,
            screenWidth,
            screenHeight,
            statusColor,
            dateFormat,
            dateTimeFormat,
            numberOfDays,
            currentRequest,
            state,
          ),
          SizedBox(height: screenHeight * 0.02),
          // Comments Section
          _buildCommentsSection(context, screenWidth, screenHeight, comments),
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
    int numberOfDays,
    RegularizeRequestModel currentRequest,
    RegularizeDetailState state,
  ) {
    final requestId = int.tryParse(widget.regularizeRequest.id) ?? 0;
    final detail = _detailFromState(state);
    final isPending = currentRequest.status == RegularizeStatus.pending;
    final requestToDate = currentRequest.toDate;
    final isSingleDayRequest =
        requestToDate == null ||
        (requestToDate.year == currentRequest.fromDate.year &&
            requestToDate.month == currentRequest.fromDate.month &&
            requestToDate.day == currentRequest.fromDate.day);
    final menuActions = <Map<String, String>>[
      if (isPending && !widget.isApprovalMode)
        {'value': 'Edit', 'icon': AppAssets.editIconwfh},
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
            spreadRadius: 0,
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
              Flexible(
                child: Text(
                  currentRequest.reason,
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor, // Green color for title
                  ),
                ),
              ),
              if (menuActions.length >= 2)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.textPrimary),
                  onSelected: (value) async {
                    if (value == 'Edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ApplyRegularizePage(
                                regularizeRequest: currentRequest,
                              ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        _shouldRefreshListing = true;
                        context.read<RegularizeDetailBloc>().add(
                          LoadRegularizeDetail(
                            requestId: requestId,
                            clientId: _clientId,
                          ),
                        );
                      }
                    } else if (value == 'Withdraw') {
                      context.read<RegularizeDetailBloc>().add(
                        UpdateRegularizeRequestStatus(
                          requestId: requestId,
                          clientId: _clientId,
                          status: 'Withdrawn',
                        ),
                      );
                    } else if (value == 'Activity') {
                      _showActivityBottomSheet(
                        context,
                        detail?.activity ?? const [],
                      );
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
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ApplyRegularizePage(
                                regularizeRequest: currentRequest,
                              ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        _shouldRefreshListing = true;
                        context.read<RegularizeDetailBloc>().add(
                          LoadRegularizeDetail(
                            requestId: requestId,
                            clientId: _clientId,
                          ),
                        );
                      }
                    } else if (action == 'Withdraw') {
                      context.read<RegularizeDetailBloc>().add(
                        UpdateRegularizeRequestStatus(
                          requestId: requestId,
                          clientId: _clientId,
                          status: 'Withdrawn',
                        ),
                      );
                    } else if (action == 'Activity') {
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
          SizedBox(height: screenHeight * 0.02),
          _buildDetailRow(
            context,
            'Leave Type:',
            currentRequest.reason,
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),

          _buildDetailRow(
            context,
            'Request For:',
            currentRequest.requestType.displayName,
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),

          _buildDetailRow(
            context,
            'No. of Days:',
            numberOfDays.toString().padLeft(2, '0'),
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            isSingleDayRequest ? 'On:' : 'From:',
            dateFormat.format(currentRequest.fromDate),
            screenWidth,
            screenHeight,
          ),
          if (!isSingleDayRequest) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'To:',
              currentRequest.toDate != null
                  ? dateFormat.format(currentRequest.toDate!)
                  : dateFormat.format(currentRequest.fromDate),
              screenWidth,
              screenHeight,
            ),
          ],
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Check-In:',
            currentRequest.checkIn != null
                ? dateTimeFormat.format(currentRequest.checkIn!)
                : 'N/A',
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Check-Out:',
            currentRequest.checkOut != null
                ? dateTimeFormat.format(currentRequest.checkOut!)
                : 'N/A',
            screenWidth,
            screenHeight,
          ),
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildDetailRow(
            context,
            'Applied On:',
            dateTimeFormat.format(currentRequest.appliedDate),
            screenWidth,
            screenHeight,
          ),
          // Show reject remark if rejected
          if (currentRequest.status == RegularizeStatus.rejected &&
              currentRequest.rejectRemark != null) ...[
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            _buildDetailRow(
              context,
              'Reject Remark:',
              currentRequest.rejectRemark!,
              screenWidth,
              screenHeight,
            ),
          ],
          Divider(height: screenHeight * 0.03, color: AppColors.border),
          _buildApproversRow(context, screenWidth, screenHeight, detail),
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
          ),
        ],
      ),
    );
  }

  Widget _buildApproversRow(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    AttendanceRegularizeDetail? detail,
  ) {
    final approvers =
        detail?.approvers.expand((level) => level.users).toList() ?? const [];

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
                _RegularizeApproverAvatarStack(
                  approvers: approvers,
                  avatarSize: screenWidth * 0.07,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  approvers.length == 1
                      ? approvers.first.fullName
                      : '${approvers.length} approvers',
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

  ///Approver bottomsheet
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
                      endpoint: AppUrls.regularizeRequestDetails,
                      payload: {
                        'request_id':
                            int.tryParse(widget.regularizeRequest.id) ?? 0,
                      },
                    ),
                  ),
                ),
          ),
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
    RegularizeRequestModel currentRequest,
  ) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      padding: EdgeInsets.all(screenWidth * 0.042),
      width: double.infinity,
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
            currentRequest.description?.isNotEmpty == true
                ? currentRequest.description!
                : currentRequest.reason,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
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
            spreadRadius: 0,
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
                context.read<RegularizeDetailBloc>().add(
                  AddRegularizeComment(
                    requestId: int.tryParse(widget.regularizeRequest.id) ?? 0,
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
    List<AttendanceRegularizeActivity> activity,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            // Start at half screen
            minChildSize: 0.3,
            // Minimum 30% of screen
            maxChildSize: 0.9,
            // Maximum 90% of screen (can be dragged up)
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
                  child: RegularizeActivityBottomSheet(
                    scrollController: scrollController,
                    activity: activity,
                  ),
                ),
          ),
    );
  }

  Future<void> _updateRequestStatus(String status) async {
    _regularizeDetailBloc.add(
      UpdateRegularizeRequestStatus(
        requestId: int.tryParse(widget.regularizeRequest.id) ?? 0,
        clientId: _clientId,
        status: status,
      ),
    );
  }

  void _showRejectRemarkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: RejectRemarkSheet(
              onSubmit: (_) async {
                await _updateRequestStatus('Rejected');
              },
            ),
          ),
    );
  }

  Color _getStatusColor(RegularizeStatus status) {
    switch (status) {
      case RegularizeStatus.pending:
        return AppColors.approvalSheetPending; //
      case RegularizeStatus.approved:
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case RegularizeStatus.rejected:
        return AppColors.approvalSheetReject; // 0xFFF04438
      case RegularizeStatus.withdrawn:
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
    }
  }

  AttendanceRegularizeDetail? _detailFromState(RegularizeDetailState state) {
    if (state is RegularizeDetailLoaded) return state.detail;
    if (state is RegularizeDetailStatusUpdating) return state.detail;
    if (state is RegularizeCommentSubmitting) return state.detail;
    if (state is RegularizeDetailError) return state.detail;
    return null;
  }

  List<AttendanceRequestComment> _commentsFromState(
    RegularizeDetailState state,
  ) {
    if (state is RegularizeDetailLoaded) return state.comments;
    if (state is RegularizeDetailStatusUpdating) return state.comments;
    if (state is RegularizeCommentSubmitting) return state.comments;
    if (state is RegularizeDetailError) return state.comments;
    return const [];
  }

  RegularizeRequestModel _currentRequest(AttendanceRegularizeDetail? detail) {
    if (detail == null) return _fallbackRequest;

    return _fallbackRequest.copyWith(
      id: detail.id.toString(),
      requestType: RegularizeRequestModel.parseRequestTypeValue(
        detail.requestFor,
      ),
      fromDate: detail.requestDate ?? _fallbackRequest.fromDate,
      checkIn: detail.checkIn ?? _fallbackRequest.checkIn,
      checkOut: detail.checkOut ?? _fallbackRequest.checkOut,
      reason: detail.reason,
      description: detail.description ?? _fallbackRequest.description,
      modeType: detail.modeType ?? _fallbackRequest.modeType,
      status: RegularizeRequestModel.parseStatusValue(detail.requestStatus),
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
}

class _RegularizeApproverAvatar extends StatelessWidget {
  final AttendanceRegularizeApprover approver;
  final double size;

  const _RegularizeApproverAvatar({required this.approver, required this.size});

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

class _RegularizeApproverAvatarStack extends StatelessWidget {
  final List<AttendanceRegularizeApprover> approvers;
  final double avatarSize;

  const _RegularizeApproverAvatarStack({
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
            ? avatarSize + (edgePadding * 2)
            : avatarSize +
                ((visibleApprovers.length - 1) * (avatarSize - overlap)) +
                (edgePadding * 2);

    return SizedBox(
      width: width,
      height: avatarSize + (edgePadding * 2),
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
                child: _RegularizeApproverAvatar(
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
