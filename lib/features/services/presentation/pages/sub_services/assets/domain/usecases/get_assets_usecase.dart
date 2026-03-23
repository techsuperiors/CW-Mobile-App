import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/asset_entity.dart';
import '../repository/asset_repository.dart';

/// Use case for fetching the list of allocated assets
class GetAssetsUseCase {
  final AssetRepository repository;

  GetAssetsUseCase(this.repository);

  Future<Either<Failure, List<AssetEntity>>> call() {
    return repository.getAssets();
  }
}
