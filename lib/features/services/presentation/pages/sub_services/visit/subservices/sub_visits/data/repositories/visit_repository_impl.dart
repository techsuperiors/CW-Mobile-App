import 'package:dartz/dartz.dart';

import '../../../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../../../core/error/failures.dart';
import '../../../../../../../../../../core/network/network_info.dart';
import '../../domain/models/visit_model.dart';
import '../../domain/repositories/visit_repository.dart';
import '../datasources/visit_remote_datasource.dart';

class VisitRepositoryImpl implements VisitRepository {
  final VisitRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  VisitRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<VisitModel>>> getVisits({
    required int page,
    required int limit,
    VisitType? visitType,
    VisitStatus? visitStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? createdBy,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.getVisits(
        page: page,
        limit: limit,
        visitType: visitType,
        visitStatus: visitStatus,
        fromDate: fromDate,
        toDate: toDate,
        createdBy: createdBy,
      );

      return Right(
        response.visits
            .map((visit) => visit.toDomain())
            .toList(growable: false),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, int>> getVisitTotalCount({
    required int page,
    required int limit,
    VisitType? visitType,
    VisitStatus? visitStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? createdBy,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.getVisits(
        page: page,
        limit: limit,
        visitType: visitType,
        visitStatus: visitStatus,
        fromDate: fromDate,
        toDate: toDate,
        createdBy: createdBy,
      );
      return Right(response.totalCount);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, List<VisitEmployeeModel>>> getEmployees() async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final employees = await remoteDataSource.getEmployees();
      return Right(
        employees
            .map((employee) => employee.toDomain())
            .toList(growable: false),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, List<VisitCustomerModel>>> getCustomers() async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final customers = await remoteDataSource.getCustomers();
      return Right(
        customers
            .map((customer) => customer.toDomain())
            .toList(growable: false),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, List<VisitAddressModel>>> getAddresses() async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final addresses = await remoteDataSource.getAddresses();
      return Right(
        addresses.map((address) => address.toDomain()).toList(growable: false),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, String>> createVisit(CreateVisitParams params) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final message = await remoteDataSource.createVisit(params);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, VisitDetailModel>> getVisitDetails(int visitId) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final detail = await remoteDataSource.getVisitDetails(visitId);
      return Right(detail.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, VisitActivityDetailModel>> getVisitActivityDetails(
    int activityId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final detail = await remoteDataSource.getVisitActivityDetails(activityId);
      return Right(detail.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, String>> createVisitActivity(
    CreateVisitActivityParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final message = await remoteDataSource.createVisitActivity(params);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, String>> updateVisitActivity(
    UpdateVisitActivityParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final message = await remoteDataSource.updateVisitActivity(params);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, String>> startVisitActivity(
    StartVisitActivityParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final message = await remoteDataSource.startVisitActivity(params);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, String>> completeVisitActivity(
    CompleteVisitActivityParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final message = await remoteDataSource.completeVisitActivity(params);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, String>> deleteVisitActivity(int activityId) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final message = await remoteDataSource.deleteVisitActivity(activityId);
      return Right(message);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }
}
