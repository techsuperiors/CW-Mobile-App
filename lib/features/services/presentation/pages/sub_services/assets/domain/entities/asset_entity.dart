/// Asset Entity representing an allocated asset
/// Used across all layers as the core data structure
class AssetEntity {
  final int id;
  final String assetName;
  final String assetId;
  final String allocationStatus;
  final String status;
  final String assetType;
  final String assetStatus;
  final String condition;
  final String categoryName;
  final String subCategoryName;
  final int totalUnits;
  final bool acknowledged;
  final AssetAssignee? assignedBy;

  const AssetEntity({
    required this.id,
    required this.assetName,
    required this.assetId,
    required this.allocationStatus,
    required this.status,
    required this.assetType,
    required this.assetStatus,
    required this.condition,
    required this.categoryName,
    required this.subCategoryName,
    required this.totalUnits,
    required this.acknowledged,
    this.assignedBy,
  });
}

/// Represents the user who assigned the asset
class AssetAssignee {
  final int id;
  final String firstName;
  final String lastName;
  final String? profileColor;
  final String? imageUrl;

  const AssetAssignee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileColor,
    this.imageUrl,
  });

  /// Full name helper
  String get fullName => '$firstName $lastName';
}
