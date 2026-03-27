import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_stats_entity.dart';
import '../repository/leave_stats_repository.dart';

/// Use case to fetch user's leave statistics for the current month.
class GetLeaveStatsUseCase {
  final LeaveStatsRepository repository;

  GetLeaveStatsUseCase(this.repository);

  Future<Either<Failure, LeaveStatsEntity>> call({
    String? startDate,
    String? endDate,
  }) {
    return repository.getLeaveStats(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
