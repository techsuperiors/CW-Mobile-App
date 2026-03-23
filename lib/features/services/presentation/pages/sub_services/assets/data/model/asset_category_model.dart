import '../../domain/entities/asset_category_entity.dart';

/// Model for an asset sub-category, parsed from API response
class AssetSubCategoryModel extends AssetSubCategoryEntity {
  const AssetSubCategoryModel({
    required super.id,
    required super.subCategoryName,
    required super.totalAssetCount,
  });

  factory AssetSubCategoryModel.fromJson(Map<String, dynamic> json) {
    return AssetSubCategoryModel(
      id: json['id'] as int? ?? 0,
      subCategoryName: json['subCategory_name'] as String? ?? '',
      totalAssetCount:
          int.tryParse(json['totalAssetCount']?.toString() ?? '0') ?? 0,
    );
  }
}

/// Model for an asset category with nested sub-categories
class AssetCategoryModel extends AssetCategoryEntity {
  const AssetCategoryModel({
    required super.id,
    required super.categoryName,
    required super.categoryType,
    required super.requestable,
    required super.subCategories,
  });

  factory AssetCategoryModel.fromJson(Map<String, dynamic> json) {
    final subCats =
        (json['AssetSubCategories'] as List<dynamic>? ?? [])
            .map(
              (s) => AssetSubCategoryModel.fromJson(s as Map<String, dynamic>),
            )
            .toList();

    return AssetCategoryModel(
      id: json['id'] as int? ?? 0,
      categoryName: json['category_name'] as String? ?? '',
      categoryType: json['category_type'] as String? ?? '',
      requestable: json['requestable'] as bool? ?? false,
      subCategories: subCats,
    );
  }
}
