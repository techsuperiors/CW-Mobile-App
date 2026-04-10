import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/post_repository.dart';

class GenerateAnnouncementContentUseCase {
  final PostRepository repository;

  GenerateAnnouncementContentUseCase(this.repository);

  Future<Either<Failure, String>> call({required String content}) {
    return repository.generateAnnouncementContent(content: content);
  }
}
