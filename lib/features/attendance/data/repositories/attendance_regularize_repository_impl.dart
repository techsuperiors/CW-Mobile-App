import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
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
    required int requestTo,
    required String requestFor,
    required String modeType,
    required String checkIn,
    required String checkOut,
    required String reason,
    required String description,
    required int userId,
    required bool isOther,
    required int statusUpdatedBy,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = AttendanceRegularizeRequest(
          requestDate: requestDate,
          requestTo: requestTo,
          requestFor: requestFor,
          modeType: modeType,
          checkIn: checkIn,
          checkOut: checkOut,
          reason: reason,
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
}
