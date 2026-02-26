import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_type.dart';

/// Leave Types repository interface
abstract class LeaveTypesRepository {
  Future<Either<Failure, LeaveTypes>> getLeaveTypes();
}

