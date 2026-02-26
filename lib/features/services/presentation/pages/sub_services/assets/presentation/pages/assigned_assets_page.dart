import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/utils/navigation_helper.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../data/assets_data.dart';
import '../widgets/asset_card.dart';

/// Assigned Assets page showing list of assigned assets
class AssignedAssetsPage extends StatelessWidget {
  final int? serviceId;

  const AssignedAssetsPage({
    super.key,
    this.serviceId,
  });

  @override
  Widget build(BuildContext context) {
    final assets = AssetsData.getAssignedAssets();

    return ResponsiveScaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.primary,
                size: MediaQuery.of(context).size.width * 0.048, // ~4.8% of screen width
              ),
              Flexible(
                child: Text(
                  AppStrings.services,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 110,
        title: Text(
          AppStrings.assignedAssets,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: NavigationHelper.getBottomNavHandler(context),
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.04,
          vertical: MediaQuery.of(context).size.height * 0.025,
        ),
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final screenHeight = MediaQuery.of(context).size.height;
          final spacing = screenHeight < 600 ? 12.0 : (screenHeight < 700 ? 14.0 : 16.0);
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: AssetCard(asset: assets[index]),
          );
        },
      ),
    );
  }
}

