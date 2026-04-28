import 'package:dartz/dartz.dart';

import '../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../../../../../../../core/network/network_info.dart';
import '../../domain/models/employee_directory_model.dart';
import '../../domain/repositories/employee_directory_repository.dart';
import '../datasources/employee_directory_remote_datasource.dart';

class EmployeeDirectoryRepositoryImpl implements EmployeeDirectoryRepository {
  final EmployeeDirectoryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  EmployeeDirectoryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, EmployeeDirectoryPageModel>> getEmployees({
    required int clientId,
    required int page,
    required int limit,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.getEmployees(
        clientId: clientId,
        page: page,
        limit: limit,
      );
      return Right(response.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, EmployeeDirectoryDetailModel>> getEmployeeDetails({
    required int userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.getEmployeeDetails(
        userId: userId,
      );
      return Right(response.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }
}
