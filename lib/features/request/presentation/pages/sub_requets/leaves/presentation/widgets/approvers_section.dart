import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../bloc/approvers/approvers_bloc.dart';
import '../../../../../bloc/approvers/approvers_event.dart';
import '../../../../../bloc/approvers/approvers_state.dart';

/// Approvers section widget showing approval levels and approvers
class ApproversSection extends StatefulWidget {
  final ScrollController? scrollController;
  final String endpoint;
  final Map<String, dynamic> payload;

  const ApproversSection({
    super.key,
    this.scrollController,
    required this.endpoint,
    required this.payload,
  });

  @override
  State<ApproversSection> createState() => _ApproversSectionState();
}

class _ApproversSectionState extends State<ApproversSection> {
  @override
  void initState() {
    super.initState();
    context.read<ApproversBloc>().add(
      FetchApprovers(endpoint: widget.endpoint, payload: widget.payload),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF2196F3); // Blue
      case 'approved':
        return const Color(0xFF12B76A); // Green
      case 'rejected':
        return const Color(0xFFE53935); // Red
      case 'withdrawn':
        return const Color(0xFFF79009);
      default:
        return AppColors.warning;
    }
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with close button
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.042),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.096,
                    height: screenWidth * 0.096,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: screenWidth * 0.053,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.021),
                  Text(
                    'Approvers',
                    style: AppTextStyles.heading4(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.042),
            child: Container(
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: screenHeight * 0.01),
                  BlocBuilder<ApproversBloc, ApproversState>(
                    builder: (context, state) {
                      if (state is ApproversLoading) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.05,
                            ),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      } else if (state is ApproversError) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.05,
                            ),
                            child: Text(
                              state.message,
                              style: AppTextStyles.bodyMedium(
                                context,
                              ).copyWith(color: AppColors.error),
                            ),
                          ),
                        );
                      } else if (state is ApproversLoaded) {
                        if (state.approvers.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.05,
                              ),
                              child: Text(
                                'No approvers found.',
                                style: AppTextStyles.bodyMedium(
                                  context,
                                ).copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              state.approvers.map((level) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: screenHeight * 0.025,
                                  ),
                                  child: _buildApprovalLevel(
                                    context,
                                    level.level.toLowerCase().contains('super')
                                        ? level.level
                                        : 'Level ${level.level}',
                                    level.allApproversRequired == true
                                        ? '(All Approvers Must Approve)'
                                        : '(Anyone can approve)',
                                    level.users.map((u) {
                                      return _ApproverInfo(
                                        name: '${u.firstName} ${u.lastName}',
                                        status: u.approvalStatus,
                                        statusColor: _getStatusColor(
                                          u.approvalStatus,
                                        ),
                                        hasAvatar:
                                            u.imageUrl != null ||
                                            u.profileColor != null,
                                        imageUrl: u.imageUrl,
                                        initials:
                                            u.firstName.isNotEmpty
                                                ? u.firstName[0]
                                                : null,
                                        customColor:
                                            u.profileColor != null
                                                ? _parseColor(u.profileColor!)
                                                : null,
                                      );
                                    }).toList(),
                                    screenWidth,
                                    screenHeight,
                                  ),
                                );
                              }).toList(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalLevel(
    BuildContext context,
    String levelTitle,
    String? subtitle,
    List<_ApproverInfo> approvers,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              levelTitle,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(width: screenWidth * 0.016),
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: screenHeight * 0.015),
        ...approvers.map(
          (approver) => Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.012),
            child: _buildApproverRow(
              context,
              approver,
              screenWidth,
              screenHeight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApproverRow(
    BuildContext context,
    _ApproverInfo approver,
    double screenWidth,
    double screenHeight,
  ) {
    Color avatarColor;
    Color textColor;
    if (approver.customColor != null) {
      avatarColor = approver.customColor!;
      textColor = Colors.white;
    } else if (approver.hasAvatar) {
      avatarColor = AppColors.primary;
      textColor = Colors.white;
    } else {
      avatarColor = const Color(0xFFE3F2FD); // Light blue
      textColor = AppColors.textPrimary;
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.032),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: screenWidth * 0.032,
            backgroundColor: avatarColor,
            backgroundImage:
                approver.imageUrl != null && approver.imageUrl!.isNotEmpty
                    ? NetworkImage(approver.imageUrl!)
                    : null,
            child:
                approver.imageUrl != null && approver.imageUrl!.isNotEmpty
                    ? null
                    : Text(
                      approver.initials ??
                          approver.name
                              .split(' ')
                              .map((n) => n.isNotEmpty ? n[0] : '')
                              .take(2)
                              .join(),
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
          SizedBox(width: screenWidth * 0.021),
          // Name
          Expanded(
            child: Text(
              approver.name,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.027,
              vertical: screenHeight * 0.006,
            ),
            decoration: BoxDecoration(
              color: approver.statusColor,
              borderRadius: BorderRadius.circular(6),
              // border: Border.all(color: approver.statusColor, width: 1),
            ),
            child: Text(
              approver.status,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontWeight: FontWeight.w500,
                color:Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproverInfo {
  final String name;
  final String status;
  final Color statusColor;
  final bool hasAvatar;
  final String? imageUrl;
  final String? initials;
  final Color? customColor;

  _ApproverInfo({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.hasAvatar,
    this.imageUrl,
    this.initials,
    this.customColor,
  });
}
