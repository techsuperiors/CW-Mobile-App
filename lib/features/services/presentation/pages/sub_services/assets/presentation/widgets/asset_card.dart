import 'package:flutter/material.dart';
import '../../domain/models/asset_model.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';

/// Card widget for displaying assigned asset information
class AssetCard extends StatelessWidget {
  final AssetModel asset;

  const AssetCard({
    super.key,
    required this.asset,
  });

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
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.042), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Asset Icon
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.027), // ~2.7% of screen width
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAssetIcon(asset.assetType),
                  color: Theme.of(context).colorScheme.primary,
                  size: MediaQuery.of(context).size.width * 0.064, // ~6.4% of screen width
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.032), // ~3.2% of screen width
              // Asset Name
              Expanded(
                child: Text(
                  asset.name,
                  style: AppTextStyles.heading4(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02), // 2% of screen height
          // Details Section
          _buildDetailRow(context, 'Employee Name', asset.employeeName, asset.employeeAvatar),
          SizedBox(height: MediaQuery.of(context).size.height * 0.0125), // 1.25% of screen height
          _buildDetailRow(context, 'Asset ID', asset.assetId, null),
          SizedBox(height: MediaQuery.of(context).size.height * 0.0125), // 1.25% of screen height
          _buildDetailRow(context, 'Department', asset.department, null),
          SizedBox(height: MediaQuery.of(context).size.height * 0.0125), // 1.25% of screen height
          _buildDetailRow(context, 'Office Location', asset.officeLocation, null),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, String? avatarPath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label column
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
        // Value column with optional avatar
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (avatarPath != null) ...[
                SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                CircleAvatar(
                  radius: smallerDimension * 0.033, // ~3.3% of smaller dimension
                  backgroundImage: AssetImage(avatarPath),
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

  IconData _getAssetIcon(String assetType) {
    switch (assetType.toLowerCase()) {
      case 'laptop':
        return Icons.laptop;
      case 'headphone':
        return Icons.headphones;
      default:
        return Icons.devices;
    }
  }
}

