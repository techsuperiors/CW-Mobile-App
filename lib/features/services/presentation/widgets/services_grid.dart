import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/service_model.dart';

/// Services grid widget - reusable component
class ServicesGrid extends StatelessWidget {
  final List<ServiceModel> services;
  final Function(ServiceModel)? onServiceTap;

  const ServicesGrid({
    super.key,
    required this.services,
    this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: screenWidth * 0.025, // 2.5% of screen width
        mainAxisSpacing: screenHeight * 0.012, // 1.2% of screen height
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _ServiceCard(
          service: services[index],
          onTap: onServiceTap != null
              ? () => onServiceTap!(services[index])
              : null,
        );
      },
    );
  }
}

/// Individual service card
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.service,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final smallerDimension = screenWidth < screenHeight ? screenWidth : screenHeight;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xffF1F9FE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(screenWidth * 0.037), // ~3.7% of screen width
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon at top-left
            SvgPicture.asset(
              service.iconPath,
              width: smallerDimension * 0.067, // ~6.7% of smaller dimension
              height: smallerDimension * 0.067,
              colorFilter: const ColorFilter.mode(
                AppColors.primaryLight,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: screenHeight * 0.015), // 1.5% of screen height
            // Bold title
            Text(
              service.title,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            SizedBox(height: screenHeight * 0.005), // 0.5% of screen height
            // Descriptive subtitle
            Expanded(
              child: Text(
                service.description,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
