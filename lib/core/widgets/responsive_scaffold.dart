import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import 'platform_aware_scaffold.dart';

/// Responsive scaffold with adaptive layout
class ResponsiveScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const ResponsiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.appBar,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformAwareScaffold(
      title: title,
      appBar: appBar,
      actions: actions,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      body: Padding(
        padding: padding ?? ResponsiveUtils.responsivePadding(context),
        child: body,
      ),
    );
  }
}
