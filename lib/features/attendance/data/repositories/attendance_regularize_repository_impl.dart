import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/attendance_request_comment.dart';
import '../../domain/entities/attendance_regularize_detail.dart';
import '../../domain/entities/attendance_regularize_result.dart';
import '../../domain/repositories/attendance_regularize_repository.dart';
import '../datasources/attendance_regularize_remote_datasource.dart';
import '../models/attendance_regularize_model.dart';

/// Attendance Regularize repository implementation
class AttendanceRegularizeRepositoryImpl
    implements AttendanceRegularizeRepository {
  final AttendanceRegularizeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AttendanceRegularizeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AttendanceRegularizeResult>> applyRegularize({
    required String requestDate,
    required String requestFor,
    required String modeType,
    required String checkIn,
    required String checkOut,
    required String reason,
    String? otherReason,
    required String description,
    required int userId,
    required bool isOther,
    required int statusUpdatedBy,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = AttendanceRegularizeRequest(
          requestDate: requestDate,
          requestFor: requestFor,
          modeType: modeType,
          checkIn: checkIn,
          checkOut: checkOut,
          reason: reason,
          otherReason: otherReason,
          description: description,
          userId: userId,
          isOther: isOther,
          statusUpdatedBy: statusUpdatedBy,
        );

        final response = await remoteDataSource.applyRegularize(request);

        return Right(AttendanceRegularizeResult(
          success: response.success,
          message: response.message,
          data: response.data,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, AttendanceRegularizeDetail>> getRegularizeRequestDetail(
    int requestId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final detail = await remoteDataSource.getRegularizeRequestDetail(
          requestId,
        );
        return Right(detail);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, AttendanceRegularizeResult>> updateRegularize({
    required int id,
    required String requestFor,
    required String requestDate,
    required String checkIn,
    required String checkOut,
    required int statusUpdatedBy,
    required String description,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = AttendanceRegularizeUpdateRequest(
          id: id,
          requestFor: requestFor,
          requestDate: requestDate,
          checkIn: checkIn,
          checkOut: checkOut,
          statusUpdatedBy: statusUpdatedBy,
          description: description,
        );

        final response = await remoteDataSource.updateRegularize(request);

        return Right(
          AttendanceRegularizeResult(
            success: response.success,
            message: response.message,
            data: response.data,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, String>> updateRegularizeRequestStatus({
    required int requestId,
    required String status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await remoteDataSource.updateRegularizeRequestStatus(
          requestId: requestId,
          status: status,
        );
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceRequestComment>>> getRequestComments({
    required int clientId,
    required int requestId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final comments = await remoteDataSource.getRequestComments(
          clientId: clientId,
          requestId: requestId,
        );
        return Right(comments);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  @override
  Future<Either<Failure, String>> addRequestComment({
    required int requestId,
    required String comment,
    String type = 'Attendance',
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await remoteDataSource.addRequestComment(
          requestId: requestId,
          comment: comment,
          type: type,
        );
        return Right(message);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }
}
