import 'package:dartz/dartz.dart';
import 'package:collectivWork/core/error/exceptions.dart';
import 'package:collectivWork/core/constants/app_strings.dart';
import 'package:collectivWork/core/error/failures.dart';
import 'package:collectivWork/core/network/network_info.dart';
import '../../domain/entities/leave_entity.dart';
import '../../domain/entities/apply_leave_entity.dart';
import '../../domain/entities/leave_history_entity.dart';
import '../../domain/repositories/leaves_repository.dart';
import '../datasources/leaves_remote_datasource.dart';
import '../models/apply_leave_model.dart';

class LeavesRepositoryImpl implements LeavesRepository {
  final LeavesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LeavesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<LeaveEntity>>> getLeaves() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLeaves = await remoteDataSource.getLeaves();
        return Right(
          remoteLeaves,
        ); // Left side will implicitly map up to List<LeaveEntity>
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('An unexpected error occurred.'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<LeaveEntity>>> getTeamLeaveRequests({
    required int clientId,
    int page = 1,
    int limit = 50,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteLeaves = await remoteDataSource.getTeamLeaveRequests(
          clientId: clientId,
          page: page,
          limit: limit,
        );
        return Right(remoteLeaves);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure('An unexpected error occurred.'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<LeaveHistoryEntity>>> getLeaveHistory(
    String leaveType,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteHistory = await remoteDataSource.getLeaveHistory(leaveType);
        return Right(remoteHistory);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('An unexpected error occurred.'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, ApplyLeaveResponseEntity>> applyLeave(
    ApplyLeaveRequestEntity request,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final requestModel = ApplyLeaveRequestModel.fromEntity(request);
        final result = await remoteDataSource.applyLeave(requestModel);
        return Right(result); // Return the actual ResponseModel entity mapping
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }
}
