import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/policy_model.dart';
import '../pages/policy_detail_page.dart';

/// Card widget for displaying policy information
class PolicyCard extends StatelessWidget {
  final PolicyModel policy;
  final Future<void> Function()? onPolicyUpdated;

  const PolicyCard({
    super.key,
    required this.policy,
    this.onPolicyUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: () {
        // Navigate to policy detail page when tapped
        Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PolicyDetailPage(policy: policy),
          ),
        ).then((shouldRefresh) async {
          if (shouldRefresh == true) {
            await onPolicyUpdated?.call();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: EdgeInsets.all(
          MediaQuery.of(context).size.width * 0.042,
        ), // ~4.2% of screen width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Policy Name and Kebab Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    policy.name,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.02), // 2% of screen height
            // Assigned By
            _buildDetailRow(
              context,
              'Assigned By',
              policy.assignedBy,
              policy.assignedByAvatar,
            ),
            // SizedBox(height: screenHeight * 0.015), // 1.5% of screen height
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            // Assigned Date
            _buildDetailRow(
              context,
              'Assigned Date',
              policy.assignedDate,
              null,
            ),
            Divider(height: screenHeight * 0.03, color: AppColors.border),
            // Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ',
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                Flexible(
                  child: Text(
                    policy.status,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color:
                          policy.isAcknowledged
                              ? AppColors.success
                              : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    String? avatarPath,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: screenWidth * 0.267, // ~26.7% of screen width
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042), // ~4.2% of screen width
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (avatarPath != null) ...[
                SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                CircleAvatar(
                  radius: smallerDimension * 0.033,
                  // ~3.3% of smaller dimension
                  backgroundImage:
                      avatarPath.startsWith('http')
                          ? NetworkImage(avatarPath)
                          : AssetImage(avatarPath) as ImageProvider,
                ),
              ],
              SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
              Text(
                value,
                style: AppTextStyles.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
