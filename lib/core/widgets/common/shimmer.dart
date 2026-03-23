import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppShimmer extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;
  final Color? baseColor;
  final Color? highlightColor;

  // Rectangular Shimmer (Cards/Linee)
  const AppShimmer.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.baseColor,
    this.highlightColor,
  }) : shapeBorder = const RoundedRectangleBorder();

  // Circular Shimmer (Profile Avatars )
  const AppShimmer.circular({
    super.key,
    required this.width,
    required this.height,
    this.baseColor,
    this.highlightColor,
  }) : shapeBorder = const CircleBorder();

  // Custom Shape Shimmer
  const AppShimmer.custom({
    super.key,
    required this.width,
    required this.height,
    required this.shapeBorder,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // Default colors for App Theme match
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      period: const Duration(milliseconds: 1500), // Speed control
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[400]!, // Base color for the child
          shape: shapeBorder,
        ),
      ),
    );
  }
}