import '../../domain/entities/asset_entity.dart';

/// Asset Model extending AssetEntity with JSON serialization
/// Used in the Data layer for API response parsing
class AssetModel extends AssetEntity {
  const AssetModel({
    required super.id,
    required super.assetName,
    required super.assetId,
    required super.allocationStatus,
    required super.status,
    required super.assetType,
    required super.assetStatus,
    required super.condition,
    required super.categoryName,
    required super.subCategoryName,
    required super.totalUnits,
    required super.acknowledged,
    super.assignedBy,
  });

  /// Creates an AssetModel instance from API response JSON
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as int? ?? 0,
      assetName: json['asset_name'] as String? ?? '',
      assetId: json['assetID'] as String? ?? '',
      allocationStatus: json['allocation_status'] as String? ?? '',
      status: json['status'] as String? ?? '',
      assetType: json['asset_type'] as String? ?? '',
      assetStatus: json['asset_status'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      subCategoryName: json['subCategory_name'] as String? ?? '',
      totalUnits: json['total_units'] as int? ?? 0,
      acknowledged: json['acknowledged'] as bool? ?? false,
      assignedBy:
          json['allocation_assignedBy'] != null
              ? AssetAssigneeModel.fromJson(
                json['allocation_assignedBy'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

/// Assignee Model with fromJson
class AssetAssigneeModel extends AssetAssignee {
  const AssetAssigneeModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.profileColor,
    super.imageUrl,
  });

  factory AssetAssigneeModel.fromJson(Map<String, dynamic> json) {
    return AssetAssigneeModel(
      id: json['id'] as int? ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profileColor: json['profile_color'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }
}
