import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/document_file_model.dart';

/// Card widget for displaying document file information
class DocumentFileCard extends StatelessWidget {
  final DocumentFileModel file;
  final VoidCallback? onDownload;
  final VoidCallback? onTap;

  const DocumentFileCard({
    super.key,
    required this.file,
    this.onDownload,
    this.onTap,
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
                  SizedBox(height: screenHeight * 0.005), // 0.5% of screen height
                  Row(
                    children: [
                      Text(
                        file.fileSize,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                      Text(
                        '•',
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.021), // ~2.1% of screen width
                      Text(
                        file.date,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Three dots menu
            IconButton(
              icon: Icon(
                Icons.more_vert,
                size: screenWidth * 0.053, // ~5.3% of screen width
                color: AppColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _showDownloadMenu(context);
              },
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
        iconData = Icons.insert_drive_file;
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.027), // ~2.7% of screen width
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: screenWidth * 0.064, // ~6.4% of screen width
      ),
    );
  }

  void _showDownloadMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.02,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.download,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Download',
                style: AppTextStyles.bodyLarge(context),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onDownload != null) {
                  onDownload!();
                } else {
                  // Default download action
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Downloading ${file.name}...'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Share',
                style: AppTextStyles.bodyLarge(context),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sharing ${file.name}...'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              title: Text(
                'Delete',
                style: AppTextStyles.bodyLarge(context).copyWith(
                  color: AppColors.error,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleting ${file.name}...'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
