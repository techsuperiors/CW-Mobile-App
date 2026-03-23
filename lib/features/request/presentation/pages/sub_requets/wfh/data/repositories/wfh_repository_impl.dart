import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/error_handler.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../models/wfh_request_model.dart';
import '../../domain/repositories/wfh_repository.dart';
import '../datasources/wfh_remote_datasource.dart';

class WfhRepositoryImpl implements WfhRepository {
  final WfhRemoteDataSource remoteDataSource;

  WfhRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<WfhRequestModel>>> getWfhRequests() async {
    try {
      final requests = await remoteDataSource.getWfhRequests();
      return Right(requests);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<WfhRequestModel>>> getTeamWfhRequests({
    int page = 1,
    int limit = 50,
    String requestType = 'All',
  }) async {
    try {
      final requests = await remoteDataSource.getTeamWfhRequests(
        page: page,
        limit: limit,
        requestType: requestType,
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
