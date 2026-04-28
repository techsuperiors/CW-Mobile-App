import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../../../core/utils/app_spacing.dart';
import '../../../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../../../core/widgets/api_error_state.dart';
import '../../../../../../../../../../core/widgets/common/app_card.dart';
import '../../../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/visit_model.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../widgets/activity_chip.dart';
import '../widgets/visit_activity_complete_dialog.dart';
import '../widgets/visit_activity_start_dialog.dart';

class VisitActivityDetailsPage extends StatefulWidget {
  final VisitActivityModel activity;
  final DateTime? scheduledDate;

  const VisitActivityDetailsPage({
    super.key,
    required this.activity,
    required this.scheduledDate,
  });

  @override
  State<VisitActivityDetailsPage> createState() =>
      _VisitActivityDetailsPageState();
}

class _VisitActivityDetailsPageState extends State<VisitActivityDetailsPage> {
  bool get _isPlannedStatus => _normalizedStatus == 'PLANNED';

  String get _normalizedStatus {
    final state = context.read<VisitBloc>().state;
    final detail = state.visitActivityDetailsById[widget.activity.id];
    final raw = detail?.activityStatus ?? widget.activity.activityStatus;
    return raw.trim().toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VisitBloc>().add(
        LoadVisitActivityDetails(widget.activity.id),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VisitBloc, VisitState>(
      listenWhen:
          (previous, current) =>
              previous.startActivitySuccessMessage !=
                  current.startActivitySuccessMessage ||
              previous.lastStartedActivityId != current.lastStartedActivityId ||
              previous.deleteActivitySuccessMessage !=
                  current.deleteActivitySuccessMessage ||
              previous.lastDeletedActivityId != current.lastDeletedActivityId,
      listener: (context, state) {
        if (state.lastStartedActivityId == widget.activity.id &&
            (state.startActivitySuccessMessage?.isNotEmpty ?? false)) {
          Navigator.of(context).pop();
          return;
        }

        if (state.lastDeletedActivityId == widget.activity.id &&
            (state.deleteActivitySuccessMessage?.isNotEmpty ?? false)) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          elevation: 0,
          forceMaterialTransparency: true,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          leadingWidth: 110,

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
          title: Text(
            'Activity Details',
            style: AppTextStyles.heading4(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            BlocBuilder<VisitBloc, VisitState>(
              builder: (context, state) {
                final isDeleting = state.deletingVisitActivityIds.contains(
                  widget.activity.id,
                );
                if (!_isPlannedStatus) {
                  return const SizedBox.shrink();
                }
                if (isDeleting) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: SizedBox(
                      width: AppTextStyles.bodyMedium(context).fontSize,
                      height: AppTextStyles.bodyMedium(context).fontSize,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                return PopupMenuButton<_ActivityDetailMenuAction>(
                  onSelected: (value) {
                    if (value == _ActivityDetailMenuAction.delete) {
                      context.read<VisitBloc>().add(
                        DeleteVisitActivityRequested(widget.activity.id),
                      );
                    }
                  },
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem<_ActivityDetailMenuAction>(
                          value: _ActivityDetailMenuAction.delete,
                          child: Text('Delete Activity'),
                        ),
                      ],
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 0,
          onTap: NavigationHelper.getBottomNavHandler(context),
        ),
        body: BlocBuilder<VisitBloc, VisitState>(
          builder: (context, state) {
            final activity = _currentActivity(state);
            final detail = state.visitActivityDetailsById[widget.activity.id];
            final detailError =
                state.visitActivityDetailErrorsById[widget.activity.id];
            final isLoading = state.loadingVisitActivityDetailIds.contains(
              widget.activity.id,
            );
            final isStarting = state.startingVisitActivityIds.contains(
              widget.activity.id,
            );
            final isCompleting = state.completingVisitActivityIds.contains(
              widget.activity.id,
            );

            if (isLoading && detail == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (detailError != null && detail == null) {
              return ApiErrorState(
                title: 'Unable to load activity details',
                rawMessage: detailError,
                onRetry:
                    () => context.read<VisitBloc>().add(
                      LoadVisitActivityDetails(
                        widget.activity.id,
                        forceRefresh: true,
                      ),
                    ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<VisitBloc>().add(
                  LoadVisitActivityDetails(
                    widget.activity.id,
                    forceRefresh: true,
                  ),
                );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(
                      context,
                      activity: activity,
                      detail: detail,
                      isStarting: isStarting,
                      isCompleting: isCompleting,
                    ),
                    AppSpacing.vMd,
                    _buildRouteSection(context, detail),
                    AppSpacing.vMd,
                    _buildAttachmentsSection(context, detail),
                    AppSpacing.vMd,
                    _buildNotesSection(context),
                    AppSpacing.vMd,
                    _buildCommentsSection(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  VisitActivityModel _currentActivity(VisitState state) {
    final detail = state.visitDetail;
    if (detail == null) return widget.activity;
    for (final activity in detail.activities) {
      if (activity.id == widget.activity.id) return activity;
    }
    return widget.activity;
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required VisitActivityModel activity,
    required VisitActivityDetailModel? detail,
    required bool isStarting,
    required bool isCompleting,
  }) {
    final title = _activityTypeLabel(activity.activityType);
    final isPlanned = _isStatusPlanned(detail, activity);
    final isPending = _isStatusPending(detail, activity);
    final isCompleted = _isStatusCompleted(detail, activity);
    final isStarted = _isStatusStarted(detail, activity);
    final customerName =
        detail?.customer?.customerName.trim().isNotEmpty == true
            ? detail!.customer!.customerName.trim()
            : activity.customer?.customerName.trim() ?? '';
    final addressLine = _addressLine(activity, detail);
    final scheduledTime = _scheduledTimeRange(activity, detail);

    return AppCard(
      borderRadius: AppSpacing.lg,
      elevation: 1,
      padding: AppSpacing.cardPadding,
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
                    color: isCompleted ? AppColors.primary : AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.hSm,
              if (isStarted) ...[
                const ActivityChip(
                  label: 'Ongoing',
                  textColor: AppColors.warning,
                  backgroundColor: AppColors.serviceOrangeBg,
                ),
                AppSpacing.hSm,
                // const ActivityChip(
                //   label: '28m :36s',
                //   textColor: AppColors.textWhite,
                //   backgroundColor: AppColors.primary,
                // ),
              ] else if (isPending) ...[
                const ActivityChip(
                  label: 'Pending',
                  textColor: AppColors.textWhite,
                  backgroundColor: AppColors.serviceOrange,
                ),
              ] else ...[
                ActivityChip(
                  label: isCompleted ? 'Completed' : 'Planned',
                  textColor: AppColors.textWhite,
                  backgroundColor:
                      isCompleted ? AppColors.successDark : AppColors.primary,
                ),
              ],
            ],
          ),
          AppSpacing.vMd,

          AppSpacing.vMd,
          _DetailRow(
            icon: Icons.person_rounded,
            iconColor: AppColors.serviceBlue,
            child: RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Client - '),
                  TextSpan(
                    text: customerName.isEmpty ? '--' : customerName,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (addressLine.isNotEmpty) ...[
            AppSpacing.vSm,
            _DetailRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.error,
              child: Text(
                addressLine,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          AppSpacing.vSm,
          _DetailRow(
            icon: Icons.flag_outlined,
            iconColor: AppColors.textPrimary,
            child: RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Priority - '),
                  TextSpan(
                    text: '--',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.vSm,
          _DetailRow(
            icon: Icons.access_time_outlined,
            iconColor: AppColors.primary,
            child: RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Date - '),
                  TextSpan(
                    text: _formattedDate(widget.scheduledDate),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.vSm,
          _DetailRow(
            icon: Icons.schedule_rounded,
            iconColor: AppColors.primary,
            child: RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Scheduled Time - '),
                  TextSpan(
                    text: scheduledTime,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.vLg,

          if (isStarted) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openCancelActivityDialog(activity),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                    ),
                    child: Text(
                      'Cancel Activity',
                      style: AppTextStyles.bodyMediumHeading(
                        context,
                      ).copyWith(color: AppColors.error),
                    ),
                  ),
                ),
                AppSpacing.hMd,
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        isCompleting ? null : () => _openCompleteActivityDialog(activity),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successDark,
                      disabledBackgroundColor: AppColors.backgroundDark,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                    ),
                    child:
                        isCompleting
                            ? SizedBox(
                              width: AppTextStyles.bodySmall(context).fontSize,
                              height: AppTextStyles.bodySmall(context).fontSize,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textWhite,
                              ),
                            )
                            : Text(
                              'Complete Activity',
                              style: AppTextStyles.bodyMediumHeading(
                                context,
                              ).copyWith(color: AppColors.textWhite),
                            ),
                  ),
                ),
              ],
            ),
          ],
          if (isPlanned) ...[
            AppSpacing.vLg,
            Center(
              child: SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed:
                      isStarting ? null : () => _openStartDialog(activity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.backgroundDark,
                    foregroundColor: AppColors.textWhite,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                  ),
                  child:
                      isStarting
                          ? SizedBox(
                            width: AppTextStyles.bodySmall(context).fontSize,
                            height: AppTextStyles.bodySmall(context).fontSize,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textWhite,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size:
                                    AppTextStyles.bodyMedium(context).fontSize,
                                color: AppColors.textWhite,
                              ),
                              AppSpacing.hXs,
                              Text(
                                'Start Activity',
                                style: AppTextStyles.bodyMediumHeading(
                                  context,
                                ).copyWith(color: AppColors.textWhite),
                              ),
                            ],
                          ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteSection(
    BuildContext context,
    VisitActivityDetailModel? detail,
  ) {
    final destination = _destinationPoint(detail);
    return AppCard(
      borderRadius: AppSpacing.lg,
      elevation: 1,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route',
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.vMd,
          if (destination == null)
            _buildPlaceholderBox(
              context,
              icon: Icons.map_outlined,
              title: 'Route unavailable',
              subtitle:
                  'Location coordinates are not available for this activity yet.',
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: SizedBox(
                height: 240,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: destination,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.collectivwork.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: destination,
                          width: AppSpacing.xxl,
                          height: AppSpacing.xxl,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.error,
                            size: AppSpacing.xxl,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(
    BuildContext context,
    VisitActivityDetailModel? detail,
  ) {
    final attachments = _attachments(detail);
    return AppCard(
      borderRadius: AppSpacing.lg,
      elevation: 1,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Attachments',
                  style: AppTextStyles.bodyMediumHeading(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '+ Attach file',
                style: AppTextStyles.bodyMedium(
                  context,
                ).copyWith(color: AppColors.primary),
              ),
            ],
          ),
          AppSpacing.vMd,
          if (attachments.isEmpty)
            _buildPlaceholderBox(
              context,
              icon: Icons.attach_file_rounded,
              title: 'No Attachments',
              subtitle: 'Files will appear here when the backend is available.',
            )
          else
            Column(
              children: attachments
                  .map(
                    (attachment) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AttachmentTile(attachment: attachment),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return AppCard(
      borderRadius: AppSpacing.lg,
      elevation: 1,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.vMd,
          _buildPlaceholderBox(
            context,
            icon: Icons.note_alt_outlined,
            title: 'Add Notes',
            subtitle:
                'Notes support will be connected once the API is available.',
          ),
          AppSpacing.vMd,
          TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: 'Add notes',
              filled: true,
              fillColor: AppColors.backgroundMedium,
              contentPadding: AppSpacing.inputPadding,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    const comments = [
      _MockComment(
        authorName: 'Robert William',
        authorInitials: 'RW',
        message:
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
        timestamp: 'June 04, 2024 at 12:56 PM',
        accentColor: AppColors.primary,
        primaryActionLabel: 'Edit',
        secondaryActionLabel: 'Delete',
        primaryActionIcon: Icons.edit_outlined,
        secondaryActionIcon: Icons.delete_outline_rounded,
      ),
      _MockComment(
        authorName: 'Maya Collins',
        authorInitials: 'MC',
        message:
            'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
        timestamp: 'June 05, 2024 at 10:30 AM',
        accentColor: AppColors.serviceOrange,
        primaryActionLabel: 'Reply',
        primaryActionIcon: Icons.edit_outlined,
      ),
    ];

    return AppCard(
      borderRadius: AppSpacing.lg,
      elevation: 1,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.vMd,
          TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              filled: true,
              fillColor: AppColors.background,
              contentPadding: AppSpacing.inputPadding,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          AppSpacing.vLg,
          ...comments.asMap().entries.map((entry) {
            final index = entry.key;
            final comment = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == comments.length - 1 ? 0 : AppSpacing.lg,
              ),
              child: _CommentTile(comment: comment),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBox(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: AppSpacing.xxl),
          AppSpacing.vSm,
          Text(
            title,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          AppSpacing.vXs,
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  List<_ActivityAttachment> _attachments(VisitActivityDetailModel? detail) {
    if (detail == null) return const [];
    final items = <_ActivityAttachment>[];
    final start = detail.activityCheckinSelfie?.trim() ?? '';
    final end = detail.activityCheckoutSelfie?.trim() ?? '';
    if (start.isNotEmpty) {
      items.add(_ActivityAttachment(label: 'Start visit image', url: start));
    }
    if (end.isNotEmpty) {
      items.add(_ActivityAttachment(label: 'Complete visit image', url: end));
    }
    return items;
  }

  LatLng? _destinationPoint(VisitActivityDetailModel? detail) {
    if (detail == null) return null;

    final customerAddress = detail.customer?.addresses.firstOrNull;
    final customerLat = double.tryParse(
      customerAddress?.latitude?.trim() ?? '',
    );
    final customerLng = double.tryParse(
      customerAddress?.longitude?.trim() ?? '',
    );
    if (customerLat != null && customerLng != null) {
      return LatLng(customerLat, customerLng);
    }

    if (detail.activityStartLat != null && detail.activityStartLng != null) {
      return LatLng(detail.activityStartLat!, detail.activityStartLng!);
    }
    return null;
  }

  String _activityTypeLabel(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return '--';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _addressLine(
    VisitActivityModel activity,
    VisitActivityDetailModel? detail,
  ) {
    final customerAddress =
        detail?.customer?.addresses.firstOrNull?.locationLabel.trim() ?? '';
    if (customerAddress.isNotEmpty) return customerAddress;
    final visitAddress = activity.address?.locationLabel.trim() ?? '';
    if (visitAddress.isNotEmpty) return visitAddress;
    return '';
  }

  String _formattedDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('dd MMMM , yyyy').format(date);
  }

  String _scheduledTimeRange(
    VisitActivityModel activity,
    VisitActivityDetailModel? detail,
  ) {
    final sourceTime = detail?.estimatedTime ?? activity.estimatedTime;
    final sourceDuration =
        detail?.estimatedDuration ?? activity.estimatedDuration;
    final start = _formatDisplayTime(sourceTime) ?? '--';
    final end = _scheduledExitTime(sourceTime, sourceDuration) ?? '--';
    return '$start - $end';
  }

  String? _formatDisplayTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = _parseTime(raw);
    if (parsed == null) return raw;
    return DateFormat('hh:mm a').format(parsed);
  }

  String? _scheduledExitTime(String? scheduledTime, int? scheduledDuration) {
    if (scheduledTime == null ||
        scheduledTime.trim().isEmpty ||
        scheduledDuration == null ||
        scheduledDuration <= 0) {
      return null;
    }

    final parsed = _parseTime(scheduledTime);
    if (parsed == null) return null;
    return DateFormat(
      'hh:mm a',
    ).format(parsed.add(Duration(minutes: scheduledDuration)));
  }

  DateTime? _parseTime(String raw) {
    final trimmed = raw.trim();
    final now = DateTime.now();
    for (final pattern in const ['hh:mm a', 'HH:mm:ss', 'HH:mm']) {
      try {
        final parsed = DateFormat(pattern).parseStrict(trimmed);
        return DateTime(
          now.year,
          now.month,
          now.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
        );
      } catch (_) {
        // Try next pattern
      }
    }
    return null;
  }

  Future<void> _openStartDialog(VisitActivityModel activity) async {
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
                            visualDensity: VisualDensity.compact,
                            splashRadius: AppSpacing.lg,
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.warning.withValues(alpha: 0.12),
                            ),
                            child: Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.warning,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.warning.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: AppSpacing.md,
                                      offset: const Offset(0, AppSpacing.xs),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  color: AppColors.textWhite,
                                  size: AppTextStyles.heading2(context).fontSize,
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.vLg,
                          Text(
                            'Ending the Visit',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading3(
                              dialogContext,
                            ).copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppSpacing.vSm,
                          Text(
                            'Ending this visit will mark it as pending, and you can complete it later.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(
                              dialogContext,
                            ).copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          AppSpacing.vLg,
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      () => Navigator.of(dialogContext).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
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

  bool _isStatusPlanned(
    VisitActivityDetailModel? detail,
    VisitActivityModel activity,
  ) {
    final raw = detail?.activityStatus ?? activity.activityStatus;
    return raw.trim().toUpperCase() == 'PLANNED';
  }

  bool _isStatusCompleted(
    VisitActivityDetailModel? detail,
    VisitActivityModel activity,
  ) {
    final raw = detail?.activityStatus ?? activity.activityStatus;
    return raw.trim().toUpperCase() == 'COMPLETED';
  }

  bool _isStatusPending(
    VisitActivityDetailModel? detail,
    VisitActivityModel activity,
  ) {
    final raw = detail?.activityStatus ?? activity.activityStatus;
    return raw.trim().toUpperCase() == 'PENDING';
  }

  bool _isStatusStarted(
    VisitActivityDetailModel? detail,
    VisitActivityModel activity,
  ) {
    final raw = detail?.activityStatus ?? activity.activityStatus;
    final normalized = raw.trim().toUpperCase();
    return normalized == 'STARTED' || normalized == 'IN PROGRESS';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: AppTextStyles.bodyMedium(context).fontSize,
        ),
        AppSpacing.hSm,
        Expanded(child: child),
      ],
    );
  }
}

class _ActivityAttachment {
  final String label;
  final String url;

  const _ActivityAttachment({required this.label, required this.url});
}

class _AttachmentTile extends StatelessWidget {
  final _ActivityAttachment attachment;

  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: () => _showPreview(context),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: SizedBox(
                  width: AppSpacing.section,
                  height: AppSpacing.section,
                  child: Image.network(
                    attachment.url,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          color: AppColors.serviceBlueBg,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.primary,
                            size: AppTextStyles.bodyMedium(context).fontSize,
                          ),
                        ),
                  ),
                ),
              ),
              AppSpacing.hSm,
              Expanded(
                child: Text(
                  attachment.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPreview(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => Dialog(
            insetPadding: const EdgeInsets.all(AppSpacing.lg),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: Container(
                color: AppColors.background,
                padding: AppSpacing.cardPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            attachment.label,
                            style: AppTextStyles.bodyMediumHeading(
                              dialogContext,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 420),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                        child: Image.network(
                          attachment.url,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: AppColors.backgroundMedium,
                                padding: AppSpacing.cardPadding,
                                alignment: Alignment.center,
                                child: Text(
                                  'Unable to load attachment preview.',
                                  style: AppTextStyles.bodyMedium(
                                    dialogContext,
                                  ).copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                        ),
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

class _CommentTile extends StatelessWidget {
  final _MockComment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.xxl,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: comment.accentColor,
          ),
          alignment: Alignment.center,
          child: Text(
            comment.authorInitials,
            style: AppTextStyles.bodyMediumHeading(
              context,
            ).copyWith(color: AppColors.textWhite),
          ),
        ),
        AppSpacing.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                textScaler: MediaQuery.textScalerOf(context),
                text: TextSpan(
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: comment.authorName,
                      style: AppTextStyles.bodyMediumHeading(
                        context,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                    const TextSpan(text: '  '),
                    TextSpan(text: comment.timestamp),
                  ],
                ),
              ),
              AppSpacing.vSm,
              Text(
                comment.message,
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              AppSpacing.vSm,
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  if (comment.primaryActionLabel != null)
                    _CommentAction(
                      icon: comment.primaryActionIcon ?? Icons.edit_outlined,
                      label: comment.primaryActionLabel!,
                    ),
                  if (comment.secondaryActionLabel != null)
                    _CommentAction(
                      icon:
                          comment.secondaryActionIcon ??
                          Icons.delete_outline_rounded,
                      label: comment.secondaryActionLabel!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CommentAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppTextStyles.bodySmall(context).fontSize,
              color: AppColors.textSecondary,
            ),
            AppSpacing.hXs,
            Text(
              label,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockComment {
  final String authorName;
  final String authorInitials;
  final String message;
  final String timestamp;
  final Color accentColor;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final IconData? primaryActionIcon;
  final IconData? secondaryActionIcon;

  const _MockComment({
    required this.authorName,
    required this.authorInitials,
    required this.message,
    required this.timestamp,
    required this.accentColor,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.primaryActionIcon,
    this.secondaryActionIcon,
  });
}

enum _ActivityDetailMenuAction { delete }
