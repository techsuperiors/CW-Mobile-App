import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/leave_type.dart';
import '../../domain/entities/leave_apply_result.dart';
import '../../domain/repositories/leave_types_repository.dart';
import '../datasources/leave_types_remote_datasource.dart';
import '../models/leave_type_model.dart';
import '../models/leave_apply_model.dart';

/// Leave Types repository implementation
class LeaveTypesRepositoryImpl implements LeaveTypesRepository {
  final LeaveTypesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LeaveTypesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LeaveTypes>> getLeaveTypes(int userId) async {
    if (await networkInfo.isConnected) {
      try {
        final responseModel = await remoteDataSource.getLeaveTypes(userId);
        
        // Convert models to entities
        // Include all leave types, but filter out null leave types
        // LOP might not have a status field, so we include it if status is null or active
        final leaveTypes = responseModel.leaveConfig
            .where((config) => 
                config.leaveType != null && 
                (config.status == null || 
                 config.status?.toLowerCase() == 'active'))
            .map((config) => LeaveType(
              leaveType: config.leaveType!,
              count: config.displayCount,
              leaveCode: config.leaveCode ?? '',
              consumedLeaves: config.consumedLeaves,
              totalLeaves: config.totalLeaves,
              annualQuota: config.annualQuota,
              allocatedQuota: config.allocatedLeave ?? config.assignedQuota,
              remainingLeaves: config.remainingLeaves,
              currentMonthLop: config.currentMonthLop,
            ))
            .toList();
        
        return Right(LeaveTypes(
          leaveTypes: leaveTypes,
          lossOffPay: responseModel.lossOffPay,
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
  Future<Either<Failure, LeaveApplyResult>> applyLeave({
    required String leaveType,
    required String clubing,
    required bool isClubbing,
    required String startDate,
    required String endDate,
    required String subject,
    required String reason,
    required String startHalf,
    required String endHalf,
    required String dayType,
    required String description,
    required String shortCode,
    required int requestTo,
    required List<String> rHDates,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final request = LeaveApplyRequest(
          leaveType: leaveType,
          clubing: clubing,
          isClubbing: isClubbing,
          startDate: startDate,
          endDate: endDate,
          subject: subject,
          reason: reason,
          startHalf: startHalf,
          endHalf: endHalf,
          dayType: dayType,
          description: description,
          shortCode: shortCode,
          requestTo: requestTo,
          rHDates: rHDates,
        );
        
        final response = await remoteDataSource.applyLeave(request);
        
        return Right(LeaveApplyResult(
          success: response.success,
          message: response.message ?? 'Leave applied successfully',
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

