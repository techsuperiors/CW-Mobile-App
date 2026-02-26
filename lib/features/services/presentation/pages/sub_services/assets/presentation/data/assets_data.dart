import '../../../../../../../../core/constants/app_assets.dart';
import '../../domain/models/asset_model.dart';

/// Assets data provider - can be replaced with API call
class AssetsData {
  static List<AssetModel> getAssignedAssets() {
    return [
      const AssetModel(
        id: 1,
        name: 'MacBook Pro',
        assetId: 'Asset-018',
        employeeName: 'Riya Rawat',
        employeeAvatar: AppAssets.placeholderAvatar,
        department: 'HR Department',
        officeLocation: 'Dehradun',
        assetType: 'laptop',
      ),
      const AssetModel(
        id: 2,
        name: 'Samsung Headphone',
        assetId: 'Asset-010',
        employeeName: 'Aditya Sharma',
        employeeAvatar: AppAssets.placeholderAvatar,
        department: 'Marketing Department',
        officeLocation: 'Bangalore',
        assetType: 'headphone',
      ),
      const AssetModel(
        id: 3,
        name: 'Dell XPS 15',
        assetId: 'Asset-020',
        employeeName: 'Sneha Iyer',
        employeeAvatar: AppAssets.placeholderAvatar,
        department: 'Finance Department',
        officeLocation: 'Mumbai',
        assetType: 'laptop',
      ),
      const AssetModel(
        id: 4,
        name: 'HP Spectre x360',
        assetId: 'Asset-015',
        employeeName: 'Vikram Singh',
        employeeAvatar: AppAssets.placeholderAvatar,
        department: 'IT Department',
        officeLocation: 'Noida',
        assetType: 'laptop',
      ),
    ];
  }
}

