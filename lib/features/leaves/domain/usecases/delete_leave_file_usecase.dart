import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/leave_types_repository.dart';

class DeleteLeaveFileUseCase {
  final LeaveTypesRepository repository;

  DeleteLeaveFileUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int leaveFileId,
    required String fileId,
  }) {
    return repository.deleteLeaveFile(
      leaveFileId: leaveFileId,
      fileId: fileId,
    );
  }
}
