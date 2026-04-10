import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class GetCachedUserProfileUseCase {
  final UserProfileRepository repository;

  GetCachedUserProfileUseCase(this.repository);

  Future<Either<Failure, UserProfile?>> call() {
    return repository.getCachedUserProfile();
  }
}
