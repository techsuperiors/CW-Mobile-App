import 'package:dartz/dartz.dart';

import '../../../../../../../../../../core/constants/app_strings.dart';
import '../../../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../../../core/error/failures.dart';
import '../../../../../../../../../../core/network/network_info.dart';
import '../../domain/models/account_model.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AccountRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<AccountCustomerModel>>> getCustomers() async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.getCustomers();
      return Right(
        response.map((customer) => customer.toDomain()).toList(growable: false),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, List<AccountAddressModel>>> getAddresses() async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.getAddresses();
      return Right(
        response.map((address) => address.toDomain()).toList(growable: false),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, AccountCustomerDetailModel>> getCustomerDetails(
    int customerId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.getCustomerDetails(customerId);
      return Right(response.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, AccountAddressDetailModel>> getAddressDetails(
    int addressId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.getAddressDetails(addressId);
      return Right(response.toDomain());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, String>> createAddress(
    CreateVisitAddressParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.createAddress(params);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }

  @override
  Future<Either<Failure, String>> createCustomer(
    CreateAccountCustomerParams params,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(const NetworkFailure(AppStrings.noInternetConnection));
    }

    try {
      final response = await remoteDataSource.createCustomer(params);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return Left(ServerFailure(AppStrings.unexpectedError));
    }
  }
}
