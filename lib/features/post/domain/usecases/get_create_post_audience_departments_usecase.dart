import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/create_post_audience_entity.dart';
import '../repositories/post_repository.dart';

class GetCreatePostAudienceDepartmentsUseCase {
  final PostRepository repository;

  GetCreatePostAudienceDepartmentsUseCase(this.repository);

  Future<Either<Failure, List<CreatePostAudienceDepartmentEntity>>> call() {
    return repository.getCreatePostAudienceDepartments();
  }
}
