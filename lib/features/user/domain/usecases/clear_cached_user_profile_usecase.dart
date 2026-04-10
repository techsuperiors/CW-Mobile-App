import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/user_profile_repository.dart';

class ClearCachedUserProfileUseCase {
  final UserProfileRepository repository;

  ClearCachedUserProfileUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.clearCachedUserProfile();
  }
}
