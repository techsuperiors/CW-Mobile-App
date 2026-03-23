/// Represents a sub-category of an asset category
class AssetSubCategoryEntity {
  final int id;
  final String subCategoryName;
  final int totalAssetCount;

  const AssetSubCategoryEntity({
    required this.id,
    required this.subCategoryName,
    required this.totalAssetCount,
  });
}

/// Represents an asset category with its sub-categories
class AssetCategoryEntity {
  final int id;
  final String categoryName;
  final String categoryType;
  final bool requestable;
  final List<AssetSubCategoryEntity> subCategories;

  const AssetCategoryEntity({
    required this.id,
    required this.categoryName,
    required this.categoryType,
    required this.requestable,
    required this.subCategories,
  });
}
