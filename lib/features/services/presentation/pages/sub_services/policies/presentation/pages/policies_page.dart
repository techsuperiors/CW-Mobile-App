import 'package:flutter/material.dart';
import '../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/constants/app_text_styles.dart';
import '../../../../../../../../core/widgets/responsive_scaffold.dart';
import '../../../../../../../home/presentation/widgets/bottom_nav_bar.dart';
import '../data/policies_data.dart';
import '../widgets/policy_card.dart';

/// Policies page showing list of policies
class PoliciesPage extends StatelessWidget {
  final int? serviceId;

  const PoliciesPage({
    super.key,
    this.serviceId,
  });

  @override
  Widget build(BuildContext context) {
    final policies = PoliciesData.getPolicies();

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
          AppStrings.policies,
          style: AppTextStyles.heading4(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Services is active
        onTap: (index) {
          // Handle navigation if needed
          // For now, just keep Services active
        },
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.01,
        ),
        itemCount: policies.length,
        itemBuilder: (context, index) {
          final screenHeight = MediaQuery.of(context).size.height;
          final spacing = screenHeight < 600 ? 12.0 : (screenHeight < 700 ? 14.0 : 16.0);
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: PolicyCard(policy: policies[index]),
          );
        },
      ),
    );
  }
}

