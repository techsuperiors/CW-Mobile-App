import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../domain/models/document_folder_model.dart';

/// Card widget for displaying document folder information
class DocumentFolderCard extends StatelessWidget {
  final DocumentFolderModel folder;
  final bool isSelected;
  final VoidCallback? onTap;

  const DocumentFolderCard({
    super.key,
    required this.folder,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(screenWidth * 0.042), // ~4.2% of screen width
        child: Row(
          children: [
            // Folder Icon
            Container(
              padding: EdgeInsets.all(screenWidth * 0.027), // ~2.7% of screen width
              decoration: BoxDecoration(
                color: folder.folderType == 'shared'
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder,
                color: folder.folderType == 'shared'
                    ? Theme.of(context).colorScheme.primary
                    : Colors.amber[700],
                size: screenWidth * 0.064, // ~6.4% of screen width
              ),
            ),
            SizedBox(width: screenWidth * 0.032), // ~3.2% of screen width
            // Folder Name and File Count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.005), // 0.5% of screen height
                  Text(
                    'File Count: ${folder.fileCount.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
