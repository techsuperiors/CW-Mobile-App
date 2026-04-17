import 'package:dartz/dartz.dart';
import 'package:collectivWork/features/request/presentation/widgets/request_listing/request_audience_scope.dart';
import '../../../../../../../../core/error/error_handler.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../domain/repositories/wfh_repository.dart';
import '../../models/wfh_request_model.dart';
import '../../models/wfh_request_stats_model.dart';
import '../../models/wfh_requests_page_model.dart';
import '../datasources/wfh_remote_datasource.dart';

class WfhRepositoryImpl implements WfhRepository {
  final WfhRemoteDataSource remoteDataSource;

  WfhRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, WfhRequestsPageModel>> getWfhRequests({
    required int clientId,
    int page = 1,
    int limit = 5,
    WfhStatus? status,
  }) async {
    try {
      final requests = await remoteDataSource.getWfhRequests(
        clientId: clientId,
        page: page,
        limit: limit,
        status: status,
      );
      return Right(requests);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, WfhRequestStatsModel>> getWfhRequestStats({
    required int clientId,
    String requestType = 'User',
  }) async {
    try {
      final stats = await remoteDataSource.getWfhRequestStats(
        clientId: clientId,
        requestType: requestType,
      );
      return Right(stats);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<WfhRequestModel>>> getTeamWfhRequests({
    required int clientId,
    int page = 1,
    int limit = 50,
    RequestAudienceScope scope = RequestAudienceScope.allUsers,
    WfhStatus? status,
  }) async {
    try {
      final requests = await remoteDataSource.getTeamWfhRequests(
        clientId: clientId,
        page: page,
        limit: limit,
        scope: scope,
        status: status,
      );
      return Right(requests);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateWfhStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      await remoteDataSource.updateWfhStatus(
        requestId: requestId,
        status: status,
      );
      return const Right(null);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }
}
