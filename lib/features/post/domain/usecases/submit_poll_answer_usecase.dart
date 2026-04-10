import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class SubmitPollAnswerUseCase {
  final PostRepository repository;

  SubmitPollAnswerUseCase(this.repository);

  Future<Either<Failure, bool>> call(SubmitPollAnswerParams params) {
    return repository.submitPollAnswer(
      announcementId: params.announcementId,
      userId: params.userId,
      selectedOption: params.selectedOption,
    );
  }
}

class SubmitPollAnswerParams {
  final int announcementId;
  final int userId;
  final String selectedOption;

  SubmitPollAnswerParams({
    required this.announcementId,
    required this.userId,
    required this.selectedOption,
  });
}
