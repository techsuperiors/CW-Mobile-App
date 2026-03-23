import 'package:dartz/dartz.dart';
import '../../../../../../../../core/error/failures.dart';
import 'package:collectivWork/core/usecase/usecase.dart';
import '../entities/leave_history_entity.dart';
import '../repositories/leaves_repository.dart';

/// UseCase for fetching leave balance history
class GetLeaveHistoryUseCase
    implements UseCase<List<LeaveHistoryEntity>, String> {
  final LeavesRepository repository;

  GetLeaveHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<LeaveHistoryEntity>>> call(
    String leaveType,
  ) async {
    return await repository.getLeaveHistory(leaveType);
  }
}
