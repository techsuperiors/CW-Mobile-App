import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/error_handler.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../domain/entities/on_duty_detail.dart';
import '../../domain/repositories/on_duty_repository.dart';
import '../../models/on_duty_request_model.dart';
import '../../models/on_duty_request_stats_model.dart';
import '../datasources/on_duty_remote_datasource.dart';

class OnDutyRepositoryImpl implements OnDutyRepository {
  final OnDutyRemoteDataSource remoteDataSource;

  OnDutyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<OnDutyRequestModel>>> getOnDutyRequests({
    required int clientId,
    int page = 1,
    int limit = 5,
    OnDutyStatus? status,
  }) async {
    try {
      final requests = await remoteDataSource.getOnDutyRequests(
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
  Future<Either<Failure, List<OnDutyRequestModel>>> getTeamOnDutyRequests({
    required int clientId,
    int page = 1,
    int limit = 50,
    String requestType = 'All',
    OnDutyStatus? status,
  }) async {
    try {
      final requests = await remoteDataSource.getTeamOnDutyRequests(
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
  Future<Either<Failure, OnDutyRequestStatsModel>> getOnDutyRequestStats({
    required int clientId,
    String requestType = 'User',
  }) async {
    try {
      final stats = await remoteDataSource.getOnDutyRequestStats(
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
  Future<Either<Failure, OnDutyDetail>> getOnDutyRequestDetail(
    int requestId,
  ) async {
    try {
      final detail = await remoteDataSource.getOnDutyRequestDetail(requestId);
      return Right(detail);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> updateOnDutyRequestStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      final message = await remoteDataSource.updateOnDutyRequestStatus(
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
    String type = 'OnDuty',
  }) async {
    try {
      final comments = await remoteDataSource.getRequestComments(
        clientId: clientId,
        requestId: requestId,
        type: type,
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
    String type = 'OnDuty',
  }) async {
    try {
      final message = await remoteDataSource.addRequestComment(
        requestId: requestId,
        comment: comment,
        type: type,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> raiseOnDutyRequest({
    required String subject,
    required String requestType,
    required String description,
    required String startDate,
    required String endDate,
    required String startHalf,
    required String endHalf,
    required int userId,
    int? requestId,
  }) async {
    try {
      final message = await remoteDataSource.raiseOnDutyRequest(
        subject: subject,
        requestType: requestType,
        description: description,
        startDate: startDate,
        endDate: endDate,
        startHalf: startHalf,
        endHalf: endHalf,
        userId: userId,
        requestId: requestId,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }
}
