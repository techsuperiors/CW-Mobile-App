import 'package:flutter/material.dart';

/// Service model for services page
class ServiceModel {
  final String id;
  final String title;
  final String description;
  final String? iconPath; // SVG icon path (optional)
  final IconData? iconData; // Material icon (optional)
  final Color iconColor;
  final Color backgroundColor;
  final String? requiredPermission;
  final List<String>? anyOfPermissions;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    this.iconPath,
    this.iconData,
    required this.iconColor,
    required this.backgroundColor,
    this.requiredPermission,
    this.anyOfPermissions,
  });

  /// Create a copy with updated values
  ServiceModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    IconData? iconData,
    Color? iconColor,
    Color? backgroundColor,
    String? requiredPermission,
    List<String>? anyOfPermissions,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      iconData: iconData ?? this.iconData,
      iconColor: iconColor ?? this.iconColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      requiredPermission: requiredPermission ?? this.requiredPermission,
      anyOfPermissions: anyOfPermissions ?? this.anyOfPermissions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
