import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/utils/app_spacing.dart';

class MenuRow extends StatelessWidget {
  final String? assetPath;
  final IconData? icon;
  final String label;
  final Color? color;

  const MenuRow({
    super.key,
    this.assetPath,
    this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (assetPath != null)
          SvgPicture.asset(
            assetPath!,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              color ?? const Color(0xFF5D6470),
              BlendMode.srcIn,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: color ?? const Color(0xFF5D6470))
        else
          const SizedBox(width: 18, height: 18),
        AppSpacing.hSm,
        Text(
          label,
          style: AppTextStyles.bodyMediumHeading(context).copyWith(
            fontWeight: FontWeight.w500,
            color: color ?? const Color(0xFF3A414D),
          ),
        ),
      ],
    );
  }
}
