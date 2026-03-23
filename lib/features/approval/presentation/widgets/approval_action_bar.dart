import 'package:collectivWork/core/constants/app_colors.dart';
import 'package:collectivWork/core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_text_styles.dart';

class ApprovalActionBar extends StatelessWidget {
  final VoidCallback? onReject;
  final VoidCallback? onApprove;
  final bool isLoading;
  final bool embedded;

  const ApprovalActionBar({
    super.key,
    this.onReject,
    this.onApprove,
    this.isLoading = false,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenWidth * 0.12;

    final content = Container(
      color: embedded ? Colors.transparent : Colors.white,
      padding: EdgeInsets.fromLTRB(
        embedded ? 0 : screenWidth * 0.05,
        embedded ? 0 : 12,
        embedded ? 0 : screenWidth * 0.05,
        embedded ? 0 : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'Reject',
              color: AppColors.approvalSheetReject,
              iconAsset: AppAssets.wrongIcon,
              height: buttonHeight,
              isLoading: isLoading,
              onTap: isLoading ? null : onReject,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ActionButton(
              label: 'Approve',
              color: AppColors.approvalSheetAccept,
              iconAsset: AppAssets.correctIconapprova,
              height: buttonHeight,
              isLoading: isLoading,
              onTap: isLoading ? null : onApprove,
            ),
          ),
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    return SafeArea(top: false, child: content);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final String iconAsset;
  final double height;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.iconAsset,
    required this.height,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
          disabledBackgroundColor: color.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
        ),
        icon:
            isLoading
                ? SizedBox(
                  width: screenWidth * 0.05,
                  height: screenHeight * 0.05,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : SvgPicture.asset(
                  iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
        label: Text(
          label,
          style: AppTextStyles.bodyMedium(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
