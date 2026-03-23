import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/asset_request_entity.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';

/// Card widget displaying a single asset request
class AssetRequestCard extends StatelessWidget {
  final AssetRequestEntity request;

  const AssetRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(sw * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category + Status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(sw * 0.027),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  getIcon(request.subCategoryName),
                  width: sw * 0.064,
                  height: sw * 0.064,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: sw * 0.032),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   request.categoryName.isNotEmpty
                    //       ? request.categoryName
                    //       : 'Asset Request',
                    //   style: AppTextStyles.heading4(context).copyWith(
                    //     fontWeight: FontWeight.w700,
                    //     color: AppColors.textPrimary,
                    //   ),
                    // ),
                    if (request.subCategoryName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        request.subCategoryName,
                        style: AppTextStyles.heading4(context).copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Status badge
                    Row(
                      children: [
                        _StatusBadge(label: request.approvalStatus),
                        const SizedBox(width: 6),
                        _StatusBadge(
                          label: request.requestType,
                          color: AppColors.primary.withOpacity(0.15),
                          textColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: sh * 0.018),
          // Details
          _buildDetailRow(context, 'Reason', request.reason),
          Divider(height: sh * 0.02, color: AppColors.border),

          _buildDetailRow(
            context,
            'Requested On',
            DateFormat('dd MMM yyyy').format(request.createdAt),
          ),
          if (request.requestAssignee != null) ...[
            Divider(height: sh * 0.02, color: AppColors.border),

            _buildDetailRow(
              context,
              'Assignee',
              request.requestAssignee!.fullName,
            ),
          ],
          if (request.assetAssignedTo != null) ...[
            Divider(height: sh * 0.02, color: AppColors.border),
            _buildDetailRow(
              context,
              'Assigned To',
              request.assetAssignedTo!.fullName,
            ),
          ],
          if (request.documents.isNotEmpty) ...[
            Divider(height: sh * 0.02, color: AppColors.border),
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${request.documents.length} document${request.documents.length > 1 ? 's' : ''} attached',
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  String getIcon(String subCategory) {
    if (subCategory.toLowerCase().contains('laptop')) {
      return AppAssets.laptopIcon;
    } else if (subCategory.toLowerCase().contains('headphone')) {
      return AppAssets.headphonesIcon;
    }
    return AppAssets.laptopIcon; // fallback
  }
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final sw = MediaQuery.of(context).size.width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: sw * 0.28,
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),

          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const _StatusBadge({required this.label, this.color, this.textColor});

  Color _resolveColor() {
    switch (label.toLowerCase()) {
      case 'pending':
        return Colors.orange.withOpacity(0.15);
      case 'approved':
        return Colors.green.withOpacity(0.15);
      case 'rejected':
        return Colors.red.withOpacity(0.15);
      default:
        return Colors.grey.withOpacity(0.15);
    }
  }

  Color _resolveTextColor() {
    switch (label.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'approved':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? _resolveColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall(context).copyWith(
          color: textColor ?? _resolveTextColor(),
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }
}
