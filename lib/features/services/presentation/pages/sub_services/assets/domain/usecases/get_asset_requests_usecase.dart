import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import '../entities/asset_request_entity.dart';
import '../repository/asset_repository.dart';

/// Use case for fetching the list of asset requests for a specific user
class GetAssetRequestsUseCase {
  final AssetRepository repository;

  GetAssetRequestsUseCase(this.repository);

  Future<Either<Failure, List<AssetRequestEntity>>> call(int userId) {
    return repository.getAssetRequests(userId);
  }
}
