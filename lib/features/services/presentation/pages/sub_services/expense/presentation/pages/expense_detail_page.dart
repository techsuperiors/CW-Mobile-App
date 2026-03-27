import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../../../core/constants/app_assets.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/network/api_client.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../../../../../../user/presentation/bloc/user_profile_bloc.dart';
import '../../../../../../../user/presentation/bloc/user_profile_state.dart';
import '../../data/expense_remote_data.dart';
import '../../data/models/expense_detail_model.dart';
import '../../data/models/expense_item_model.dart';
import 'edit_expense_page.dart';

class ExpenseDetailPage extends StatefulWidget {
  final ExpenseItemModel expense;

  const ExpenseDetailPage({super.key, required this.expense});

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  late final ExpenseRemoteData _remoteData;
  late Future<ExpenseDetailModel> _detailFuture;
  final Set<int> _expandedIndices = <int>{0};
  bool _isWithdrawing = false;
  bool _shouldRefreshParent = false;

  @override
  void initState() {
    super.initState();
    _remoteData = ExpenseRemoteData(
      apiClient: ApiClient(
        dio: Dio(),
        networkInfo: NetworkInfoImpl(Connectivity()),
      ),
    );
    _detailFuture = _remoteData.getExpenseDetails(expenseId: widget.expense.id);
  }
  @override
  void dispose() {
    super.dispose();
  }

  void _reload() {
    setState(() {
      _detailFuture = _remoteData.getExpenseDetails(
        expenseId: widget.expense.id,
      );
    });
  }

  Future<void> _showWithdrawDialog(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Withdraw Expense',
              style: AppTextStyles.heading5(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to withdraw this expense request?',
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
                onPressed: () => Navigator.of(ctx).pop(true),
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

    if (confirmed != true || _isWithdrawing || !mounted) return;

    setState(() => _isWithdrawing = true);
    try {
      final message = await _remoteData.withdrawExpense(
        expenseId: widget.expense.id,
      );
      if (!mounted) return;
      _shouldRefreshParent = true;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
      navigator.pop(true);
    } on ServerException catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to withdraw expense request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isWithdrawing = false);
      }
    }
  }

  void _showActivitySheet(BuildContext context, ExpenseDetailModel detail) {
    final sw = MediaQuery.of(context).size.width;
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
                      if (detail.activity.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No activity available.',
                            style: AppTextStyles.bodyMedium(
                              context,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...detail.activity.map(
                          (activity) => _ExpenseActivityTile(
                            activity: activity,
                            sw: sw,
                          ),
                        ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_shouldRefreshParent);
      },
      child: ResponsiveScaffold(
      backgroundColor: AppColors.backgroundMedium,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(_shouldRefreshParent),
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
          'Reimbursement',
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          FutureBuilder<ExpenseDetailModel>(
            future: _detailFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final detail = snapshot.data!;
              final isPending =
                  detail.approvalStatus.toLowerCase() == 'pending';

              return PopupMenuButton<String>(
                enabled: !_isWithdrawing,
                icon:
                    _isWithdrawing
                        ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        )
                        : Icon(Icons.more_vert, color: AppColors.textPrimary),
                onSelected: (value) async {
                  switch (value) {
                    case 'Edit':
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditExpensePage(detail: detail),
                        ),
                      );
                      if (updated == true && mounted) {
                        _shouldRefreshParent = true;
                        _reload();
                      }
                      break;
                    case 'Withdraw':
                      _showWithdrawDialog(context);
                      break;
                    case 'Activity':
                      _showActivitySheet(context, detail);
                      break;
                  }
                },
                itemBuilder: (context) {
                  return [
                    if (widget.expense.isEditEnabled)
                      PopupMenuItem(
                        value: 'Edit',
                        child: Row(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.05,
                              height: screenHeight * 0.05,
                              child: SvgPicture.asset(AppAssets.editIconwfh),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'Edit',
                              style: AppTextStyles.heading5(context).copyWith(
                                fontWeight: FontWeight.w400,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isPending)
                      PopupMenuItem(
                        value: 'Withdraw',
                        child: Row(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.05,
                              height: screenHeight * 0.05,
                              child: SvgPicture.asset(AppAssets.withdrawIcon),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'Withdraw',
                              style: AppTextStyles.heading5(context).copyWith(
                                fontWeight: FontWeight.w400,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'Activity',
                      child: Row(
                        children: [
                          SizedBox(
                            width: screenWidth * 0.05,
                            height: screenHeight * 0.05,
                            child: SvgPicture.asset(AppAssets.activityIcon),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Activity',
                            style: AppTextStyles.heading5(context).copyWith(
                              fontWeight: FontWeight.w400,
                              color: AppColors.textHeading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: FutureBuilder<ExpenseDetailModel>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ApiErrorState(
              rawMessage: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final detail = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _DetailCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              detail.expenseName,
                              style: AppTextStyles.heading4(context).copyWith(
                                color: AppColors.attendanceTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _RequestByRow(user: detail.requestUser),
                      Divider(
                        height: screenHeight * 0.03,
                        color: AppColors.border,
                      ),
                      _InfoRow(
                        label: 'Amount',
                        value: NumberFormat.currency(
                          symbol: '₹',
                          decimalDigits: 0,
                        ).format(detail.amount),
                      ),
                      Divider(
                        height: screenHeight * 0.03,
                        color: AppColors.border,
                      ),

                      _InfoRow(
                        label: 'Invoice Number',
                        value: detail.invoiceNumber ?? '—',
                      ),
                      Divider(
                        height: screenHeight * 0.03,
                        color: AppColors.border,
                      ),

                      _InfoRow(
                        label: 'Reimbursement Policy Name',
                        value:
                            detail.policy.policyName.isEmpty
                                ? '—'
                                : detail.policy.policyName,
                      ),
                      Divider(
                        height: screenHeight * 0.03,
                        color: AppColors.border,
                      ),

                      _InfoRow(
                        label: 'Status',
                        valueWidget: _StatusChip(status: detail.approvalStatus),
                      ),
                      Divider(
                        height: screenHeight * 0.03,
                        color: AppColors.border,
                      ),
                      Text(
                        'Description',
                        style: AppTextStyles.bodyMediumHeading(
                          context,
                        ).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        (detail.description?.trim().isNotEmpty ?? false)
                            ? detail.description!.trim()
                            : 'No description available.',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(height: 1.1, color: AppColors.textSecondary),
                      ),
                      Divider(
                        height: screenHeight * 0.03,
                        color: AppColors.border,
                      ),
                      Text(
                        'Attachment',
                        style: AppTextStyles.bodyMediumHeading(
                          context,
                        ).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      if (detail.documents.isEmpty)
                        Text(
                          'No attachments',
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              detail.documents
                                  .map((doc) => _AttachmentTile(document: doc))
                                  .toList(),
                        ),
                      Divider(
                        height: screenHeight * 0.03,
                        color: AppColors.border,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        'Levels',
                        style: AppTextStyles.bodyMediumHeading(
                          context,
                        ).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.004),
                      Text(
                        'Configure different components and their respective limits or requirements.',
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      ...List.generate(
                        detail.approvals.length,
                        (index) => _ApprovalLevelTile(
                          approval: detail.approvals[index],
                          index: index,
                          isExpanded: _expandedIndices.contains(index),
                          onToggle: () {
                            setState(() {
                              if (_expandedIndices.contains(index)) {
                                _expandedIndices.remove(index);
                              } else {
                                _expandedIndices.add(index);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                _ExpenseCommentsSection(
                  expenseId: detail.id,
                  initialComments: detail.comments,
                  remoteData: _remoteData,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
              ],
            ),
          );
        },
      ),
    ));
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.02,
        horizontal: screenWidth * 0.04,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ExpenseCommentsSection extends StatefulWidget {
  final int expenseId;
  final List<ExpenseComment> initialComments;
  final ExpenseRemoteData remoteData;
  final double screenWidth;
  final double screenHeight;

  const _ExpenseCommentsSection({
    required this.expenseId,
    required this.initialComments,
    required this.remoteData,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<_ExpenseCommentsSection> createState() => _ExpenseCommentsSectionState();
}

class _ExpenseCommentsSectionState extends State<_ExpenseCommentsSection> {
  late final TextEditingController _commentController;
  late List<ExpenseComment> _comments;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _comments = List<ExpenseComment>.from(widget.initialComments);
  }

  @override
  void didUpdateWidget(covariant _ExpenseCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenseId != widget.expenseId) {
      _comments = List<ExpenseComment>.from(widget.initialComments);
      return;
    }
    if (!_isSubmittingComment &&
        oldWidget.initialComments != widget.initialComments) {
      _comments = List<ExpenseComment>.from(widget.initialComments);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || _isSubmittingComment) return;

    final profileState = context.read<UserProfileBloc>().state;
    if (profileState is! UserProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile is not loaded yet.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final profile = profileState.profile;
    final newComment = ExpenseComment(
      id: 'expense-comment-${DateTime.now().microsecondsSinceEpoch}',
      comment: commentText,
      createdAt: DateTime.now().toUtc(),
      createdBy: ExpenseRequester(
        id: profile.user.id,
        firstName: profile.user.firstName ?? '',
        lastName: profile.user.lastName ?? '',
        imageUrl: profile.user.imageUrl,
        profileColor: profile.user.profileColor,
      ),
    );

    final payloadComments = [
      ..._comments.map((comment) => comment.toPayloadJson()),
      newComment.toPayloadJson(),
    ];

    setState(() => _isSubmittingComment = true);
    try {
      final message = await widget.remoteData.updateExpenseComments(
        expenseId: widget.expenseId,
        comments: payloadComments,
      );
      if (!mounted) return;

      _commentController.clear();
      setState(() {
        _comments = [..._comments, newComment];
        _isSubmittingComment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingComment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = widget.screenWidth;
    final screenHeight = widget.screenHeight;

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Comments',
                style: AppTextStyles.bodyMediumHeading(
                  context,
                ).copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
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
                  style: AppTextStyles.labelSmall(
                    context,
                  ).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Keep updates and discussion in one place.',
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: screenHeight * 0.018),
          if (_comments.isNotEmpty) ...[
            ..._comments.map(
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
                          _Avatar(
                            user: comment.createdBy,
                            size: screenWidth * 0.09,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment.createdBy.fullName.isEmpty
                                      ? 'User'
                                      : comment.createdBy.fullName,
                                  style: AppTextStyles.bodyMediumHeading(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: screenHeight * 0.002),
                                Text(
                                  comment.createdAt != null
                                      ? DateFormat('dd MMM yyyy, hh:mm a')
                                          .format(comment.createdAt!.toLocal())
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
                        ).copyWith(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.008),
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
                      hintStyle: AppTextStyles.bodySmall(
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
                    onPressed: _isSubmittingComment ? null : _submitComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.attendanceTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: _isSubmittingComment
                        ? SizedBox(
                            width: screenWidth * 0.045,
                            height: screenWidth * 0.045,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestByRow extends StatelessWidget {
  final ExpenseRequester user;

  const _RequestByRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Request By',
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _Avatar(user: user, size: 30),
              SizedBox(width: screenWidth * 0.024),
              Flexible(
                child: Text(
                  user.fullName.isEmpty ? '—' : user.fullName,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.attendanceTeal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: AppTextStyles.bodyMediumHeading(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child:
                valueWidget ??
                Text(
                  value ?? '—',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyMediumHeading(context).copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF12B76A);
      case 'rejected':
      case 'withdrawn':
        return const Color(0xFFF04438);
      default:
        return const Color(0xFF0086C9);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelSmall(
          context,
        ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ExpenseActivityTile extends StatelessWidget {
  final ExpenseActivity activity;
  final double sw;

  const _ExpenseActivityTile({required this.activity, required this.sw});

  @override
  Widget build(BuildContext context) {
    final cleanText = activity.action.replaceAll(RegExp(r'<[^>]*>'), '');
    final actorName = '${activity.firstName} ${activity.lastName}'.trim();
    final accentColor = switch (activity.actionType.toLowerCase()) {
      'document_upload' => AppColors.primary,
      'update' => AppColors.attendanceTeal,
      'create' => const Color(0xFF12B76A),
      _ => AppColors.textSecondary,
    };
    final initials =
        actorName.isEmpty
            ? 'A'
            : actorName
                .split(' ')
                .where((part) => part.isNotEmpty)
                .take(2)
                .map((part) => part[0].toUpperCase())
                .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(sw * 0.035),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 42,
                margin: EdgeInsets.only(right: sw * 0.03),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.labelSmall(
                      context,
                    ).copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (actorName.isNotEmpty)
                      Text(
                        actorName,
                        style: AppTextStyles.bodySmall(
                          context,
                        ).copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (actorName.isNotEmpty) const SizedBox(height: 4),
                    Text(
                      cleanText.isEmpty ? 'Activity updated' : cleanText,
                      style: AppTextStyles.bodyMediumHeading(
                        context,
                      ).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (activity.actionType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    activity.actionType.replaceAll('_', ' '),
                    style: AppTextStyles.labelSmall(
                      context,
                    ).copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              if (activity.createdAt != null)
                Text(
                  DateFormat(
                    'dd MMM yyyy, hh:mm a',
                  ).format(activity.createdAt!.toLocal()),
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final ExpenseDocument document;

  const _AttachmentTile({required this.document});

  bool get _isPdf => document.url.toLowerCase().endsWith('.pdf');

  void _open(BuildContext context) {
    if (_isPdf) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Container(
                  height: 50,
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PDF Preview',
                        style: TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(child: SfPdfViewer.network(document.url)),
              ],
            ),
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: document.url,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileSize = MediaQuery.of(context).size.width * 0.22;

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: tileSize.clamp(80.0, 104.0),
        height: tileSize.clamp(80.0, 104.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child:
              _isPdf
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                        size: 30,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          document.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelSmall(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  )
                  : CachedNetworkImage(
                    imageUrl: document.url,
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, __, ___) => const Icon(Icons.broken_image_outlined),
                  ),
        ),
      ),
    );
  }
}

class _ApprovalLevelTile extends StatelessWidget {
  final ExpenseApprovalDetail approval;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ApprovalLevelTile({
    required this.approval,
    required this.index,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.002),
            child: Column(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.border,
                  size: 26,
                ),
                if (!isExpanded)
                  Container(
                    width: screenWidth * 0.002,
                    height: screenHeight * 0.02,
                    color: AppColors.border,
                  ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: onToggle,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Level ${index + 1}',
                              style: AppTextStyles.bodyMediumHeading(
                                context,
                              ).copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          _StatusChip(status: approval.approvalStatus),
                          SizedBox(width: screenWidth * 0.004),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE9EDF2)),
                        ),
                      ),
                      child: Column(
                        children: [
                          _ApprovalInfoRow(
                            label: 'Approver Name',
                            valueWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Avatar(user: approval.assignee, size: 24),
                                SizedBox(width: screenWidth * 0.02),
                                Flexible(
                                  child: Text(
                                    approval.assignee.fullName.isEmpty
                                        ? '—'
                                        : approval.assignee.fullName,
                                    style: AppTextStyles.bodySmall(
                                      context,
                                    ).copyWith(
                                      color: AppColors.attendanceTeal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ApprovalInfoRow(
                            label: 'Approve Date',
                            value:
                                approval.actionTakenAt == null
                                    ? '—'
                                    : DateFormat(
                                      'dd-MMM-yyyy',
                                    ).format(approval.actionTakenAt!),
                          ),
                          _ApprovalInfoRow(
                            label: 'Remark',
                            value:
                                (approval.remarks?.trim().isNotEmpty ?? false)
                                    ? approval.remarks!.trim()
                                    : '—',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalInfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _ApprovalInfoRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyles.bodyMediumHeading(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  valueWidget ??
                  Text(
                    value ?? '—',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodySmall(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final ExpenseRequester user;
  final double size;

  const _Avatar({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    if (user.imageUrl?.isNotEmpty == true) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: user.imageUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _InitialAvatar(user: user, size: size),
          ),
        ),
      );
    }
    return _InitialAvatar(user: user, size: size);
  }
}

class _InitialAvatar extends StatelessWidget {
  final ExpenseRequester user;
  final double size;

  const _InitialAvatar({required this.user, required this.size});

  Color _parseColor() {
    final raw = user.profileColor?.replaceFirst('#', '');
    if (raw == null || raw.isEmpty) return AppColors.attendanceTeal;
    final normalized = raw.length == 6 ? 'FF$raw' : raw;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFF0DC5C1);
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        user.fullName.isEmpty
            ? '?'
            : user.fullName
                .split(' ')
                .where((part) => part.isNotEmpty)
                .take(2)
                .map((part) => part[0].toUpperCase())
                .join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _parseColor(),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelSmall(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
