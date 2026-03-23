import 'package:dartz/dartz.dart';
import 'package:collectivWork/core/error/failures.dart';
import 'package:collectivWork/core/usecase/usecase.dart';
import '../entities/apply_leave_entity.dart';
import '../repositories/leaves_repository.dart';

/// Use case for submitting a new leave application
class ApplyLeaveUseCase
    implements UseCase<ApplyLeaveResponseEntity, ApplyLeaveRequestEntity> {
  final LeavesRepository repository;

  ApplyLeaveUseCase(this.repository);

  @override
  Future<Either<Failure, ApplyLeaveResponseEntity>> call(
    ApplyLeaveRequestEntity params,
  ) async {
    return await repository.applyLeave(params);
  }
}
