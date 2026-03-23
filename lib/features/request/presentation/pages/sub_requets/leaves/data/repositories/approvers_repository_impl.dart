import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../domain/repositories/approvers_repository.dart';
import '../datasources/approvers_remote_datasource.dart';

class ApproversRepositoryImpl implements ApproversRepository {
  final ApproversRemoteDataSource remoteDataSource;

  ApproversRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getApprovers(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final data = await remoteDataSource.getApprovers(endpoint, payload);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
