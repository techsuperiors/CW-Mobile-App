import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Reusable avatar widget
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final IconData? icon;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.border,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? (icon != null
              ? Icon(icon, color: AppColors.textSecondary, size: radius)
              : (name != null && name!.isNotEmpty
                  ? Text(
                      name![0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: radius * 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.person, color: AppColors.textSecondary)))
          : null,
    );
  }
}

