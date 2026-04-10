import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/create_post_audience_entity.dart';
import '../repositories/post_repository.dart';

class GetCreatePostAudienceUsersUseCase {
  final PostRepository repository;

  GetCreatePostAudienceUsersUseCase(this.repository);

  Future<Either<Failure, List<CreatePostAudienceUserEntity>>> call() {
    return repository.getCreatePostAudienceUsers();
  }
}
