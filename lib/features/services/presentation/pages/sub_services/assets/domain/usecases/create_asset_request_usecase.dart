import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../repository/asset_repository.dart';

/// UseCase for creating a new asset request
class CreateAssetRequestUseCase {
  final AssetRepository repository;

  CreateAssetRequestUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required int userId,
    required int assetCategoryId,
    required int assetSubCategoryId,
    required String reason,
    required String requestType,
  }) {
    return repository.createAssetRequest(
      userId: userId,
      assetCategoryId: assetCategoryId,
      assetSubCategoryId: assetSubCategoryId,
      reason: reason,
      requestType: requestType,
    );
  }
}
