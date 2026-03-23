import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/overtime_repository.dart';

class AddOvertimeRequestCommentUseCase {
  final OvertimeRepository repository;

  AddOvertimeRequestCommentUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int requestId,
    required String comment,
  }) {
    return repository.addRequestComment(
      requestId: requestId,
      comment: comment,
    );
  }
}
