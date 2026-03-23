import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/asset_entity.dart';
import '../entities/asset_request_entity.dart';
import '../entities/asset_category_entity.dart';

/// Repository contract defining asset data operations
abstract class AssetRepository {
  Future<Either<Failure, List<AssetEntity>>> getAssets();
  Future<Either<Failure, List<AssetRequestEntity>>> getAssetRequests(
    int userId,
  );
  Future<Either<Failure, List<AssetCategoryEntity>>> getAssetCategories(
    int userId,
  );
  Future<Either<Failure, void>> createAssetRequest({
    required int userId,
    required int assetCategoryId,
    required int assetSubCategoryId,
    required String reason,
    required String requestType,
  });
}
