/// Asset model for assigned assets
class AssetModel {
  final int id;
  final String name;
  final String assetId;
  final String employeeName;
  final String employeeAvatar;
  final String department;
  final String officeLocation;
  final String assetType; // 'laptop', 'headphone', etc.

  const AssetModel({
    required this.id,
    required this.name,
    required this.assetId,
    required this.employeeName,
    required this.employeeAvatar,
    required this.department,
    required this.officeLocation,
    required this.assetType,
  });
}

