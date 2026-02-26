import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_scaffold.dart';
import '../../features/home/presentation/widgets/bottom_nav_bar.dart';

/// Wrapper widget for dashboard pages with bottom navigation
/// This ensures bottom nav appears only on dashboard and navigated pages
class DashboardWrapper extends StatefulWidget {
  final Widget child;
  final int initialIndex;

  const DashboardWrapper({
    super.key,
    required this.child,
    this.initialIndex = 0,
  });

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Navigate to different pages based on index
    // This will be handled by HomePage
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onNavTap,
            ),
    );
  }
}

