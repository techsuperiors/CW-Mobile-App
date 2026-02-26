import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/leave_type.dart';
import '../../domain/repositories/leave_types_repository.dart';
import '../datasources/leave_types_remote_datasource.dart';
import '../models/leave_type_model.dart';

/// Leave Types repository implementation
class LeaveTypesRepositoryImpl implements LeaveTypesRepository {
  final LeaveTypesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LeaveTypesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LeaveTypes>> getLeaveTypes() async {
    if (await networkInfo.isConnected) {
      try {
        final responseModel = await remoteDataSource.getLeaveTypes();
        
        // Convert models to entities
        final leaveTypes = responseModel.leaveConfig
            .where((config) => 
                config.leaveType != null && 
                config.status?.toLowerCase() == 'active')
            .map((config) => LeaveType(
              leaveType: config.leaveType!,
              count: config.displayCount,
              leaveCode: config.leaveCode ?? '',
              consumedLeaves: config.consumedLeaves,
              totalLeaves: config.totalLeaves,
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
}

