import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/attendance_details.dart';
import '../../domain/repositories/attendance_details_repository.dart';
import '../datasources/attendance_details_remote_datasource.dart';
import '../models/attendance_details_model.dart';

/// Attendance Details repository implementation
class AttendanceDetailsRepositoryImpl
    implements AttendanceDetailsRepository {
  final AttendanceDetailsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AttendanceDetailsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AttendanceDetails>> getAttendanceDetails() async {
    if (await networkInfo.isConnected) {
      try {
        final model = await remoteDataSource.getAttendanceDetails();
        final entity = _mapModelToEntity(model);
        return Right(entity);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  AttendanceDetails _mapModelToEntity(AttendanceDetailsModel model) {
    return AttendanceDetails(
      id: model.id,
      clientId: model.clientId,
      userId: model.userId,
      date: model.date,
      punchIn: model.punchIn,
      punchOut: model.punchOut,
      totalTime: model.totalTime,
      breakTime: model.breakTime,
      overTime: model.overTime,
      punchInIp: model.punchInIp,
      punchOutIp: model.punchOutIp,
      punchInLocation: model.punchInLocation,
      punchOutLocation: model.punchOutLocation,
      entries: model.entries,
      isLateEntries: model.isLateEntries,
      shiftType: model.shiftType,
      shiftId: model.shiftId,
      punchType: model.punchType,
      status: model.status,
      incompleteHours: model.incompleteHours,
      firstHalf: model.firstHalf,
      secondHalf: model.secondHalf,
      leaveType: model.leaveType,
      deductDays: model.deductDays,
      regularizeId: model.regularizeId,
      isProcessed: model.isProcessed,
      createdBy: model.createdBy,
      createdAt: model.createdAt,
      updatedBy: model.updatedBy,
      updatedAt: model.updatedAt,
      onDuty: model.onDuty,
      wfhShowPunch: model.wfhShowPunch,
      formattedPunchIn: model.formattedPunchIn,
      formattedPunchOut: model.formattedPunchOut,
      formattedBreakTime: model.formattedBreakTime,
      formattedOverTime: model.formattedOverTime,
    );
  }
}

