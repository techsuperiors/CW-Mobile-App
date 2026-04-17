import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/error_handler.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../domain/entities/overtime_detail.dart';
import '../../domain/repositories/overtime_repository.dart';
import '../../models/overtime_request_model.dart';
import '../../models/overtime_request_stats_model.dart';
import '../datasources/overtime_remote_datasource.dart';

class OvertimeRepositoryImpl implements OvertimeRepository {
  final OvertimeRemoteDataSource remoteDataSource;

  OvertimeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<OvertimeRequestModel>>> getOvertimeRequests({
    required int clientId,
    int page = 1,
    int limit = 5,
    OvertimeStatus? status,
  }) async {
    try {
      final requests = await remoteDataSource.getOvertimeRequests(
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
  Future<Either<Failure, List<OvertimeRequestModel>>> getTeamOvertimeRequests({
    required int clientId,
    int page = 1,
    int limit = 20,
    String requestType = 'All',
    OvertimeStatus? status,
  }) async {
    try {
      final requests = await remoteDataSource.getTeamOvertimeRequests(
        clientId: clientId,
        page: page,
        limit: limit,
        requestType: requestType,
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
  Future<Either<Failure, OvertimeRequestStatsModel>> getOvertimeRequestStats({
    required int clientId,
    String requestType = 'User',
  }) async {
    try {
      final stats = await remoteDataSource.getOvertimeRequestStats(
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
  Future<Either<Failure, OvertimeDetail>> getOvertimeRequestDetail(
    int requestId,
  ) async {
    try {
      final detail = await remoteDataSource.getOvertimeRequestDetail(requestId);
      return Right(detail);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createOvertimeRequest({
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required String subject,
    required String description,
    required int userId,
  }) async {
    try {
      final message = await remoteDataSource.createOvertimeRequest(
        requestDate: requestDate,
        checkIn: checkIn,
        checkOut: checkOut,
        subject: subject,
        description: description,
        userId: userId,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> updateOvertimeRequest({
    required int requestId,
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required int userId,
    required String description,
  }) async {
    try {
      final message = await remoteDataSource.updateOvertimeRequest(
        requestId: requestId,
        requestDate: requestDate,
        checkIn: checkIn,
        checkOut: checkOut,
        userId: userId,
        description: description,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> withdrawOvertimeRequest({
    required int requestId,
    required String status,
  }) async {
    try {
      final message = await remoteDataSource.withdrawOvertimeRequest(
        requestId: requestId,
        status: status,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceRequestComment>>> getRequestComments({
    required int clientId,
    required int requestId,
  }) async {
    try {
      final comments = await remoteDataSource.getRequestComments(
        clientId: clientId,
        requestId: requestId,
      );
      return Right(comments);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> addRequestComment({
    required int requestId,
    required String comment,
  }) async {
    try {
      final message = await remoteDataSource.addRequestComment(
        requestId: requestId,
        comment: comment,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }
}
