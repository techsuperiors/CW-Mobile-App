import 'package:dartz/dartz.dart';

import '../../../../../../../../core/error/failures.dart';
import '../repositories/comp_off_repository.dart';

class AddCompOffCommentUseCase {
  final CompOffRepository repository;

  AddCompOffCommentUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int compOffId,
    required String comment,
  }) {
    return repository.addComment(compOffId: compOffId, comment: comment);
  }
}
