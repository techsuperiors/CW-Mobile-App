import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_stats_entity.dart';

/// Abstract contract for leave stats operations.
abstract class LeaveStatsRepository {
  Future<Either<Failure, LeaveStatsEntity>> getLeaveStats();
}
