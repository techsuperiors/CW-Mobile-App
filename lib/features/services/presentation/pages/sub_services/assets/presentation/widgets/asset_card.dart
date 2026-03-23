import 'package:flutter/material.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/models/asset_model.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';

/// Card widget for displaying assigned asset information
class AssetCard extends StatelessWidget {
  final AssetEntity asset;

  const AssetCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
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
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asset Icon
              Container(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width * 0.027,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAssetIcon(asset.subCategoryName),
                  color: Theme.of(context).colorScheme.primary,
                  size: MediaQuery.of(context).size.width * 0.064,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.032),
              // Asset Name + Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.assetName,
                      style: AppTextStyles.heading4(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          asset.allocationStatus,
                        ).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        asset.allocationStatus,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: _getStatusColor(asset.allocationStatus),
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          // Details Section
          if (asset.assignedBy != null)
            _buildDetailRow(context, 'Assigned By', asset.assignedBy!.fullName),
          SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
          _buildDetailRow(context, 'Asset ID', asset.assetId),
          SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
          _buildDetailRow(context, 'Category', asset.categoryName),
          SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
          _buildDetailRow(context, 'Condition', asset.condition),
          SizedBox(height: MediaQuery.of(context).size.height * 0.0125),
          _buildDetailRow(context, 'Type', asset.assetType),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label column
        SizedBox(
          width: screenWidth * 0.267,
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.042),
        // Value column
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.green;
      case 'returned':
        return Colors.orange;
      case 'damaged':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAssetIcon(String subCategory) {
    switch (subCategory.toLowerCase()) {
      case 'laptop':
        return Icons.laptop;
      case 'headphone':
        return Icons.headphones;
      case 'monitor':
        return Icons.monitor;
      case 'mouse':
        return Icons.mouse;
      case 'keyboard':
        return Icons.keyboard;
      case 'mobile':
      case 'phone':
        return Icons.phone_android;
      default:
        return Icons.devices;
    }
  }
}

