import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/policy_model.dart';
import '../pages/policy_detail_page.dart';

/// Card widget for displaying policy information
class PolicyCard extends StatelessWidget {
  final PolicyModel policy;
  final Future<void> Function()? onPolicyUpdated;

  const PolicyCard({super.key, required this.policy, this.onPolicyUpdated});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
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
              color: Colors.black.withValues(alpha: 0.03),
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
              _assignedByDisplayValue(),
              policy.assignedByAvatar,
              alwaysShowAvatar: true,
              avatarFallbackName: policy.assignedBy,
              avatarFallbackColor: _parseColor(policy.assignedByProfileColor),
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
            if (policy.updatedOn != null &&
                policy.updatedOn!.trim().isNotEmpty) ...[
              Divider(height: screenHeight * 0.03, color: AppColors.border),
              _buildDetailRow(context, 'Updated On', policy.updatedOn!, null),
            ],
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
                Container(
                  decoration: BoxDecoration(
                    color: _statusColor(policy),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight*0.0008,
                    horizontal: screenWidth*0.02,
                  ),
                  child: Flexible(
                    child: Text(
                      policy.status,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
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
    String? avatarPath, {
    bool alwaysShowAvatar = false,
    String? avatarFallbackName,
    Color? avatarFallbackColor,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension =
        screenWidth < screenHeight ? screenWidth : screenHeight;
    final trimmedAvatarPath = avatarPath?.trim();
    final shouldShowAvatar =
        alwaysShowAvatar ||
        (trimmedAvatarPath != null && trimmedAvatarPath.isNotEmpty);
    final displayValue =
        label == 'Assigned Date' || label == 'Updated On'
            ? _formatAssignedDate(value)
            : value;

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
              if (shouldShowAvatar) ...[
                SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                _buildAvatar(
                  context: context,
                  name: avatarFallbackName ?? value,
                  avatarPath: trimmedAvatarPath,
                  radius: smallerDimension * 0.033,
                  fallbackColor: avatarFallbackColor,
                ),
              ],
              SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
              Flexible(
                child: Text(
                  displayValue,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAssignedDate(String value) {
    if (value.trim().isEmpty || value == 'N/A') {
      return value;
    }

    final parsedDate = DateFormat('dd/MM/yyyy').tryParse(value);
    if (parsedDate == null) {
      return value;
    }

    return DateFormat('dd-MMM-yyyy').format(parsedDate);
  }

  String _assignedByDisplayValue() {
    final employeeId = policy.assignedByEmployeeId?.trim();
    if (employeeId == null || employeeId.isEmpty) {
      return policy.assignedBy;
    }
    return '${policy.assignedBy} ($employeeId)';
  }

  Color _statusColor(PolicyModel policy) {
    final normalizedStatus = policy.status.trim().toLowerCase();
    if (policy.isAcknowledged) {
      return AppColors.success;
    }
    if (normalizedStatus == 'viewed') {
      return AppColors.info;
    }
    return AppColors.warning;
  }

  Widget _buildAvatar({
    required BuildContext context,
    required String name,
    required String? avatarPath,
    required double radius,
    Color? fallbackColor,
  }) {
    final avatarSize = radius * 2;
    final trimmedAvatarPath = avatarPath?.trim();

    if (trimmedAvatarPath != null && trimmedAvatarPath.startsWith('http')) {
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: trimmedAvatarPath,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorWidget:
                (_, __, ___) => _buildAvatarFallback(
                  context,
                  name,
                  radius,
                  fallbackColor: fallbackColor,
                ),
          ),
        ),
      );
    }

    if (trimmedAvatarPath != null && trimmedAvatarPath.isNotEmpty) {
      return SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: ClipOval(
          child: Image.asset(
            trimmedAvatarPath,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => _buildAvatarFallback(
                  context,
                  name,
                  radius,
                  fallbackColor: fallbackColor,
                ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackColor ?? AppColors.border,
      child: _buildAvatarFallback(
        context,
        name,
        radius,
        fallbackColor: fallbackColor,
      ),
    );
  }

  Widget _buildAvatarFallback(
    BuildContext context,
    String name,
    double radius,
    {
    Color? fallbackColor,
  }) {
    final trimmedName = name.trim();
    final parts = trimmedName.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final list = parts.toList();
    final initials =
        list.isEmpty
            ? ''
            : list.length == 1
            ? list.first.substring(0, 1).toUpperCase()
            : '${list.first.substring(0, 1)}${list.last.substring(0, 1)}'
                .toUpperCase();

    if (initials.isEmpty) {
      return Icon(Icons.person, size: radius, color: Colors.white);
    }

    return Center(
      child: Text(
        initials,
        style: AppTextStyles.labelSmall(
          context,
        ).copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '');
    if (normalized.length != 6 && normalized.length != 8) return null;
    final value = int.tryParse(
      normalized.length == 6 ? 'FF$normalized' : normalized,
      radix: 16,
    );
    if (value == null) return null;
    return Color(value);
  }
}
