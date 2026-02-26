import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/punch_in_result.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';

/// Attendance repository implementation
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PunchInResult>> punchIn({
    required String punchInLocation,
    required double latitude,
    required double longitude,
    required String punchType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = PunchInRequest(
          punchInLocation: punchInLocation,
          latitude: latitude,
          longitude: longitude,
          punchType: punchType,
        );
        
        final response = await remoteDataSource.punchIn(request);
        
        return Right(PunchInResult(
          success: response.success,
          message: response.message ?? 'Punch-in successful',
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

