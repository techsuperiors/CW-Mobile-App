import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';

/// Mobile wrapper widget
class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;

  const ResponsiveWrapper({
    super.key,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    return mobile;
  }
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isMobile) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return builder(context, isMobile);
  }
}

/// Responsive container with max width
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: ResponsiveUtils.maxContentWidth(context),
      ),
      padding: padding ?? ResponsiveUtils.responsivePadding(context),
      child: child,
    );
  }
}

