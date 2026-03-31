import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/error_handler.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../attendance/domain/entities/attendance_request_comment.dart';
import '../../domain/entities/comp_off_detail.dart';
import '../../domain/repositories/comp_off_repository.dart';
import '../../models/comp_off_request_model.dart';
import '../../models/comp_off_request_stats_model.dart';
import '../datasources/comp_off_remote_datasource.dart';

class CompOffRepositoryImpl implements CompOffRepository {
  final CompOffRemoteDataSource remoteDataSource;

  CompOffRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CompOffRequestModel>>> getCompOffRequests() async {
    try {
      final list = await remoteDataSource.getCompOffRequests();
      return Right(list);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<CompOffRequestModel>>> getTeamCompOffRequests({
    int page = 1,
    int limit = 20,
    String requestType = 'All',
  }) async {
    try {
      final pageData = await remoteDataSource.getTeamCompOffRequests(
        page: page,
        limit: limit,
        requestType: requestType,
      );
      return Right(pageData.requests);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, CompOffRequestStatsModel>> getCompOffRequestStats({
    required int userId,
  }) async {
    try {
      final stats = await remoteDataSource.getCompOffRequestStats(
        userId: userId,
      );
      return Right(stats);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, CompOffDetail>> getCompOffDetail(int compOffId) async {
    try {
      final detail = await remoteDataSource.getCompOffDetail(compOffId);
      return Right(detail);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> createCompOffRequest({
    required String type,
    required String date,
    required String duration,
    required String reason,
    required String subject,
    required int requestTo,
    required int userId,
  }) async {
    try {
      final message = await remoteDataSource.createCompOffRequest(
        type: type,
        date: date,
        duration: duration,
        reason: reason,
        subject: subject,
        requestTo: requestTo,
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
  Future<Either<Failure, String>> updateCompOffRequest({
    required int compOffId,
    required String subject,
    required String date,
    required String duration,
    required String reason,
  }) async {
    try {
      final message = await remoteDataSource.updateCompOffRequest(
        compOffId: compOffId,
        subject: subject,
        date: date,
        duration: duration,
        reason: reason,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadCompOffFile({
    required int compOffId,
    required String filePath,
  }) async {
    try {
      final message = await remoteDataSource.uploadCompOffFile(
        compOffId: compOffId,
        filePath: filePath,
      );
      return Right(message);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> updateCompOffRequestStatus({
    required int compOffId,
    required String status,
    String type = 'earn',
  }) async {
    try {
      final message = await remoteDataSource.updateCompOffRequestStatus(
        compOffId: compOffId,
        status: status,
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
  Future<Either<Failure, List<AttendanceRequestComment>>> getComments({
    required int compOffId,
  }) async {
    try {
      final comments = await remoteDataSource.getComments(compOffId: compOffId);
      return Right(comments);
    } on AppException catch (e) {
      return Left(ErrorHandler.handleException(e));
    } catch (e) {
      return Left(ErrorHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> addComment({
    required int compOffId,
    required String comment,
  }) async {
    try {
      final message = await remoteDataSource.addComment(
        compOffId: compOffId,
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
