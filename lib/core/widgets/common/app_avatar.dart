import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Reusable avatar widget
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String? firstName;
  final String? lastName;
  final double radius;
  final Color? backgroundColor;
  final IconData? icon;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.firstName,
    this.lastName,
    this.radius = 20,
    this.backgroundColor,
    this.icon,
  });

  String _getInitials() {
    final trimmedFirstName = firstName?.trim() ?? '';
    final trimmedLastName = lastName?.trim() ?? '';

    if (trimmedFirstName.isNotEmpty && trimmedLastName.isNotEmpty) {
      return '${trimmedFirstName[0]}${trimmedLastName[0]}'.toUpperCase();
    }

    if (trimmedFirstName.isNotEmpty) {
      return trimmedFirstName[0].toUpperCase();
    }

    if (trimmedLastName.isNotEmpty) {
      return trimmedLastName[0].toUpperCase();
    }

    if (name == null || name!.trim().isEmpty) return '';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  @override
  Widget build(BuildContext context) {
    final initials = _getInitials();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.border,
      backgroundImage: null,
      child: imageUrl != null
          ? ClipOval(
            child: Image.network(
                    imageUrl!,
                    width: radius * 2,
                    height: radius * 2,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallback(initials), // load fail → fallback
                  ),
          )
          : _buildFallback(initials),
    );
  }

  Widget _buildFallback(String initials) {
    return initials.isNotEmpty
        ? Text(
      initials,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: radius * 0.6,
        fontWeight: FontWeight.bold,
      ),
    )
        : const Icon(Icons.person, color: AppColors.textSecondary);
  }
}
