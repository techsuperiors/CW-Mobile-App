import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/responsive_utils.dart';
import '../constants/app_strings.dart';
import '../constants/app_assets.dart';

/// White label app logo widget
/// Displays app logo from SVG image
class AppLogo extends StatelessWidget {
  final double? height;
  final double? width;

  final bool showText;

  const AppLogo({super.key, this.height, this.width, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final logoSizeHeight =
        height ?? ResponsiveUtils.responsiveIconSize(context, mobile: 48);
    final logoSizeWidth =
        width ?? ResponsiveUtils.responsiveIconSize(context, mobile: 48);
    return Row(
      // mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App logo from SVG
        SizedBox(
          width: logoSizeWidth,
          height: logoSizeHeight,
          child: SvgPicture.asset(
            AppAssets.appNameLogo,
            width: logoSizeWidth,
            height: logoSizeHeight,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
