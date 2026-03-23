import 'package:dartz/dartz.dart';
import 'package:collectivWork/core/error/failures.dart';
import 'package:collectivWork/core/usecase/usecase.dart';
import '../entities/leave_entity.dart';
import '../repositories/leaves_repository.dart';

/// UseCase to get the list of leave requests
class GetLeavesUseCase extends UseCase<List<LeaveEntity>, NoParams> {
  final LeavesRepository repository;

  GetLeavesUseCase(this.repository);

  @override
  Future<Either<Failure, List<LeaveEntity>>> call(NoParams params) async {
    return await repository.getLeaves();
  }
}
