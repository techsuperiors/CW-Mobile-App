import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/visit_model.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../widgets/visit_activity_card.dart';
import '../widgets/visit_activity_complete_dialog.dart';
import '../widgets/visit_activity_start_dialog.dart';
import '../widgets/visit_initial_avatar.dart';
import 'visit_activity_details_page.dart';

class VisitDetailPage extends StatefulWidget {
  final int visitId;

  const VisitDetailPage({super.key, required this.visitId});

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VisitBloc>().add(LoadVisitDetails(widget.visitId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                size: AppTextStyles.bodyMedium(context).fontSize,
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
          'Visit Management',
          style: AppTextStyles.heading4(
            context,
          ).copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: BlocConsumer<VisitBloc, VisitState>(
        listenWhen:
            (previous, current) =>
                previous.deleteActivityError != current.deleteActivityError ||
                previous.deleteActivitySuccessMessage !=
                    current.deleteActivitySuccessMessage ||
                previous.lastDeletedActivityId != current.lastDeletedActivityId,
        listener: (context, state) {
          final message =
              state.deleteActivitySuccessMessage ?? state.deleteActivityError;
          if (message == null || message.isEmpty) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
          context.read<VisitBloc>().add(const ClearVisitFeedback());
        },
        builder: (context, state) {
          final detail = state.visitDetail;
          final isCurrentDetail = detail != null && detail.id == widget.visitId;

          if (state.isVisitDetailLoading && !isCurrentDetail) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.visitDetailError != null && !isCurrentDetail) {
            return ApiErrorState(
              title: 'Unable to load visit details',
              rawMessage: state.visitDetailError,
              onRetry:
                  () => context.read<VisitBloc>().add(
                    LoadVisitDetails(widget.visitId),
                  ),
            );
          }

          if (!isCurrentDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          _ensureActivityDetailsLoaded(detail, state);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<VisitBloc>().add(LoadVisitDetails(widget.visitId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, detail),
                  AppSpacing.vLg,
                  Text(
                    'Activities',
                    style: AppTextStyles.bodyMediumHeading(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  AppSpacing.vSm,
                  if (detail.activities.isNotEmpty) ...[
                    _buildActivitiesStatusCard(context, detail.activities),
                    AppSpacing.vSm,
                  ],
                  if (detail.activities.isEmpty)
                    _buildEmptyActivitiesCard(context)
                  else
                    ...detail.activities.map(
                      (activity) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: VisitActivityCard(
                          activity: activity,
                          visitScheduledDate: detail.scheduledDate,
                          activityDetail:
                              state.visitActivityDetailsById[activity.id],
                          isLoadingDetails: state.loadingVisitActivityDetailIds
                              .contains(activity.id),
                          detailError:
                              state.visitActivityDetailErrorsById[activity.id],
                          isStarting: state.startingVisitActivityIds.contains(
                            activity.id,
                          ),
                          isCompleting: state.completingVisitActivityIds
                              .contains(activity.id),
                          isDeleting: state.deletingVisitActivityIds.contains(
                            activity.id,
                          ),
                          onStartActivity:
                              _isPlannedActivity(activity)
                                  ? () => _openStartActivityDialog(activity)
                                  : null,
                          onViewDetails:
                              (_isPlannedActivity(activity) ||
                                      _isPendingActivity(activity) ||
                                      _isCompletedActivity(activity) ||
                                      _isStartedActivity(activity))
                                  ? () => _openActivityDetailsPage(
                                    activity,
                                    detail.scheduledDate,
                                  )
                                  : null,
                          onDeleteActivity:
                              _isPlannedActivity(activity)
                                  ? () => context.read<VisitBloc>().add(
                                    DeleteVisitActivityRequested(activity.id),
                                  )
                                  : null,
                          onCompleteActivity:
                              _isStartedActivity(activity)
                                  ? () => _openCompleteActivityDialog(activity)
                                  : null,
                          onCancelActivity:
                              _isStartedActivity(activity)
                                  ? () => _openCancelActivityDialog(activity)
                                  : null,
                          onRetryLoadDetails:
                              (_isStartedActivity(activity) ||
                                      _isCompletedActivity(activity))
                                  ? () => context.read<VisitBloc>().add(
                                    LoadVisitActivityDetails(activity.id),
                                  )
                                  : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, VisitDetailModel detail) {
    final assignedLabel = _assignedEmployeeLabel(detail);
    final assignedUser = _assignedUser(detail);
    final totalDuration = _formatVisitDuration(
      startTime: detail.startTime,
      endTime: detail.endTime,
    );

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.visitTitle,
            style: AppTextStyles.heading4(
              context,
            ).copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          AppSpacing.vLg,
          _buildInfoRow(
            context,
            label: 'Visit Type',
            value: _visitTypeLabel(detail.type),
          ),
          _buildDivider(),
          _buildInfoRow(
            context,
            label: 'Visit Date',
            value: _formatScheduledDate(detail.scheduledDate),
          ),
          _buildDivider(),
          _buildInfoRow(
            context,
            label: 'Start Time',
            value: detail.startTime ?? '--',
          ),
          _buildDivider(),
          _buildInfoRow(context, label: 'Total Duration', value: totalDuration),
          _buildDivider(),
          _buildAssigneeRow(
            context,
            label: 'Assigned Employee',
            value: assignedLabel,
            user: assignedUser,
          ),
          if ((detail.description?.trim().isNotEmpty ?? false)) ...[
            _buildDivider(),
            Text(
              'Description',
              style: AppTextStyles.bodyMediumHeading(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            AppSpacing.vSm,
            Text(
              detail.description!.trim(),
              style: AppTextStyles.bodyMediumHeading(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        AppSpacing.hMd,
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildAssigneeRow(
    BuildContext context, {
    required String label,
    required String value,
    required VisitUserModel user,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        AppSpacing.hMd,
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              VisitInitialAvatar(
                label: user.fullName,
                imageUrl: user.imageUrl,
                profileColor: user.profileColor,
                radius: 12,
              ),
              AppSpacing.hSm,
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(height: 1, color: AppColors.border),
    );
  }

  Widget _buildEmptyActivitiesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No activities added yet.',
        style: AppTextStyles.bodyMedium(
          context,
        ).copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildActivitiesStatusCard(
    BuildContext context,
    List<VisitActivityModel> activities,
  ) {
    final summary = _activityStatusSummary(activities);
    final segments = [
      _ActivityStatusSegmentData(
        label: 'Scheduled',
        count: summary.scheduledCount,
        color: AppColors.primary,
      ),
      _ActivityStatusSegmentData(
        label: 'Completed',
        count: summary.completedCount,
        color: AppColors.successDark,
      ),
      _ActivityStatusSegmentData(
        label: 'Pending',
        count: summary.pendingCount,
        color: AppColors.warning,
      ),
    ];
    final visibleSegments = segments
        .where((segment) => segment.count > 0)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingSmall,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppSpacing.md,
            offset: Offset(0, AppSpacing.xs),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Activities Status',
                  style: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          AppSpacing.vMd,
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: segments
                .map(
                  (segment) => _buildActivityLegend(
                    context,
                    label: segment.label,
                    color: segment.color,
                  ),
                )
                .toList(growable: false),
          ),
          AppSpacing.vLg,
          if (visibleSegments.isEmpty)
            Container(
              height: AppSpacing.lg,
              decoration: BoxDecoration(
                color: AppColors.backgroundMedium,
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: SizedBox(
                height: AppSpacing.lg,
                child: Row(
                  children: visibleSegments
                      .map(
                        (segment) => Expanded(
                          flex: segment.count,
                          child: Container(
                            color: segment.color,
                            alignment: Alignment.center,
                            child: Text(
                              segment.count.toString(),
                              style: AppTextStyles.labelSmall(context).copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),

          AppSpacing.vSm,
        ],
      ),
    );
  }

  Widget _buildActivityLegend(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.md,
          height: AppSpacing.md,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        AppSpacing.hXs,
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _visitTypeLabel(VisitType? type) {
    return switch (type) {
      VisitType.customer => 'Customer Based Visit',
      VisitType.address => 'Address Based Visit',
      null => '--',
    };
  }

  String _formatScheduledDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('dd-MMMM-yyyy').format(date);
  }

  String _formatVisitDuration({
    required String? startTime,
    required String? endTime,
  }) {
    if (startTime == null || endTime == null) return '--';
    try {
      final formatter = DateFormat('hh:mm a');
      final start = formatter.parseStrict(startTime);
      final end = formatter.parseStrict(endTime);
      final difference = end.difference(start);
      if (difference.inMinutes <= 0) return '--';
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      if (hours > 0 && minutes > 0) {
        return '${hours.toString().padLeft(2, '0')} hr ${minutes.toString().padLeft(2, '0')} min';
      }
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')} hrs';
      }
      return '${minutes.toString().padLeft(2, '0')} mins';
    } catch (_) {
      return '--';
    }
  }

  String _assignedEmployeeLabel(VisitDetailModel detail) {
    final participants = detail.participants;
    if (participants.isEmpty) return detail.createdBy.fullName;
    final primary = participants.first.user.fullName;
    if (participants.length == 1) return primary;
    return '$primary +${participants.length - 1}';
  }

  VisitUserModel _assignedUser(VisitDetailModel detail) {
    if (detail.participants.isNotEmpty) {
      return detail.participants.first.user;
    }
    return detail.createdBy;
  }

  bool _isPlannedActivity(VisitActivityModel activity) {
    return activity.activityStatus.trim().toUpperCase() == 'PLANNED';
  }

  bool _isStartedActivity(VisitActivityModel activity) {
    final normalized = activity.activityStatus.trim().toUpperCase();
    return normalized == 'STARTED' || normalized == 'IN PROGRESS';
  }

  bool _isCompletedActivity(VisitActivityModel activity) {
    return activity.activityStatus.trim().toUpperCase() == 'COMPLETED';
  }

  bool _isPendingActivity(VisitActivityModel activity) {
    final normalized = activity.activityStatus.trim().toUpperCase();
    return normalized == 'PENDING';
  }

  _ActivityStatusSummary _activityStatusSummary(
    List<VisitActivityModel> activities,
  ) {
    var scheduledCount = 0;
    var completedCount = 0;
    var pendingCount = 0;

    for (final activity in activities) {
      if (_isPlannedActivity(activity) ) {
        scheduledCount++;
        continue;
      }
      if (_isCompletedActivity(activity)) {
        completedCount++;
        continue;
      }
      if (_isPendingActivity(activity)) {
        pendingCount++;
      }
    }

    return _ActivityStatusSummary(
      scheduledCount: scheduledCount,
      completedCount: completedCount,
      pendingCount: pendingCount,
      totalCount: activities.length,
    );
  }

  void _ensureActivityDetailsLoaded(VisitDetailModel detail, VisitState state) {
    final activityIds = detail.activities
        .where(
          (activity) =>
              _isStartedActivity(activity) || _isCompletedActivity(activity),
        )
        .map((activity) => activity.id)
        .where(
          (activityId) =>
              !state.visitActivityDetailsById.containsKey(activityId) &&
              !state.loadingVisitActivityDetailIds.contains(activityId),
        )
        .toList(growable: false);

    if (activityIds.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<VisitBloc>();
      for (final activityId in activityIds) {
        bloc.add(LoadVisitActivityDetails(activityId));
      }
    });
  }

  Future<void> _openStartActivityDialog(VisitActivityModel activity) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => BlocProvider.value(
            value: context.read<VisitBloc>(),
            child: VisitActivityStartDialog(activity: activity),
          ),
    );
  }

  Future<void> _openCompleteActivityDialog(VisitActivityModel activity) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => BlocProvider.value(
            value: context.read<VisitBloc>(),
            child: VisitActivityCompleteDialog(activity: activity),
          ),
    );
  }

  Future<void> _openActivityDetailsPage(
    VisitActivityModel activity,
    DateTime? scheduledDate,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: context.read<VisitBloc>(),
              child: VisitActivityDetailsPage(
                activity: activity,
                scheduledDate: scheduledDate,
              ),
            ),
      ),
    );
  }

  Future<void> _openCancelActivityDialog(VisitActivityModel activity) async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: Container(
                color: AppColors.background,
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ending Visit',
                              style: AppTextStyles.bodyMediumHeading(
                                dialogContext,
                              ).copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                size:
                                    AppTextStyles.heading4(
                                      dialogContext,
                                    ).fontSize,
                                color: AppColors.textWhite,
                              ),
                            ),
                          ),
                          AppSpacing.vLg,
                          Text(
                            'Ending the Visit',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading4(
                              dialogContext,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          AppSpacing.vSm,
                          Text(
                            'Ending this visit will mark it as pending, and you can complete it later.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(
                              dialogContext,
                            ).copyWith(color: AppColors.textSecondary),
                          ),
                          AppSpacing.vLg,
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      () => Navigator.of(dialogContext).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.successDark,
                                    foregroundColor: AppColors.textWhite,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.sm,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Resume Visit',
                                    style: AppTextStyles.bodyMediumHeading(
                                      dialogContext,
                                    ).copyWith(color: AppColors.textWhite),
                                  ),
                                ),
                              ),
                              AppSpacing.hMd,
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cancel activity API is pending',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    foregroundColor: AppColors.textWhite,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.md,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.sm,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'End Visit',
                                    style: AppTextStyles.bodyMediumHeading(
                                      dialogContext,
                                    ).copyWith(color: AppColors.textWhite),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _ActivityStatusSummary {
  final int scheduledCount;
  final int completedCount;
  final int pendingCount;
  final int totalCount;

  const _ActivityStatusSummary({
    required this.scheduledCount,
    required this.completedCount,
    required this.pendingCount,
    required this.totalCount,
  });
}

class _ActivityStatusSegmentData {
  final String label;
  final int count;
  final Color color;

  const _ActivityStatusSegmentData({
    required this.label,
    required this.count,
    required this.color,
  });
}
