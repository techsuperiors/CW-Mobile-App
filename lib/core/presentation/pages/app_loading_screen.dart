import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_assets.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_spacing.dart';

/// Loading screen shown while the signed-in user profile is being prepared.
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.splashbackgroundLight,
              AppColors.backgroundMediumLight,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    Container(
                      width: AppSpacing.sectionLarge * 2,
                      height: AppSpacing.sectionLarge * 2,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.textWhite,
                        borderRadius: BorderRadius.circular(AppSpacing.xl),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: AppSpacing.xl,
                            offset: const Offset(0, AppSpacing.sm),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AppAssets.splashIcon,
                        fit: BoxFit.contain,
                      ),
                    ),
                    AppSpacing.vXl,
                    Text(
                      'Signing you in',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: AppSpacing.sectionLarge,
                      height: AppSpacing.sectionLarge,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSpacing.xs,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.14,
                        ),
                      ),
                    ),
                    AppSpacing.vLg,
                    Text(
                      'This will only take a moment',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelLarge(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
