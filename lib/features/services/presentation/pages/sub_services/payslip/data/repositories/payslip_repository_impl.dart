import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/exceptions.dart';
import '../../../../../../../../core/error/failures.dart';
import '../../domain/models/payslip_model.dart';
import '../../domain/repositories/payslip_repository.dart';
import '../datasources/payslip_remote_datasource.dart';

class PayslipRepositoryImpl implements PayslipRepository {
  final PayslipRemoteDataSource remoteDataSource;

  PayslipRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PayslipModel>>> getPayslips(String year) async {
    try {
      final payslips = await remoteDataSource.getPayslips(year);
      return Right(payslips);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
