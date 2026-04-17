import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/attendance_day_detail.dart';
import '../../domain/entities/attendance_details.dart';
import '../../domain/repositories/attendance_details_repository.dart';
import '../datasources/attendance_details_remote_datasource.dart';
import '../models/attendance_day_detail_model.dart';
import '../models/attendance_details_model.dart';

/// Attendance Details repository implementation
class AttendanceDetailsRepositoryImpl implements AttendanceDetailsRepository {
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

  @override
  Future<Either<Failure, AttendanceDayDetail>> getAttendanceDayDetail({
    required int userId,
    required String date,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        var model = await remoteDataSource.getAttendanceDayDetail(
          userId: userId,
          date: date,
        );
        try {
          final activityLogs = await remoteDataSource.getAttendanceActivity(
            userId: userId,
            date: date,
          );
          if (activityLogs.isNotEmpty) {
            model = model.copyWith(dayLogs: activityLogs);
          }
        } on ServerException {
          // Fall back to attendance user detail logs if the activity API fails.
        }
        return Right(_mapDayDetailModelToEntity(model));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (_) {
        return Left(ServerFailure(AppStrings.unexpectedError));
      }
    } else {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }
  }

  AttendanceDetails _mapModelToEntity(AttendanceDetailsModel model) {
    // Map OverTime
    OverTime? overTimeEntity;
    if (model.overTime != null) {
      overTimeEntity = OverTime(
        total: model.overTime!.total,
        beforePunchIn: model.overTime!.beforePunchIn,
        afterPunchOut: model.overTime!.afterPunchOut,
      );
    }

    // Map Shift
    Shift? shiftEntity;
    if (model.shift != null) {
      shiftEntity = Shift(
        id: model.shift!.id,
        shiftDayTiming:
            model.shift!.shiftDayTiming
                .map(
                  (timing) => ShiftDayTiming(
                    day: timing.day,
                    punchIn: timing.punchIn,
                    punchOut: timing.punchOut,
                    breakTime: timing.breakTime,
                    grossHours: timing.grossHours,
                    effectiveHours: timing.effectiveHours,
                  ),
                )
                .toList(),
        weeklyOffDays:
            model.shift!.weeklyOffDays
                .map(
                  (offDay) => WeeklyOffDay(
                    day: offDay.day,
                    offType: offDay.offType,
                    selectedDay: offDay.selectedDay,
                    weeklyOccurrence: offDay.weeklyOccurrence,
                  ),
                )
                .toList(),
      );
    }

    // Map Activities
    List<Activity>? activities;
    if (model.activity != null) {
      activities =
          model.activity!
              .map(
                (activity) => Activity(
                  action: activity.action,
                  activityType: activity.activityType,
                  activityBy: activity.activityBy,
                  createdAt: activity.createdAt,
                  time: activity.time,
                  penaltyMessage: activity.penaltyMessage,
                  paidDays: activity.paidDays,
                  unPaidDays: activity.unPaidDays,
                  ip: activity.ip,
                  location: activity.location,
                  mode: activity.mode,
                ),
              )
              .toList();
    }

    return AttendanceDetails(
      id: model.id,
      clientId: model.clientId,
      userId: model.userId,
      date: model.date,
      punchIn: model.punchIn,
      punchOut: model.punchOut,
      totalTime: model.totalTime,
      breakTime: model.breakTime,
      overTime: overTimeEntity,
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
      remark: model.remark,
      approvalStatus: model.approvalStatus,
      isProcessed: model.isProcessed,
      activity: activities,
      createdBy: model.createdBy,
      createdAt: model.createdAt,
      updatedBy: model.updatedBy,
      updatedAt: model.updatedAt,
      shift: shiftEntity,
      onDuty: model.onDuty,
      wfhShowPunch: model.wfhShowPunch,
      capturePunchLocation: model.capturePunchLocation,
      approvalRequired: model.approvalRequired,
      punchOutRemarkRequired: model.punchOutRemarkRequired,
      grossHours: model.grossHours,
      effectiveHours: model.effectiveHours,
      formattedPunchIn: model.formattedPunchIn,
      formattedPunchOut: model.formattedPunchOut,
      formattedBreakTime: model.formattedBreakTime,
      formattedOverTime: model.formattedOverTime,
    );
  }

  AttendanceDayDetail _mapDayDetailModelToEntity(
    AttendanceDayDetailModel model,
  ) {
    return model.toEntity();
  }
}
