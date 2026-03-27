import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/document_file_model.dart';

/// Card widget for displaying document file information
class DocumentFileCard extends StatelessWidget {
  final DocumentFileModel file;
  final VoidCallback? onDownload;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const DocumentFileCard({
    super.key,
    required this.file,
    this.onDownload,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.042, // ~4.2% of screen width
          vertical: screenHeight * 0.015, // 1.5% of screen height
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.borderLight),
          color: AppColors.background
        ),
        child: Row(
          children: [
            // File Icon based on file type
            _buildFileIcon(context, screenWidth),
            SizedBox(width: screenWidth * 0.032), // ~3.2% of screen width
            // File Name and Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  // 0.5% of screen height
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          file.fileSize,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          file.date,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.more_vert,
                size: screenWidth * 0.053,
                color: AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onMoreTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(BuildContext context, double screenWidth) {
    Color iconColor;
    IconData iconData;

    switch (file.fileType.toLowerCase()) {
      case 'pdf':
        iconColor = Colors.red;
        iconData = Icons.picture_as_pdf;
        break;
      case 'doc':
      case 'docx':
        iconColor = Colors.blue;
        iconData = Icons.description;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconColor = Colors.green;
        iconData = Icons.image;
        break;
      default:
        iconColor = AppColors.textSecondary;
        iconData = Icons.web_rounded;
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.027), // ~2.7% of screen width
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: screenWidth * 0.064, // ~6.4% of screen width
      ),
    );
  }

}
