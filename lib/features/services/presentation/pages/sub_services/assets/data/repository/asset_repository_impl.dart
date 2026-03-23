import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../domain/entities/asset_entity.dart';
import '../../domain/entities/asset_request_entity.dart';
import '../../domain/entities/asset_category_entity.dart';
import '../../domain/repository/asset_repository.dart';
import '../datasource/asset_remote_datasource.dart';

/// Concrete implementation of [AssetRepository]
/// Handles data fetching via remote data source with error handling
class AssetRepositoryImpl implements AssetRepository {
  final AssetRemoteDataSource remoteDataSource;

  AssetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AssetEntity>>> getAssets() async {
    try {
      // Fetch assets from remote data source
      final assets = await remoteDataSource.getAssets();
      // Return successful result
      return Right(assets);
    } catch (e) {
      // Return failure with error message
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AssetRequestEntity>>> getAssetRequests(
    int userId,
  ) async {
    try {
      final requests = await remoteDataSource.getAssetRequests(userId);
      return Right(requests);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AssetCategoryEntity>>> getAssetCategories(
    int userId,
  ) async {
    try {
      final categories = await remoteDataSource.getAssetCategories(userId);
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createAssetRequest({
    required int userId,
    required int assetCategoryId,
    required int assetSubCategoryId,
    required String reason,
    required String requestType,
  }) async {
    try {
      await remoteDataSource.createAssetRequest(
        userId: userId,
        assetCategoryId: assetCategoryId,
        assetSubCategoryId: assetSubCategoryId,
        reason: reason,
        requestType: requestType,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
