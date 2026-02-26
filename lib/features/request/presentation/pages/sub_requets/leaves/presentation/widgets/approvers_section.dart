import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';

/// Approvers section widget showing approval levels and approvers
class ApproversSection extends StatelessWidget {
  final ScrollController? scrollController;
  
  const ApproversSection({super.key, this.scrollController});

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
                icon: Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.042),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
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
                  // Description
                  Text(
                    'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
            // Level 1
            _buildApprovalLevel(
              context,
              'Level 1',
              '(All Approvers Must Approve)',
              [
                _ApproverInfo(
                  name: 'Priya Rawat',
                  status: 'Pending',
                  statusColor: AppColors.warning,
                  hasAvatar: true,
                  initials: 'PR',
                ),
                _ApproverInfo(
                  name: 'Riya Sharma',
                  status: 'Approved',
                  statusColor: AppColors.success,
                  hasAvatar: true,
                  initials: 'RS',
                ),
              ],
              screenWidth,
              screenHeight,
            ),
            SizedBox(height: screenHeight * 0.025),
            // Level 2
            _buildApprovalLevel(
              context,
              'Level 2',
              null,
              [
                _ApproverInfo(
                  name: 'Support User',
                  status: 'Pending',
                  statusColor: AppColors.warning,
                  hasAvatar: false,
                  initials: 'PR',
                ),
              ],
              screenWidth,
              screenHeight,
            ),
            SizedBox(height: screenHeight * 0.025),
            // Level 3
            _buildApprovalLevel(
              context,
              'Level 3',
              '(Anyone can approve)',
              [
                _ApproverInfo(
                  name: 'Kapil Rawat',
                  status: 'Pending',
                  statusColor: AppColors.warning,
                  hasAvatar: false,
                  initials: 'KR',
                ),
                _ApproverInfo(
                  name: 'Aman Sharma',
                  status: 'Approved',
                  statusColor: AppColors.success,
                  hasAvatar: false,
                  initials: 'AS',
                ),
              ],
              screenWidth,
              screenHeight,
            ),
            SizedBox(height: screenHeight * 0.025),
            // Super Approver
            _buildApprovalLevel(
              context,
              'Super Approver',
              '(Can approve on behalf of all levels)',
              [
                _ApproverInfo(
                  name: 'Kapil Rawat',
                  status: 'Pending',
                  statusColor: AppColors.warning,
                  hasAvatar: false,
                  initials: 'KR',
                ),
                _ApproverInfo(
                  name: 'Aman Sharma',
                  status: 'Approved',
                  statusColor: AppColors.success,
                  hasAvatar: false,
                  initials: 'AS',
                ),
              ],
              screenWidth,
              screenHeight,
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
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: screenHeight * 0.015),
        ...approvers.map((approver) => Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.012),
              child: _buildApproverRow(
                context,
                approver,
                screenWidth,
                screenHeight,
              ),
            )),
      ],
    );
  }

  Widget _buildApproverRow(
    BuildContext context,
    _ApproverInfo approver,
    double screenWidth,
    double screenHeight,
  ) {
    // Determine avatar color based on name (matching design)
    Color avatarColor;
    Color textColor;
    if (approver.hasAvatar) {
      // Different colors for different approvers
      if (approver.name.contains('Priya')) {
        avatarColor = const Color(0xFF2196F3); // Blue
        textColor = Colors.white;
      } else if (approver.name.contains('Riya')) {
        avatarColor = const Color(0xFF9C27B0); // Purple
        textColor = Colors.white;
      } else {
        avatarColor = AppColors.primary;
        textColor = Colors.white;
      }
    } else {
      avatarColor = const Color(0xFFE3F2FD); // Light blue
      textColor = AppColors.textPrimary;
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.032),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: screenWidth * 0.032,
            backgroundColor: avatarColor,
            child: Text(
              approver.initials ?? approver.name.split(' ').map((n) => n[0]).take(2).join(),
              style: AppTextStyles.bodySmall(context).copyWith(
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
              color: approver.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: approver.statusColor,
                width: 1,
              ),
            ),
            child: Text(
              approver.status,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontWeight: FontWeight.w500,
                color: approver.statusColor,
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
  final String? initials;

  _ApproverInfo({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.hasAvatar,
    this.initials,
  });
}
