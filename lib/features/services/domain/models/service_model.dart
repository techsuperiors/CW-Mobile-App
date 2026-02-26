import 'package:flutter/material.dart';

/// Service model for services page
class ServiceModel {
  final String id;
  final String title;
  final String description;
  final String iconPath; // SVG icon path
  final Color iconColor;
  final Color backgroundColor;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.iconColor,
    required this.backgroundColor,
  });

  /// Create a copy with updated values
  ServiceModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      iconColor: iconColor ?? this.iconColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
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
