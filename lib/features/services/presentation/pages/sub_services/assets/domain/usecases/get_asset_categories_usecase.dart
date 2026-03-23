import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/asset_category_entity.dart';
import '../repository/asset_repository.dart';

/// UseCase for fetching the list of asset categories
class GetAssetCategoriesUseCase {
  final AssetRepository repository;

  GetAssetCategoriesUseCase(this.repository);

  Future<Either<Failure, List<AssetCategoryEntity>>> call(int userId) {
    return repository.getAssetCategories(userId);
  }
}
