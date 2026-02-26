import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/common/app_section_header.dart';
import '../../../request/presentation/pages/sub_requets/leaves/presentation/pages/apply_leave_page.dart';
import '../../../request/presentation/pages/sub_requets/wfh/presentation/pages/apply_wfh_page.dart';
import '../../../request/presentation/pages/sub_requets/regularize/presentation/pages/apply_regularize_page.dart';

/// Quick links widget
class QuickLinks extends StatelessWidget {
  const QuickLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final quickLinks = [
      {
        'icon': Icons.schedule_outlined,
        'label': AppStrings.applyLeaveRequest,
        'color': AppColors.error,
        'backgroundColor': AppColors.attendanceLightRedBg,
      },
      {
        'icon': Icons.business_center,
        'label': AppStrings.workFromHomeRequest,
        'color': AppColors.primary,
        'backgroundColor': AppColors.attendanceLightBlueBg,
      },
      {
        'icon': Icons.edit,
        'label': AppStrings.raiseRegularizeRequest,
        'color': AppColors.success,
        'backgroundColor': AppColors.attendanceLightGreenBg,
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.042), // ~4.2% of screen width
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: AppStrings.quickLinks),
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.25, // 25% of screen width
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickLinks.length,
              separatorBuilder: (context, index) => SizedBox(
                width: MediaQuery.of(context).size.width * 0.025, // 2.5% of screen width
              ),
              itemBuilder: (context, index) {
                final link = quickLinks[index];
                return _buildQuickLinkCard(
                  context,
                  icon: link['icon'] as IconData,
                  label: link['label'] as String,
                  iconColor: link['color'] as Color,
                  backgroundColor: link['backgroundColor'] as Color,
                  onTap: () => _handleQuickLinkTap(context, link['label'] as String),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuickLinkTap(BuildContext context, String label) {
    if (label == AppStrings.applyLeaveRequest) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ApplyLeavePage(),
        ),
      );
    } else if (label == AppStrings.workFromHomeRequest) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ApplyWfhPage(),
        ),
      );
    } else if (label == AppStrings.raiseRegularizeRequest) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ApplyRegularizePage(),
        ),
      );
    }
  }

  Widget _buildQuickLinkCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    // Calculate card dimensions based on screen size
    // Card width: 30% of screen width, clamped between 100 and 140
    final cardWidth = (screenWidth * 0.30).clamp(100.0, 140.0);
    // Card height: same as width for square cards
    final cardHeight = cardWidth;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor,
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(
            smallerDimension * 0.027, // ~2.7% of smaller dimension
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main icon in top-left
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: smallerDimension * 0.067, // ~6.7% of smaller dimension
                    color: iconColor,
                  ),
                  // Action icon in top-right
                  Container(
                    width: smallerDimension * 0.067, // ~6.7% of smaller dimension
                    height: smallerDimension * 0.067,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward,
                      size: smallerDimension * 0.039, // ~3.9% of smaller dimension
                      color: iconColor,
                    ),
                  )
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01), // 1% of screen height
              // Text centered vertically and horizontally
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

