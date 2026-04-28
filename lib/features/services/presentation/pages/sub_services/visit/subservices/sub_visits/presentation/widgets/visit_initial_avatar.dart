import 'package:flutter/material.dart';

import '../../../../../../../../../../core/constants/app_colors.dart';
import '../../../../../../../../../../core/constants/app_text_styles.dart';

class VisitInitialAvatar extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final String? profileColor;
  final double radius;

  const VisitInitialAvatar({
    required this.label,
    this.imageUrl,
    this.profileColor,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(label);
    final backgroundColor = _parseColor(profileColor) ?? AppColors.primaryLight;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage:
      imageUrl != null && imageUrl!.trim().isNotEmpty
          ? NetworkImage(imageUrl!.trim())
          : null,
      child:
      imageUrl != null && imageUrl!.trim().isNotEmpty
          ? null
          : Text(
        initials,
        style: AppTextStyles.bodySmall(context).copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Color? _parseColor(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.replaceFirst('#', '');
    final withAlpha = normalized.length == 6 ? 'FF$normalized' : normalized;
    final parsed = int.tryParse(withAlpha, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}
