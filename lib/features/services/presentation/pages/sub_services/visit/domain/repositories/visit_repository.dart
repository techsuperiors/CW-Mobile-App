import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../models/visit_model.dart';

abstract class VisitRepository {
  Future<Either<Failure, List<VisitModel>>> getVisits({
    required int page,
    required int limit,
    VisitType? visitType,
    VisitStatus? visitStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? createdBy,
  });

  Future<Either<Failure, int>> getVisitTotalCount({
    required int page,
    required int limit,
    VisitType? visitType,
    VisitStatus? visitStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? createdBy,
  });

  Future<Either<Failure, List<VisitEmployeeModel>>> getEmployees();

  Future<Either<Failure, List<VisitCustomerModel>>> getCustomers();

  Future<Either<Failure, List<VisitAddressModel>>> getAddresses();

  Future<Either<Failure, String>> createVisit(CreateVisitParams params);

  Future<Either<Failure, String>> createVisitActivity(
    CreateVisitActivityParams params,
  );
}
