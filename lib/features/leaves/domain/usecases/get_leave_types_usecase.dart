import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/leave_type.dart';
import '../repositories/leave_types_repository.dart';

/// Use case for getting leave types
class GetLeaveTypesUseCase {
  final LeaveTypesRepository repository;

  GetLeaveTypesUseCase(this.repository);

  Future<Either<Failure, LeaveTypes>> call(int userId) {
    return repository.getLeaveTypes(userId);
  }
}

