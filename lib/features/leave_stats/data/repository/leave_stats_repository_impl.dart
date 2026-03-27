import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/leave_stats_entity.dart';
import '../../domain/repository/leave_stats_repository.dart';
import '../datasources/leave_stats_remote_datasource.dart';

/// Concrete implementation of [LeaveStatsRepository].
class LeaveStatsRepositoryImpl implements LeaveStatsRepository {
  final LeaveStatsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LeaveStatsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LeaveStatsEntity>> getLeaveStats({
    String? startDate,
    String? endDate,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final stats = await remoteDataSource.getLeaveStats(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
