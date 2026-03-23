import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/on_duty_repository.dart';

class AddOnDutyRequestCommentUseCase {
  final OnDutyRepository repository;

  AddOnDutyRequestCommentUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int requestId,
    required String comment,
    String type = 'OnDuty',
  }) {
    return repository.addRequestComment(
      requestId: requestId,
      comment: comment,
      type: type,
    );
  }
}
