import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../data/models/expense_detail_model.dart';

class ApprovalLevelTile extends StatelessWidget {
  final ExpenseApprovalDetail approval;
  final int index;
  final int totalCount;
  final bool isExpanded;
  final VoidCallback onToggle;

  const ApprovalLevelTile({
    required this.approval,
    required this.index,
    required this.totalCount,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const timelineDotSize = 44.0;
    const timelineLineWidth = 1.5;
    const timelineRailWidth = 52.0;
    const connectorWidth = 24.0;
    const connectorSegmentHeight = 28.0;
    final connectorColor = AppColors.border.withValues(alpha: 0.9);
    final circleCenterOffset = connectorSegmentHeight + (timelineDotSize / 2);
    final interItemSpacing = screenHeight * 0.02;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: timelineRailWidth,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.topCenter,
              children: [
                if (index != 0)
                  Positioned(
                    top: 0,
                    left: (timelineRailWidth - timelineLineWidth) / 2,
                    child: Container(
                      width: timelineLineWidth,
                      height: circleCenterOffset,
                      color: connectorColor,
                    ),
                  ),
                if (index != totalCount - 1)
                  Positioned(
                    top: circleCenterOffset,
                    left: (timelineRailWidth - timelineLineWidth) / 2,
                    bottom: 0,
                    child: Container(
                      width: timelineLineWidth,
                      color: connectorColor,
                    ),
                  ),
                Positioned(
                  top: connectorSegmentHeight,
                  left: (timelineRailWidth - timelineDotSize) / 2,
                  child: Container(
                    width: timelineDotSize,
                    height: timelineDotSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: connectorColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: connectorWidth,
            child: Column(
              children: [
                SizedBox(height: circleCenterOffset),
                Container(
                  width: connectorWidth,
                  height: timelineLineWidth,
                  color: connectorColor,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: connectorSegmentHeight),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: connectorColor),
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: onToggle,
                          borderRadius: BorderRadius.circular(14),
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
                                    ).copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                StatusChip(status: approval.approvalStatus),
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
                                      Avatar(user: approval.assignee, size: 24),
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
                                      (approval.remarks?.trim().isNotEmpty ??
                                              false)
                                          ? approval.remarks!.trim()
                                          : '—',
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: interItemSpacing),
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

class Avatar extends StatelessWidget {
  final ExpenseRequester user;
  final double size;

  const Avatar({required this.user, required this.size});

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

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.approvalSheetAccept; // 0xFF12B76A
      case 'rejected':
        return AppColors.approvalSheetReject; // 0xFFF04438
      case 'withdrawn':
        return AppColors.approvalSheetWithdrawn; // 0xFFF79009
      case 'pending':
        return AppColors.approvalSheetPending; //
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
