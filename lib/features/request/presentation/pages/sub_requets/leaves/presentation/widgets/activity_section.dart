import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';

/// Activity section widget showing activity log
class ActivitySection extends StatelessWidget {
  final ScrollController? scrollController;
  
  const ActivitySection({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dateFormat = DateFormat('dd MMM yyyy.hh:mm a');

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
                      Icons.bolt_outlined,
                      size: screenWidth * 0.053,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.021),
                  Text(
                    'Activity',
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
        // Content - scrollable if exceeds max height
        Flexible(
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
                    'Loren ipsum is simply dummy text of the printing and typesetting industry.',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  // Activity items
                  _buildActivityItem(
                    context,
                    Icons.remove, // Horizontal line for withdrawn
                    const Color(0xFFE53935), // Red
                    'Leave request of 2 days has been withdrawn by Kapil Rawat',
                    DateTime(2025, 10, 30, 9, 51),
                    dateFormat,
                    screenWidth,
                    screenHeight,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildActivityItem(
                    context,
                    Icons.check,
                    const Color(0xFF4CAF50), // Green
                    '2 days has been approved by Priya Sharma',
                    DateTime(2025, 11, 8, 18, 32),
                    dateFormat,
                    screenWidth,
                    screenHeight,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildActivityItem(
                    context,
                    Icons.close,
                    const Color(0xFFE53935), // Red
                    '1 days has been rejected by Riya Rawat',
                    DateTime(2025, 11, 6, 18, 32),
                    dateFormat,
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

  Widget _buildActivityItem(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String description,
    DateTime dateTime,
    DateFormat dateFormat,
    double screenWidth,
    double screenHeight,
  ) {
    // Extract name from description (text after "by ")
    final nameMatch = RegExp(r'by\s+([A-Za-z\s]+)').firstMatch(description);
    String? personName;
    if (nameMatch != null) {
      personName = nameMatch.group(1)?.trim();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon with border
        Container(
          width: screenWidth * 0.096,
          height: screenWidth * 0.096,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: screenWidth * 0.042,
          ),
        ),
        SizedBox(width: screenWidth * 0.032),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDescriptionWithHighlightedName(
                context,
                description,
                personName,
              ),
              SizedBox(height: screenHeight * 0.006),
              Text(
                dateFormat.format(dateTime),
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionWithHighlightedName(
    BuildContext context,
    String description,
    String? name,
  ) {
    if (name == null) {
      return Text(
        description,
        style: AppTextStyles.bodyMedium(context).copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      );
    }

    final parts = description.split(name);
    if (parts.length < 2) {
      return Text(
        description,
        style: AppTextStyles.bodyMedium(context).copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium(context).copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: name,
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
          TextSpan(text: parts[1]),
        ],
      ),
    );
  }
}
