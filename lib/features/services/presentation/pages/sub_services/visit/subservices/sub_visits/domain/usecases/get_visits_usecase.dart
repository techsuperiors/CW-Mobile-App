import 'package:dartz/dartz.dart';

import '../../../../../../../../../../core/error/failures.dart';
import '../models/visit_model.dart';
import '../repositories/visit_repository.dart';

class GetVisitsUseCase {
  final VisitRepository repository;

  GetVisitsUseCase(this.repository);

  Future<Either<Failure, List<VisitModel>>> call({
    required int page,
    required int limit,
    VisitType? visitType,
    VisitStatus? visitStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? createdBy,
  }) {
    return repository.getVisits(
      page: page,
      limit: limit,
      visitType: visitType,
      visitStatus: visitStatus,
      fromDate: fromDate,
      toDate: toDate,
      createdBy: createdBy,
    );
  }
}

class GetVisitTotalCountUseCase {
  final VisitRepository repository;

  GetVisitTotalCountUseCase(this.repository);

  Future<Either<Failure, int>> call({
    required int page,
    required int limit,
    VisitType? visitType,
    VisitStatus? visitStatus,
    DateTime? fromDate,
    DateTime? toDate,
    int? createdBy,
  }) {
    return repository.getVisitTotalCount(
      page: page,
      limit: limit,
      visitType: visitType,
      visitStatus: visitStatus,
      fromDate: fromDate,
      toDate: toDate,
      createdBy: createdBy,
    );
  }
}

class GetVisitDetailsUseCase {
  final VisitRepository repository;

  GetVisitDetailsUseCase(this.repository);

  Future<Either<Failure, VisitDetailModel>> call(int visitId) {
    return repository.getVisitDetails(visitId);
  }
}
